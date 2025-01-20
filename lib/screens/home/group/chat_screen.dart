import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/date_helper.dart'; // Import the date formatter
import './functions/audio_function.dart';
import './functions/message_function.dart';
import 'package:cyanase/screens/home/group/group_deposit.dart';
import 'chat_app_bar.dart'; // Import the AppBar
import 'message_chat.dart'; // Import the MessageChat widget
import 'chat_input.dart'; // Import the InputArea
import 'full_screen_image_viewer.dart'; // Import the FullScreenImage widget
import './functions/sort_message_ui_function.dart'; // Import MessageUtils
import 'package:flutter_svg/flutter_svg.dart';

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
  final String currentUserId = "current_user_id";
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<String> _memberNames = [];
  List<Map<String, dynamic>> _messages = []; // Store all messages
  Map<String, bool> _isPlayingMap = {};
  Map<String, Duration> _audioDurationMap = {};
  Map<String, Duration> _audioPositionMap = {};

  Timer? _recordingTimer;
  String? _lastMessageId;
  bool _showScrollToBottomButton = false;
  String? _currentDateHeader;

  bool _isLoading = false;
  bool _hasMoreMessages = true;
  int _currentPage = 0;
  final int _messagesPerPage = 20;

  Map<String, List<Map<String, dynamic>>> _groupedMessages =
      {}; // Grouped messages by date

  @override
  void initState() {
    super.initState();
    _loadGroupMembers();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToLastMessage();
    });
    _loadMessages(); // Load initial messages
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.minScrollExtent &&
        !_isLoading &&
        _hasMoreMessages) {
      _loadMessages(); // Load older messages when scrolled to the top
    }

    // Show/hide scroll-to-bottom button
    setState(() {
      _showScrollToBottomButton = _scrollController.offset <
          _scrollController.position.maxScrollExtent - 100;
    });
  }

  void _scrollToLastMessage() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _loadGroupMembers() async {
    if (widget.isGroup && widget.groupId != null) {
      try {
        final memberNames =
            await _dbHelper.getGroupMemberNames(widget.groupId!);
        setState(() {
          _memberNames = memberNames;
        });
      } catch (e) {
        print("Error loading group members: $e");
      }
    } else if (!widget.isGroup) {
      setState(() {
        _memberNames = [widget.name]; // Show the other user's name
      });
    }
  }

  Future<void> _loadMessages() async {
    if (_isLoading || !_hasMoreMessages) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newMessages = await _messageFunctions.getMessages(
        widget.groupId,
        limit: _messagesPerPage,
        offset: _currentPage * _messagesPerPage,
      );

      if (newMessages.isEmpty) {
        setState(() {
          _hasMoreMessages = false;
        });
      } else {
        setState(() {
          _messages.insertAll(0, newMessages); // Prepend older messages
          _currentPage++;
          _groupedMessages = MessageUtils.groupMessagesByDate(_messages);
        });
      }
    } catch (e) {
      print("Error loading messages: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      // Add the image message to the local list immediately
      final newMessage = {
        "id": DateTime.now().millisecondsSinceEpoch, // Temporary ID
        "group_id": widget.groupId,
        "sender_id": "current_user_id", // Replace with actual user ID
        "message": imagePath,
        "type": "image",
        "timestamp": DateTime.now().toIso8601String(),
        "media_id": null, // Will be updated after inserting into the database
        "status": "sent",
      };

      setState(() {
        _messages.add(newMessage); // Add the message to the local list
        _groupedMessages = MessageUtils.groupMessagesByDate(_messages);
      });

      // Scroll to the last message
      _scrollToLastMessage();

      // Insert the image into the database
      final mediaId = await _dbHelper.insertImageFile(imagePath);
      await _dbHelper.insertMessage({
        ...newMessage,
        "media_id": mediaId, // Update with the actual media ID
      });

      if (widget.onMessageSent != null) {
        widget.onMessageSent!();
      }
    } catch (e) {
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

      await _dbHelper.insertMessage({
        "group_id": widget.groupId,
        "sender_id": "current_user_id",
        "message": messageText,
        "type": "text",
        "timestamp": DateTime.now().toIso8601String(),
        "status": "sent",
      });

      _controller.clear();

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

  Future<void> _stopRecording() async {
    try {
      // Stop the recording
      final path = await _audioFunctions.stopRecording();

      // Cancel the recording timer
      _recordingTimer?.cancel();
      _recordingTimer = null;

      // Update the state to reflect that recording has stopped
      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
      });

      // Send the audio message if the file exists
      if (path != null) {
        await _sendAudioMessage(path);
      }
    } catch (e) {
      print("Error stopping recording: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to stop recording: ${e.toString()}")),
      );
    }
  }

  void _cancelRecording() async {
    await _audioFunctions.stopRecording();
    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });
  }

  Future<void> _sendAudioMessage(String path) async {
    try {
      // Add the audio message to the local list immediately
      final newMessage = {
        "id": DateTime.now().millisecondsSinceEpoch, // Temporary ID
        "group_id": widget.groupId,
        "sender_id": "current_user_id", // Replace with actual user ID
        "message": path,
        "type": "audio",
        "timestamp": DateTime.now().toIso8601String(),
        "media_id": null, // Will be updated after inserting into the database
        "status": "sent",
      };

      setState(() {
        _messages.add(newMessage); // Add the message to the local list
        _groupedMessages = MessageUtils.groupMessagesByDate(_messages);
      });

      // Scroll to the last message
      _scrollToLastMessage();

      // Insert the audio file into the database
      final mediaId = await _dbHelper.insertAudioFile(path);
      await _dbHelper.insertMessage({
        ...newMessage,
        "media_id": mediaId, // Update with the actual media ID
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

  void _playAudio(dynamic messageId, String path) async {
    // Convert messageId to String if it's an int
    final String messageIdStr = messageId.toString();

    if (_isPlayingMap[messageIdStr] ?? false) {
      await _audioFunctions.pauseAudio();
      setState(() {
        _isPlayingMap[messageIdStr] = false;
      });
    } else {
      for (var id in _isPlayingMap.keys) {
        if (_isPlayingMap[id] == true && id != messageIdStr) {
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
          _audioPositionMap[messageIdStr] = position;
        });
      });

      _audioFunctions.onDurationChanged((duration) {
        setState(() {
          _audioDurationMap[messageIdStr] = duration;
        });
      });

      _audioFunctions.onPlayerComplete(() {
        setState(() {
          _isPlayingMap[messageIdStr] = false;
          _audioPositionMap[messageIdStr] = Duration.zero;
        });
      });

      setState(() {
        _isPlayingMap[messageIdStr] = true;
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
            widget.onMessageSent!();
          }
          Navigator.pop(context);
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
          NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels ==
                      scrollInfo.metrics.minScrollExtent &&
                  !_isLoading &&
                  _hasMoreMessages) {
                // User has scrolled to the top, load older messages
                _loadMessages();
              }
              return true;
            },
            child: ListView.builder(
              controller: _scrollController,
              reverse: true, // Display most recent messages at the bottom
              padding: EdgeInsets.only(top: 16, bottom: 80),
              itemCount:
                  _groupedMessages.length + 1, // +1 for the loading indicator
              itemBuilder: (context, index) {
                if (index == _groupedMessages.length) {
                  // Show loading indicator at the top
                  return _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : SizedBox.shrink();
                }

                final dateKey = _groupedMessages.keys.elementAt(index);
                final messagesForDate = _groupedMessages[dateKey]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...messagesForDate.map((message) {
                      final bool isSameSender = messagesForDate
                                  .indexOf(message) >
                              0 &&
                          messagesForDate[messagesForDate.indexOf(message) - 1]
                                  ["isMe"] ==
                              message["isMe"];
                      return GestureDetector(
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity! < 0) {
                            setState(() {
                              _replyingToMessage = message["message"];
                            });
                          }
                        },
                        child: MessageChat(
                          isMe: message["isMe"] ?? false, // Ensure non-null
                          message: message[
                              "message"], // The message content or file path
                          time: message[
                              "timestamp"], // Ensure this is the correct field
                          isSameSender: isSameSender,
                          replyTo: message["replyTo"],
                          isAudio: message["type"] == "audio",
                          isImage: message["type"] == "image",
                          onPlayAudio: (messageId, path) => _playAudio(
                              messageId, path), // Pass both arguments
                          isPlaying: _isPlayingMap[message["id"].toString()] ??
                              false, // Ensure messageId is a String
                          audioDuration:
                              _audioDurationMap[message["id"].toString()] ??
                                  Duration.zero, // Ensure messageId is a String
                          audioPosition:
                              _audioPositionMap[message["id"].toString()] ??
                                  Duration.zero, // Ensure messageId is a String
                          messageId:
                              message["id"].toString(), // Convert int to String
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ),
          // Floating Date Header
          if (_currentDateHeader != null)
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 300), // Smooth transition
                child: _currentDateHeader != null
                    ? Center(
                        child: Container(
                          key: ValueKey<String>(
                              _currentDateHeader!), // Unique key for animation
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(
                                0.7), // Semi-transparent background
                            borderRadius:
                                BorderRadius.circular(20), // Rounded corners
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(0.2), // Subtle shadow
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            _currentDateHeader!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14, // Smaller font size
                              fontWeight:
                                  FontWeight.w500, // Lighter font weight
                            ),
                          ),
                        ),
                      )
                    : SizedBox.shrink(), // Hide if no date header
              ),
            ),
          if (_showScrollToBottomButton)
            Positioned(
              bottom: 80,
              right: 16,
              child: FloatingActionButton(
                onPressed: _scrollToLastMessage,
                child: Icon(Icons.arrow_downward),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: InputArea(
              onSendAudioMessage: _sendAudioMessage,
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
              audioFunctions: _audioFunctions,
            ),
          ),
        ],
      ),
    );
  }
}
