import 'dart:async';
import 'package:cyanase/helpers/loader.dart';
import 'package:cyanase/helpers/pay_subscriptions.dart';
import 'package:cyanase/screens/home/group/functions/sort_message_ui_function.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/database_helper.dart';
import './functions/audio_function.dart';
import './functions/message_function.dart';
import 'package:cyanase/screens/home/group/group_deposit.dart';
import 'chat_app_bar.dart';
import 'message_chat.dart';
import 'chat_input.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MessageChatScreen extends StatefulWidget {
  final String name;
  final String profilePic;
  final bool isGroup;
  final int? groupId;
  final String description;
  final VoidCallback? onMessageSent;
  final bool isAdminOnlyMode;
  final bool isCurrentUserAdmin;
  final bool allowSubscription;
  final bool hasUserPaid;
  final String subscriptionAmount;
  const MessageChatScreen({
    super.key,
    required this.name,
    required this.profilePic,
    this.isGroup = true,
    this.groupId,
    this.onMessageSent,
    required this.description,
    required this.isAdminOnlyMode, // Default to false (normal mode)
    required this.isCurrentUserAdmin,
    required this.allowSubscription,
    required this.hasUserPaid,
    required this.subscriptionAmount,
  });

  @override
  _MessageChatScreenState createState() => _MessageChatScreenState();
}

class _MessageChatScreenState extends State<MessageChatScreen> {
  final MessageFunctions _messageFunctions = MessageFunctions();
  final AudioFunctions _audioFunctions = AudioFunctions();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Map<String, dynamic>? _replyingToMessage;
  final String currentUserId = "current_user_id";
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<String> _memberNames = [];

  List<Map<String, dynamic>> _messages = [];
  Map<String, bool> _isPlayingMap = {};
  Map<String, Duration> _audioDurationMap = {};
  Map<String, Duration> _audioPositionMap = {};

  Timer? _recordingTimer;
  bool _showScrollToBottomButton = false;
  String? _currentDateHeader;

  bool _isLoading = true;
  bool _hasMoreMessages = true;
  int _currentPage = 0;
  final int _messagesPerPage = 20;

  Map<String, List<Map<String, dynamic>>> _groupedMessages = {};

  @override
  void initState() {
    super.initState();
    _loadGroupMembers();
    _loadMessages();
    _scrollController.addListener(_onScroll);
    if (widget.allowSubscription && !widget.hasUserPaid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSubscriptionReminder(context);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    _recordingTimer?.cancel();
    _audioFunctions.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      // Immediately hide the button after scrolling to bottom
      setState(() => _showScrollToBottomButton = false);
    }
  }

  void _scrollToBottomIfAtBottom() {
    if (_scrollController.hasClients) {
      final bool isAtBottom = _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50; // 50px tolerance
      if (isAtBottom) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  Future<void> _loadGroupMembers() async {
    if (widget.isGroup && widget.groupId != null) {
      try {
        final members = await _dbHelper.getGroupMemberNames(widget.groupId!);

        setState(() {
          _memberNames = members.map((e) => e["name"] ?? "").toList();
        });
      } catch (e) {
        print("Error loading group members: $e");
      }
    } else {
      setState(() {
        _memberNames = [widget.name];
      });
    }
  }

  Future<void> _loadMessages() async {
    print('Loading messages for group: ${widget.groupId}');
    setState(() => _isLoading = true);

    try {
      final newMessages = await _messageFunctions.getMessages(
        widget.groupId,
        limit: _messagesPerPage,
        offset: _currentPage * _messagesPerPage,
      );

      if (newMessages.isEmpty) {
        setState(() => _hasMoreMessages = false);
      } else {
        setState(() {
          _messages.addAll(newMessages);
          _messages = MessageSort.sortMessagesByDate(
              _messages); // Updated to use MessageSort
          _groupedMessages = MessageSort.groupMessagesByDate(
              _messages); // Updated to use MessageSort
          _currentPage++;
          print('Grouped messages: ${_groupedMessages.keys}');
        });
      }
    } catch (e) {
      print("Error loading messages: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading messages: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
      if (_currentPage == 1) _scrollToBottom();
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final double currentPosition = _scrollController.position.pixels;
      final double maxScrollExtent = _scrollController.position.maxScrollExtent;

      // Calculate the approximate number of messages below the current view
      // Assuming each message takes about 80 pixels (adjust this based on your MessageChat height)
      final double viewportHeight =
          _scrollController.position.viewportDimension;
      final double remainingScrollDistance = maxScrollExtent - currentPosition;
      final int messagesBelow =
          (remainingScrollDistance / 80).ceil(); // Approximate messages below

      // Check if the user is at the bottom (within 10px tolerance)
      final bool isAtBottom = currentPosition >= maxScrollExtent - 10;

      setState(() {
        // Show button only if there are 10 or more messages below and not at bottom
        _showScrollToBottomButton = messagesBelow >= 10 && !isAtBottom;
        _updateFloatingDateHeader();
      });

      // Load more messages if at the top and there are more to load
      if (currentPosition == maxScrollExtent &&
          !_isLoading &&
          _hasMoreMessages) {
        _loadMessages();
      }
    }
  }

  void _updateFloatingDateHeader() {
    if (_scrollController.hasClients) {
      final offset = _scrollController.offset;
      String? newHeader;

      for (final dateKey in _groupedMessages.keys.toList().reversed) {
        final messages = _groupedMessages[dateKey]!;
        final firstMessageIndex = _messages.indexOf(messages.last);
        final lastMessageIndex = _messages.indexOf(messages.first);

        final firstMessageOffset =
            (_messages.length - firstMessageIndex - 1) * 80.0;
        final lastMessageOffset =
            (_messages.length - lastMessageIndex - 1) * 80.0;

        if (offset >= firstMessageOffset &&
            offset <= lastMessageOffset + 80.0) {
          newHeader = dateKey;
          break;
        }
      }

      if (newHeader == null && _groupedMessages.isNotEmpty) {
        newHeader = _groupedMessages.keys.last;
      }

      if (newHeader != _currentDateHeader) {
        setState(() => _currentDateHeader = newHeader);
      }
    }
  }

  void _setReplyMessage(Map<String, dynamic> message) {
    setState(() {
      _replyingToMessage = {
        'id': message['id'],
        'message': message['message'],
        'sender_id': message['sender_id'],
      };
    });
  }

  void _showSubscriptionReminder(BuildContext context) {
    bool showPaymentOptions = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    );
                  },
                  child: showPaymentOptions
                      ? PayHelper(
                          amount: widget.subscriptionAmount,
                          groupId: widget.groupId ?? 0,
                          paymentType: 'group_subscription',
                          userId: currentUserId,
                          onBack: Navigator.of(context).pop,
                          onPaymentSuccess: () {
                            setState(() {});
                            Navigator.of(context).pop();

                            widget.onMessageSent?.call();
                          },
                        )
                      : Container(
                          key: const ValueKey('subscription_reminder'),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lock,
                                size: 40,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Subscription Required",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: primaryTwo),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Please pay the monthly subscription of ${widget.subscriptionAmount} to participate in this group.",
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text(
                                      "Cancel",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        showPaymentOptions = true;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      backgroundColor:
                                          primaryTwo, // Background color when enabled
                                      disabledBackgroundColor:
                                          primaryTwo, // Background color when disabled
                                    ),
                                    child: const Text(
                                      "Pay Now",
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _sendImageMessage(String imagePath) async {
    try {
      final newMessage = {
        "id": DateTime.now().millisecondsSinceEpoch,
        "group_id": widget.groupId,
        "sender_id": currentUserId,
        "message": imagePath,
        "type": "image",
        "timestamp": DateTime.now().toIso8601String(),
        "media_id": null,
        "status": "sent",
        "isMe": 1,
        "reply_to_id": _replyingToMessage?['id'],
        "reply_to_message": _replyingToMessage?['message'],
      };

      setState(() {
        _messages.add(newMessage);
        _groupedMessages = MessageSort.groupMessagesByDate(_messages);
        _replyingToMessage = null;
      });
      _scrollToBottomIfAtBottom();

      final mediaId = await _dbHelper.insertImageFile(imagePath);
      await _dbHelper.insertMessage({...newMessage, "media_id": mediaId});

      widget.onMessageSent?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send image: $e")),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Message cannot be empty")),
      );
      return;
    }

    try {
      final messageText = _controller.text.trim();
      final newMessage = {
        "id": DateTime.now().millisecondsSinceEpoch,
        "group_id": widget.groupId,
        "sender_id": currentUserId,
        "message": messageText,
        "type": "text",
        "timestamp": DateTime.now().toIso8601String(),
        "status": "sent",
        "isMe": 1,
        "reply_to_id": _replyingToMessage?['id'],
        "reply_to_message": _replyingToMessage?['message'],
      };

      setState(() {
        _messages.add(newMessage);
        _groupedMessages = MessageSort.groupMessagesByDate(_messages);
        _replyingToMessage = null;
      });
      _controller.clear();
      _scrollToBottomIfAtBottom();

      await _dbHelper.insertMessage(newMessage);
      widget.onMessageSent?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send message: $e")),
      );
    }
  }

  void _startRecording() async {
    await _audioFunctions.startRecording();
    setState(() {
      _isRecording = true;
      _recordingDuration = Duration.zero;
    });
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _recordingDuration += const Duration(seconds: 1));
    });
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioFunctions.stopRecording();
      _recordingTimer?.cancel();
      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
      });
      if (path != null) await _sendAudioMessage(path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to stop recording: $e")),
      );
    }
  }

  void _cancelRecording() async {
    await _audioFunctions.stopRecording();
    _recordingTimer?.cancel();
    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });
  }

  Future<void> _sendAudioMessage(String path) async {
    try {
      final newMessage = {
        "id": DateTime.now().millisecondsSinceEpoch,
        "group_id": widget.groupId,
        "sender_id": currentUserId,
        "message": path,
        "type": "audio",
        "timestamp": DateTime.now().toIso8601String(),
        "media_id": null,
        "status": "sent",
        "isMe": 1,
        "reply_to_id": _replyingToMessage?['id'],
        "reply_to_message": _replyingToMessage?['message'],
      };

      setState(() {
        _messages.add(newMessage);
        _groupedMessages = MessageSort.groupMessagesByDate(_messages);
        _replyingToMessage = null;
      });
      _scrollToBottomIfAtBottom();

      final mediaId = await _dbHelper.insertAudioFile(path);
      await _dbHelper.insertMessage({...newMessage, "media_id": mediaId});

      widget.onMessageSent?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send audio: $e")),
      );
    }
  }

  void _playAudio(dynamic messageId, String path) async {
    final messageIdStr = messageId.toString();
    if (_isPlayingMap[messageIdStr] ?? false) {
      await _audioFunctions.pauseAudio();
      setState(() => _isPlayingMap[messageIdStr] = false);
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
        setState(() => _audioPositionMap[messageIdStr] = position);
      });
      _audioFunctions.onDurationChanged((duration) {
        setState(() => _audioDurationMap[messageIdStr] = duration);
      });
      _audioFunctions.onPlayerComplete(() {
        setState(() {
          _isPlayingMap[messageIdStr] = false;
          _audioPositionMap[messageIdStr] = Duration.zero;
        });
      });
      setState(() => _isPlayingMap[messageIdStr] = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MessageAppBar(
        name: widget.name,
        profilePic: widget.profilePic,
        memberNames: _memberNames,
        groupId: widget.groupId,
        description: widget.description,
        onDepositPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DepositScreen(
                groupName: widget.name,
                profilePic: widget.profilePic,
                groupId: widget.groupId ?? 0,
              ),
            ),
          );
        },
        onBackPressed: () {
          widget.onMessageSent?.call();
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
            onNotification: (scrollInfo) {
              _onScroll();
              return true;
            },
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.only(top: 16, bottom: 80),
              itemCount: _groupedMessages.length + 1,
              itemBuilder: (context, index) {
                if (index == _groupedMessages.length) {
                  return _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: Loader()),
                        )
                      : const SizedBox.shrink();
                }

                final dateKey = _groupedMessages.keys.elementAt(index);
                final messagesForDate = _groupedMessages[dateKey]!;

                return Column(
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[800]!.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          dateKey,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    ...messagesForDate.map((message) {
                      final bool isSameSender = messagesForDate
                                  .indexOf(message) >
                              0 &&
                          messagesForDate[messagesForDate.indexOf(message) - 1]
                                  ["isMe"] ==
                              message["isMe"] &&
                          messagesForDate[messagesForDate.indexOf(message) - 1]
                                  ["type"] !=
                              "notification"; // Don't group notifications with regular messages
                      return GestureDetector(
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity! > 0 &&
                              message["type"] != "notification") {
                            _setReplyMessage(message);
                          }
                        },
                        child: MessageChat(
                          senderAvatar: '', // Update with actual avatar logic
                          senderName:
                              'wasswa', // Update with actual sender name
                          isMe: message["isMe"] == 1,
                          message: message["message"],
                          time: message["timestamp"],
                          isSameSender: isSameSender,
                          replyToId: message["reply_to_id"]?.toString(),
                          replyTo: message["reply_to_message"],
                          isAudio: message["type"] == "audio",
                          isImage: message["type"] == "image",
                          isNotification: message["type"] ==
                              "notification", // Added for notifications
                          onPlayAudio: _playAudio,
                          isPlaying:
                              _isPlayingMap[message["id"].toString()] ?? false,
                          audioDuration:
                              _audioDurationMap[message["id"].toString()] ??
                                  Duration.zero,
                          audioPosition:
                              _audioPositionMap[message["id"].toString()] ??
                                  Duration.zero,
                          messageId: message["id"].toString(),
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ),
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: _currentDateHeader != null
                  ? Center(
                      child: Container(
                        key: ValueKey<String>(_currentDateHeader!),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[800]!.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _currentDateHeader!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          if (_showScrollToBottomButton)
            Positioned(
              bottom: 80,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                onPressed: _scrollToBottom,
                backgroundColor: primaryTwo,
                child: Icon(Icons.arrow_downward, color: primaryColor),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: InputArea(
              isAdminOnlyMode: widget.isAdminOnlyMode,
              isCurrentUserAdmin: widget.isCurrentUserAdmin,
              onSendAudioMessage: _sendAudioMessage,
              controller: _controller,
              isRecording: _isRecording,
              recordingDuration: _recordingDuration,
              onSendMessage: _sendMessage,
              onStartRecording: _startRecording,
              onStopRecording: _stopRecording,
              onSendImageMessage: _sendImageMessage,
              onCancelRecording: _cancelRecording,
              replyToId: _replyingToMessage?['id']?.toString(),
              replyingToMessage: _replyingToMessage?['message'],
              onCancelReply: () => setState(() => _replyingToMessage = null),
              audioFunctions: _audioFunctions,
            ),
          ),
        ],
      ),
    );
  }
}
