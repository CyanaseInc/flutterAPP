import 'package:flutter/material.dart';
import 'package:cyanase/screens/home/group/group_info.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cyanase/screens/home/group/group_deposit.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'message_chat.dart';
import './functions/message_function.dart';
import './functions/audio_player.dart';
import 'functions/audio_function.dart';
import 'functions/ui_function.dart';

class MessageChatScreen extends StatefulWidget {
  final String name;
  final String profilePic;
  final bool isGroup;
  final int? groupId;

  const MessageChatScreen({
    Key? key,
    required this.name,
    required this.profilePic,
    this.isGroup = false,
    this.groupId,
  }) : super(key: key);

  @override
  _MessageChatScreenState createState() => _MessageChatScreenState();
}

class _MessageChatScreenState extends State<MessageChatScreen> {
  final MessageFunctions _messageFunctions = MessageFunctions();
  final AudioFunctions _audioFunctions = AudioFunctions();
  final AudioPlayerFunctions _audioPlayerFunctions = AudioPlayerFunctions();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _replyingToMessage;

  bool _isTyping = false;
  bool _isOnline = true;
  DateTime _lastSeen = DateTime.now().subtract(Duration(minutes: 5));

  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;

  Map<String, bool> _isPlayingMap = {};
  Map<String, Duration> _audioDurationMap = {};
  Map<String, Duration> _audioPositionMap = {};

  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final messages = await _messageFunctions.loadMessages(
        groupId: widget.isGroup ? widget.groupId : null);
    setState(() {
      _messages = messages;
    });
  }

  void _sendMessage() async {
    // Validate the message content
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Message cannot be empty")),
      );
      return;
    }

    // Ensure group_id is not null when isGroup is true
    if (widget.isGroup && widget.groupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Group ID is missing")),
      );
      return;
    }

    try {
      final message = {
        "group_id": widget.groupId,
        "sender_id": "current_user_id", // Replace with actual user ID
        "message": _controller.text.trim(),
        "type": "text",
        "timestamp": DateTime.now().toIso8601String(),
      };

      // Print the message and group_id for debugging

      setState(() {
        _messages.add({
          "id": UniqueKey().toString(),
          "isMe": true,
          "message": _controller.text.trim(),
          "time": DateTime.now().toIso8601String(),
          "replyTo": _replyingToMessage,
          "isAudio": false,
        });
        _controller.clear();
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
    } catch (e) {
      print("Error sending message: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send message: ${e.toString()}")),
      );
    }
  }

  void _startRecording() async {
    await _audioFunctions.startRecording();
    setState(() {
      _isRecording = true;
      _recordingDuration = Duration.zero;
    });
  }

  void _stopRecording() async {
    final path = await _audioFunctions.stopRecording();
    if (path != null) {
      await _messageFunctions.sendMessage(
        message: path,
        isGroup: widget.isGroup,
        groupId: widget.groupId,
        receiverId: widget.name,
      );

      setState(() {
        _messages.add({
          "id": UniqueKey().toString(),
          "isMe": true,
          "message": path,
          "time": DateTime.now().toIso8601String(),
          "replyTo": _replyingToMessage,
          "isAudio": true,
        });
      });
    }
  }

  void _playAudio(String messageId, String path) async {
    if (_isPlayingMap[messageId] ?? false) {
      await _audioPlayerFunctions.pauseAudio();
    } else {
      await _audioPlayerFunctions.playAudio(path);
    }
    setState(() {
      _isPlayingMap[messageId] = !(_isPlayingMap[messageId] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupInfoPage(
                  groupName: widget.name,
                  profilePic: widget.profilePic,
                ),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage(widget.profilePic),
                radius: 20,
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  if (_isTyping)
                    Text(
                      "Typing...",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    )
                  else if (_isOnline)
                    Text(
                      "Online",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    )
                  else
                    Text(
                      UIFunctions.formatLastSeen(_lastSeen),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DepositScreen(
                    groupName: widget.name,
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: primaryTwo),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Deposit',
              style: TextStyle(
                color: primaryTwo,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.black),
            onSelected: (String value) {
              switch (value) {
                case 'group_info':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupInfoPage(
                        groupName: widget.name,
                        profilePic: widget.profilePic,
                      ),
                    ),
                  );
                  break;
                case 'edit_group':
                  print('Edit Group Selected');
                  break;
                case 'leave_group':
                  print('Leave Group Selected');
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'group_info',
                child: Text('Group Info'),
              ),
              const PopupMenuItem<String>(
                value: 'edit_group',
                child: Text('Edit Group'),
              ),
              const PopupMenuItem<String>(
                value: 'leave_group',
                child: Text('Leave Group'),
              ),
            ],
          ),
        ],
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
                  onPlayAudio: (path) => _playAudio(message["id"], path),
                  isPlaying: _isPlayingMap[message["id"]] ?? false,
                  audioDuration:
                      _audioDurationMap[message["id"]] ?? Duration.zero,
                  audioPosition:
                      _audioPositionMap[message["id"]] ?? Duration.zero,
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
                            onChanged: (text) {
                              setState(() {
                                _isTyping = text.isNotEmpty;
                              });
                            },
                          ),
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
