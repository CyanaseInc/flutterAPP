// message_chat_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'chat_app_bar.dart'; // Import the AppBar
import 'message_chat.dart';
import './functions/ui_function.dart';
import './functions/audio_function.dart';
import './functions/message_function.dart';
import 'package:cyanase/screens/home/group/group_deposit.dart';
import './functions/image _functions.dart';

class MessageChatScreen extends StatefulWidget {
  final String name;
  final String profilePic;
  final bool isGroup;
  final int? groupId;
  final VoidCallback? onMessageSent;

  const MessageChatScreen({
    Key? key,
    required this.name,
    required this.profilePic,
    this.isGroup = true,
    this.groupId,
    this.onMessageSent,
  }) : super(key: key);

  @override
  _MessageChatScreenState createState() => _MessageChatScreenState();
}

class _MessageChatScreenState extends State<MessageChatScreen> {
  final MessageFunctions _messageFunctions = MessageFunctions();
  final AudioFunctions _audioFunctions = AudioFunctions();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _replyingToMessage;

  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<String> _memberNames = [];
  Map<String, bool> _isPlayingMap = {};
  Map<String, Duration> _audioDurationMap = {};
  Map<String, Duration> _audioPositionMap = {};

  List<Map<String, dynamic>> _messages = [];
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadGroupMembers();
  }

  Future<void> _loadMessages() async {
    final messages = await _messageFunctions.loadMessages(
        groupId: widget.isGroup ? widget.groupId : null);
    for (final message in messages) {
      if (message["type"] == "image") {
        message["isImage"] = true;
      } else {
        message["isImage"] = false;
      }
      if (message["isAudio"] == true) {
        final duration = await getAudioDuration(message["message"]);
        _audioDurationMap[message["id"]] = duration;
      }
    }
    setState(() {
      _messages = messages;
    });
  }

  Future<Duration> getAudioDuration(String path) async {
    final audioPlayer = AudioPlayer();
    try {
      await audioPlayer.setSource(DeviceFileSource(path));
      final duration = await audioPlayer.getDuration();
      return duration ?? Duration.zero;
    } catch (e) {
      print("Error getting audio duration: $e");
      return Duration.zero;
    }
  }

  void _sendImageMessage(String imagePath) async {
    try {
      final mediaId = await _dbHelper.insertImageFile(imagePath);
      final message = {
        "group_id": widget.groupId,
        "sender_id": "current_user_id",
        "message": imagePath,
        "type": "image",
        "status": "sent",
        "timestamp": DateTime.now().toIso8601String(),
        "media_id": mediaId,
      };
      final messageId = await _dbHelper.insertMessage(message);
      print("Image message inserted with ID: $messageId");

      final newMessage = {
        "id": UniqueKey().toString(),
        "isMe": true,
        "message": imagePath,
        "time": DateTime.now().toIso8601String(),
        "replyTo": _replyingToMessage,
        "isImage": true,
        "isAudio": false,
      };

      print("Added message to _messages: $newMessage");

      setState(() {
        _messages.add(newMessage);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      if (widget.onMessageSent != null) {
        widget.onMessageSent!();
      }
    } catch (e) {
      print("Error sending image message: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Failed to send image message: ${e.toString()}")),
      );
    }
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Message cannot be empty")),
      );
      return;
    }

    if (widget.isGroup && widget.groupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Group ID is missing")),
      );
      return;
    }

    try {
      await _dbHelper.insertMessage({
        "group_id": widget.groupId,
        "sender_id": "current_user_id",
        "message": _controller.text.trim(),
        "type": "text",
        "timestamp": DateTime.now().toIso8601String(),
      });

      _controller.clear();

      setState(() {
        _messages.add({
          "id": UniqueKey().toString(),
          "isMe": true,
          "message": _controller.text.trim(),
          "time": DateTime.now().toIso8601String(),
          "replyTo": _replyingToMessage,
          "isAudio": false,
          "isImage": false,
        });
        _replyingToMessage = null;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      if (widget.onMessageSent != null) {
        widget.onMessageSent!();
      }
    } catch (e) {
      print("Error sending text message: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send text message: ${e.toString()}")),
      );
    }
  }

  void _startRecording() async {
    await _audioFunctions.startRecording();
    setState(() {
      _isRecording = true;
      _recordingDuration = Duration.zero;
    });

    _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration += Duration(seconds: 1);
      });
    });
  }

  void _stopRecording() async {
    final path = await _audioFunctions.stopRecording();
    if (path != null) {
      if (widget.isGroup && widget.groupId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Group ID is missing")),
        );
        return;
      }

      try {
        final mediaId = await _dbHelper.insertAudioFile(path);
        final message = {
          "group_id": widget.groupId,
          "sender_id": "current_user_id",
          "message": path,
          "type": "audio",
          "timestamp": DateTime.now().toIso8601String(),
          "media_id": mediaId,
        };

        await _dbHelper.insertMessage(message);

        setState(() {
          _messages.add({
            "id": UniqueKey().toString(),
            "isMe": true,
            "message": path,
            "time": DateTime.now().toIso8601String(),
            "replyTo": _replyingToMessage,
            "isAudio": true,
          });
          _isRecording = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        if (widget.onMessageSent != null) {
          widget.onMessageSent!();
        }
      } catch (e) {
        print("Error sending audio message: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to send audio message: ${e.toString()}")),
        );
      }
    }
  }

  void _playAudio(String messageId, String path) async {
    print("Attempting to play audio from: $path");

    if (_isPlayingMap[messageId] ?? false) {
      await _audioFunctions.pauseAudio();
      setState(() {
        _isPlayingMap[messageId] = false;
      });
    } else {
      for (var id in _isPlayingMap.keys) {
        if (_isPlayingMap[id] == true && id != messageId) {
          await _audioFunctions.pauseAudio();
          setState(() {
            _isPlayingMap[id] = false;
            _audioPositionMap[id] = Duration.zero;
          });
        }
      }

      await _audioFunctions.playAudio(path);

      _audioFunctions.onPositionChanged((position) {
        setState(() {
          _audioPositionMap[messageId] = position;
        });
      });

      _audioFunctions.onDurationChanged((duration) {
        setState(() {
          _audioDurationMap[messageId] = duration;
        });
      });

      _audioFunctions.onPlayerComplete(() {
        setState(() {
          _isPlayingMap[messageId] = false;
          _audioPositionMap[messageId] = Duration.zero;
        });
      });

      setState(() {
        _isPlayingMap[messageId] = true;
      });
    }
  }

  Future<void> _loadGroupMembers() async {
    print(
        "isGroup: ${widget.isGroup}, groupId: ${widget.groupId}"); // Debug log
    if (widget.isGroup && widget.groupId != null) {
      try {
        print("Fetching members for group ID: ${widget.groupId}"); // Debug log
        final memberNames =
            await _dbHelper.getGroupMemberNames(widget.groupId!);
        print("Fetched member names: $memberNames"); // Debug log
        setState(() {
          _memberNames = memberNames;
        });
      } catch (e) {
        print("Error loading group members: $e"); // Debug log
      }
    } else if (!widget.isGroup) {
      // Handle one-on-one chat
      print("This is a one-on-one chat"); // Debug log
      setState(() {
        _memberNames = [widget.name]; // Show the other user's name
      });
    } else {
      print("Group ID is null or not a group chat"); // Debug log
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MessageAppBar(
        name: widget.name,
        profilePic: widget.profilePic,
        memberNames: _memberNames,
        onDepositPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DepositScreen(
                groupName: widget.name,
              ),
            ),
          );
        },
        onBackPressed: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/back.svg',
              fit: BoxFit.cover,
              color: Colors.grey[200],
            ),
          ),
          ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.only(top: 16, bottom: 80),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final bool isSameSender =
                  index > 0 && _messages[index - 1]["isMe"] == message["isMe"];
              return GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity! < 0) {
                    setState(() {
                      _replyingToMessage = message["message"];
                    });
                  }
                },
                child: MessageChat(
                  isMe: message["isMe"],
                  message: message["message"],
                  time: message["time"],
                  isSameSender: isSameSender,
                  replyTo: message["replyTo"],
                  isAudio: message["isAudio"],
                  isImage: message["isImage"] ?? false,
                  onPlayAudio: (path) => _playAudio(message["id"], path),
                  isPlaying: _isPlayingMap[message["id"]] ?? false,
                  audioDuration:
                      _audioDurationMap[message["id"]] ?? Duration.zero,
                  audioPosition:
                      _audioPositionMap[message["id"]] ?? Duration.zero,
                  messageId: message["id"],
                ),
              );
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.all(8),
              child: Column(
                children: [
                  if (_replyingToMessage != null)
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.reply, color: primaryColor),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              UIFunctions.truncateText(_replyingToMessage!),
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: primaryColor),
                            onPressed: () {
                              setState(() {
                                _replyingToMessage = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      if (_isRecording)
                        Expanded(
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _stopRecording();
                                  setState(() {
                                    _isRecording = false;
                                  });
                                },
                              ),
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.mic, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text(
                                        "Slide to cancel",
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Spacer(),
                                      Text(
                                        "${_recordingDuration.inSeconds}s",
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: "Type a message...",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ),
                      IconButton(
                        icon: Icon(Icons.image, color: primaryColor),
                        onPressed: () async {
                          final imageFile =
                              await ImageFunctions().pickImageFromGallery();
                          if (imageFile != null) {
                            final imagePath = await ImageFunctions()
                                .saveImageToStorage(imageFile);
                            _sendImageMessage(imagePath);
                          }
                        },
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          _isRecording
                              ? Icons.stop
                              : _controller.text.isEmpty
                                  ? Icons.mic
                                  : Icons.send,
                          color: _isRecording ? Colors.red : primaryColor,
                        ),
                        onPressed: () {
                          if (_isRecording) {
                            _stopRecording();
                          } else if (_controller.text.isEmpty) {
                            _startRecording();
                          } else {
                            _sendMessage();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
