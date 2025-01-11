import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart'; // For playing audio
import 'package:record/record.dart'; // For recording audio

class Testa extends StatefulWidget {
  @override
  _TestaState createState() => _TestaState();
}

class _TestaState extends State<Testa> {
  final List<Map<String, dynamic>> messages = [
    {
      "isMe": false,
      "message": "Hello!",
      "time": "10:00 AM",
      "replyTo": null,
      "isAudio": false
    },
    {
      "isMe": true,
      "message": "Hi there!",
      "time": "10:01 AM",
      "replyTo": null,
      "isAudio": false
    },
    {
      "isMe": false,
      "message": "How are you? I hope you're doing well and enjoying your day!",
      "time": "10:02 AM",
      "replyTo": null,
      "isAudio": false
    },
    {
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

  // Typing, online, and last seen status
  bool _isTyping = false;
  bool _isOnline = true;
  DateTime _lastSeen = DateTime.now().subtract(Duration(minutes: 5));

  // Voice recording
  final Record _audioRecorder = Record();
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;

  // Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        messages.add({
          "isMe": true,
          "message": _controller.text,
          "time":
              "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
          "replyTo": _replyingToMessage,
          "isAudio": false,
        });
        _controller.clear();
        _replyingToMessage = null; // Clear the reply after sending
      });
      // Scroll to the bottom when a new message is sent
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
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
    setState(() {
      _isRecording = true;
      _recordingDuration = Duration.zero;
    });

    if (await _audioRecorder.hasPermission()) {
      await _audioRecorder.start(
        path: 'path/to/save/recording.m4a', // Save recording to this path
      );

      // Start a timer to track recording duration
      _startRecordingTimer();
    } else {
      setState(() {
        _isRecording = false;
      });
      // Handle permission denial
      print("Microphone permission denied");
    }
  }

  void _stopRecording() async {
    setState(() {
      _isRecording = false;
    });

    final path = await _audioRecorder.stop();

    if (path != null) {
      // Send the recorded audio as a message
      setState(() {
        messages.add({
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

  void _playAudio(String path) async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {
      await _audioPlayer.play(UrlSource(path));
      setState(() {
        _isPlaying = true;
      });

      // Listen for audio duration and position
      _audioPlayer.onDurationChanged.listen((duration) {
        setState(() {
          _audioDuration = duration;
        });
      });

      _audioPlayer.onPositionChanged.listen((position) {
        setState(() {
          _audioPosition = position;
        });
      });

      _audioPlayer.onPlayerComplete.listen((event) {
        setState(() {
          _isPlaying = false;
          _audioPosition = Duration.zero;
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
  void dispose() {
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back, color: Colors.black), // Black back button
          onPressed: () {
            Navigator.pop(context); // Handle back button press
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(
                  'assets/images/profile.jpg'), // Replace with your image
              radius: 20,
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Viannie Lyca",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // Black text for user name
                  ),
                ),
                SizedBox(height: 4),
                if (_isTyping)
                  Text(
                    "Typing...",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54, // Black text for status
                    ),
                  )
                else if (_isOnline)
                  Text(
                    "Online",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54, // Black text for status
                    ),
                  )
                else
                  Text(
                    _formatLastSeen(_lastSeen),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54, // Black text for status
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.call, color: Colors.black), // Black call button
            onPressed: () {
              // Handle call button press
            },
          ),
          IconButton(
            icon: Icon(Icons.videocam,
                color: Colors.black), // Black video call button
            onPressed: () {
              // Handle video call button press
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert,
                color: Colors.black), // Black more options button
            onPressed: () {
              // Handle more options button press
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background wallpaper (static)
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/back.svg', // Replace with your SVG file
              fit: BoxFit.cover,
              color: Colors.grey[200], // Adjust color as needed
            ),
          ),
          // Scrollable chat messages
          ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.only(
                top: 16, bottom: 80), // Space for the input field
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final bool isSameSender =
                  index > 0 && messages[index - 1]["isMe"] == message["isMe"];
              return MessageChat(
                isMe: message["isMe"],
                message: message["message"],
                time: message["time"],
                isSameSender: isSameSender,
                replyTo: message["replyTo"],
                isAudio: message["isAudio"],
                onPlayAudio: _playAudio,
                isPlaying: _isPlaying,
                audioPosition: _audioPosition,
                audioDuration: _audioDuration,
              );
            },
          ),
          // Input field at the bottom
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
                          Icon(Icons.reply, color: Colors.teal),
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
                            icon: Icon(Icons.close, color: Colors.teal),
                            onPressed: _cancelReply,
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      if (_isRecording)
                        Expanded(
                          child: GestureDetector(
                            onHorizontalDragEnd: (details) {
                              if (details.primaryVelocity! < 0) {
                                // Swiped left to cancel
                                _stopRecording();
                              }
                            },
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
                          color: _isRecording ? Colors.red : Colors.teal,
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

  // Helper function to truncate long text
  String _truncateText(String text, {int maxLength = 30}) {
    if (text.length > maxLength) {
      return text.substring(0, maxLength) + '...';
    }
    return text;
  }
}

class MessageChat extends StatelessWidget {
  final bool isMe;
  final String message;
  final String time;
  final bool isSameSender;
  final String? replyTo;
  final bool isAudio;
  final Function(String) onPlayAudio;
  final bool isPlaying;
  final Duration audioPosition;
  final Duration audioDuration;

  MessageChat({
    required this.isMe,
    required this.message,
    required this.time,
    required this.isSameSender,
    this.replyTo,
    required this.isAudio,
    required this.onPlayAudio,
    required this.isPlaying,
    required this.audioPosition,
    required this.audioDuration,
  });

  // Helper function to truncate long text
  String _truncateText(String text, {int maxLength = 30}) {
    if (text.length > maxLength) {
      return text.substring(0, maxLength) + '...';
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 64.0 : 8.0,
        right: isMe ? 8.0 : 64.0,
        top: isSameSender
            ? 2.0
            : 8.0, // Reduce space between consecutive messages
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width *
                    0.75, // Increase bubble width
              ),
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Colors.teal : Colors.grey[300],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isMe ? 12 : 0),
                  topRight: Radius.circular(isMe ? 0 : 12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (replyTo != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.teal[700]
                            : Colors.grey[400], // Background color for replies
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 4,
                            height: 40,
                            margin: EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Colors.teal[800]
                                  : Colors.grey[500], // Color for the quote bar
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _truncateText(replyTo!),
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: replyTo != null ? 8 : 0),
                  if (isAudio)
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                          onPressed: () => onPlayAudio(message),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinearProgressIndicator(
                                value: audioDuration.inSeconds > 0
                                    ? audioPosition.inSeconds /
                                        audioDuration.inSeconds
                                    : 0,
                                backgroundColor:
                                    isMe ? Colors.teal[800] : Colors.grey[500],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isMe ? Colors.white : Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _formatDuration(audioPosition),
                                style: TextStyle(
                                  color: isMe ? Colors.white70 : Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      message,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: isMe ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      SizedBox(width: 5),
                      if (isMe)
                        const Icon(
                          Icons.done_all,
                          color: Colors.white70,
                          size: 16,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
