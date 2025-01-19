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
import './functions/audio_function.dart';
import './functions/message_function.dart';
import 'package:cyanase/screens/home/group/group_deposit.dart';
import 'chat_input.dart'; // Import the InputArea

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

  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _loadGroupMembers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToLastMessage();
    });
  }

  void _scrollToLastMessage() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
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
      await _dbHelper.insertMessage({
        "group_id": widget.groupId,
        "sender_id": "current_user_id",
        "message": imagePath,
        "type": "image",
        "timestamp": DateTime.now().toIso8601String(),
        "media_id": mediaId,
        "status": "sent", // Ensure the status field is included
      });

      // Call the callback to refresh the chat list
      if (widget.onMessageSent != null) {
        widget.onMessageSent!();
      }

      _scrollToLastMessage();
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

    try {
      final String messageText = _controller.text.trim();

      // Insert the message into the database
      await _dbHelper.insertMessage({
        "group_id": widget.groupId,
        "sender_id": "current_user_id",
        "message": messageText,
        "type": "text",
        "timestamp": DateTime.now().toIso8601String(),
        "status": "sent",
      });

      // Clear the text field
      _controller.clear();

      // Call the callback to refresh the chat list
      if (widget.onMessageSent != null) {
        widget.onMessageSent!();
      }

      _scrollToLastMessage();
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
          "status": "sent", // Ensure the status field is included
        };

        await _dbHelper.insertMessage(message);

        // Call the callback to refresh the chat list
        if (widget.onMessageSent != null) {
          widget.onMessageSent!();
        }

        _scrollToLastMessage();
      } catch (e) {
        print("Error sending audio message: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to send audio message: ${e.toString()}")),
        );
      }
    }
  }

  void _cancelRecording() async {
    await _audioFunctions.stopRecording(); // Stop the recording
    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });
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
        onBackPressed: () {
          if (widget.onMessageSent != null) {
            widget.onMessageSent!(); // Call the callback when navigating back
          }
          Navigator.pop(context); // Navigate back
        },
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
          StreamBuilder<List<Map<String, dynamic>>>(
            stream:
                _messageFunctions.getMessagesStream(groupId: widget.groupId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data!;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToLastMessage();
              });
              return ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.only(top: 16, bottom: 80),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final bool isSameSender = index > 0 &&
                      messages[index - 1]["isMe"] == message["isMe"];
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
              );
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: InputArea(
              controller: _controller,
              isRecording: _isRecording,
              recordingDuration: _recordingDuration,
              onSendMessage: () {
                _sendMessage();
                _scrollToLastMessage();
              },
              onStartRecording: _startRecording,
              onStopRecording: _stopRecording,
              onSendImageMessage: _sendImageMessage,
              onCancelRecording: _cancelRecording,
              replyingToMessage: _replyingToMessage,
              onCancelReply: () {
                setState(() {
                  _replyingToMessage = null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
