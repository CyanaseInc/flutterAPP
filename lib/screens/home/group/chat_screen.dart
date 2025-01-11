import 'package:cyanase/screens/home/group/group_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart'; // For playing audio
import 'package:record/record.dart'; // For recording audio
import 'package:path_provider/path_provider.dart'; // For directory handling
import 'dart:io'; // For file and directory operations
import 'message_chat.dart';
import 'package:cyanase/theme/theme.dart'; // Import the app theme
import 'group_deposit.dart';

class MessageChatScreen extends StatefulWidget {
  final String name;
  final String profilePic;

  const MessageChatScreen({
    Key? key,
    required this.name,
    required this.profilePic,
  }) : super(key: key);

  @override
  _MessageChatScreenState createState() => _MessageChatScreenState();
}

class _MessageChatScreenState extends State<MessageChatScreen> {
  final List<Map<String, dynamic>> messages = [
    {
      "id": UniqueKey().toString(),
      "isMe": false,
      "message": "Hello!",
      "time": "10:00 AM",
      "replyTo": null,
      "isAudio": false
    },
    {
      "id": UniqueKey().toString(),
      "isMe": true,
      "message": "Hi there!",
      "time": "10:01 AM",
      "replyTo": null,
      "isAudio": false
    },
    {
      "id": UniqueKey().toString(),
      "isMe": false,
      "message": "How are you? I hope you're doing well and enjoying your day!",
      "time": "10:02 AM",
      "replyTo": null,
      "isAudio": false
    },
    {
      "id": UniqueKey().toString(),
      "isMe": true,
      "message": "I'm good, thanks! How about you?",
      "time": "10:03 AM",
      "replyTo": "How are you? I hope you're doing well and enjoying your day!",
      "isAudio": false
    },
  ];

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _replyingToMessage;

  bool _isTyping = false;
  bool _isOnline = true;
  DateTime _lastSeen = DateTime.now().subtract(Duration(minutes: 5));

  final Record _audioRecorder = Record(); // No need to call init()
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;

  final AudioPlayer _audioPlayer = AudioPlayer();

  Map<String, bool> _isPlayingMap = {};
  Map<String, Duration> _audioDurationMap = {};
  Map<String, Duration> _audioPositionMap = {};

  @override
  void initState() {
    super.initState();
    // No need to call _audioRecorder.init();
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        messages.add({
          "id": UniqueKey().toString(),
          "isMe": true,
          "message": _controller.text,
          "time":
              "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
          "replyTo": _replyingToMessage,
          "isAudio": false,
        });
        _controller.clear();
        _replyingToMessage = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _deleteMessage(int index) {
    setState(() {
      messages.removeAt(index);
    });
  }

  void _startReply(Map<String, dynamic> message) {
    setState(() {
      _replyingToMessage = message["message"];
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToMessage = null;
    });
  }

  void _toggleTyping() {
    setState(() {
      _isTyping = !_isTyping;
    });
  }

  void _toggleOnlineStatus() {
    setState(() {
      _isOnline = !_isOnline;
      if (!_isOnline) {
        _lastSeen = DateTime.now();
      }
    });
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return "Last seen just now";
    } else if (difference.inMinutes < 60) {
      return "Last seen ${difference.inMinutes} minutes ago";
    } else if (difference.inHours < 24) {
      return "Last seen ${difference.inHours} hours ago";
    } else {
      return "Last seen ${difference.inDays} days ago";
    }
  }

  void _startRecording() async {
    if (!await _audioRecorder.hasPermission()) {
      print("Microphone permission denied");
      return;
    }

    setState(() {
      _isRecording = true;
      _recordingDuration = Duration.zero;
    });

    final directory = await getApplicationDocumentsDirectory();
    final folderPath = '${directory.path}/recordings';
    final folder = Directory(folderPath);
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final filePath =
        '$folderPath/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _audioRecorder.start(
      path: filePath,
      encoder: AudioEncoder.aacLc,
    );

    _startRecordingTimer();
  }

  void _stopRecording() async {
    setState(() {
      _isRecording = false;
    });

    final path = await _audioRecorder.stop();

    if (path != null) {
      setState(() {
        messages.add({
          "id": UniqueKey().toString(),
          "isMe": true,
          "message": path,
          "time":
              "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
          "replyTo": _replyingToMessage,
          "isAudio": true,
        });
      });
    }
  }

  void _startRecordingTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (_isRecording) {
        setState(() {
          _recordingDuration += Duration(seconds: 1);
        });
        _startRecordingTimer();
      }
    });
  }

  void _playAudio(String messageId, String path) async {
    final isPlaying = _isPlayingMap[messageId] ?? false;
    if (isPlaying) {
      await _audioPlayer.pause();
      setState(() {
        _isPlayingMap[messageId] = false;
      });
    } else {
      _isPlayingMap.forEach((key, value) {
        if (value == true && key != messageId) {
          _audioPlayer.pause();
          setState(() {
            _isPlayingMap[key] = false;
          });
        }
      });

      await _audioPlayer.play(DeviceFileSource(path));
      setState(() {
        _isPlayingMap[messageId] = true;
      });

      _audioPlayer.onDurationChanged.listen((duration) {
        setState(() {
          _audioDurationMap[messageId] = duration;
        });
      });

      _audioPlayer.onPositionChanged.listen((position) {
        setState(() {
          _audioPositionMap[messageId] = position;
        });
      });

      _audioPlayer.onPlayerComplete.listen((event) {
        setState(() {
          _isPlayingMap[messageId] = false;
          _audioPositionMap[messageId] = Duration.zero;
        });
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: GestureDetector(
          onTap: () {
            // Navigate to GroupInfo page
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
                      _formatLastSeen(_lastSeen),
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
              side: BorderSide(color: primaryTwo), // Border color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Rounded corners
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12), // Padding
            ),
            child: const Text(
              'Deposit', // Button label
              style: TextStyle(
                color: primaryTwo, // Text color matches the border
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                color: Colors.black), // Vertical bars icon
            onSelected: (String value) {
              // Handle the selected action
              switch (value) {
                case 'group_info':
                  // Navigate to group info screen or show a dialog
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
                  // Navigate to edit group screen
                  print('Edit Group Selected');
                  break;
                case 'leave_group':
                  // Handle leave group action
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
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final bool isSameSender =
                  index > 0 && messages[index - 1]["isMe"] == message["isMe"];
              return GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity! < 0) {
                    _startReply(message);
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
                              _truncateText(_replyingToMessage!),
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: primaryColor),
                            onPressed: _cancelReply,
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
                              if (text.isNotEmpty) {
                                if (!_isTyping) _toggleTyping();
                              } else {
                                if (_isTyping) _toggleTyping();
                              }
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

  String _truncateText(String text, {int maxLength = 30}) {
    if (text.length > maxLength) {
      return text.substring(0, maxLength) + '...';
    }
    return text;
  }
}
