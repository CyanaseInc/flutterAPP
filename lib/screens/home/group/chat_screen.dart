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
import 'package:cyanase/helpers/websocket_service.dart';
import 'package:cyanase/helpers/web_shared_storage.dart';
import 'dart:io';
import 'dart:convert';

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
  final WebSocketService _wsService = WebSocketService.instance;
  Map<String, dynamic>? _replyingToMessage;
  String? _currentUserId;
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

  bool _isTyping = false;
  Timer? _typingTimer;
  Map<String, String> _typingUsers =
      {}; // Map of user_id to username who are typing

  @override
  void initState() {
    super.initState();
    _loadGroupMembers();
    _loadMessages();
    _scrollController.addListener(_onScroll);
    _initializeWebSocket();
    _getCurrentUserId();
    if (widget.allowSubscription && !widget.hasUserPaid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSubscriptionReminder(context);
      });
    }
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _wsService.dispose();
    _scrollController.dispose();
    _controller.dispose();
    _recordingTimer?.cancel();
    _audioFunctions.dispose();
    _typingTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0, // Since the list is reversed, 0 is the bottom
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
        // Get current user ID for comparison
        final db = await _dbHelper.database;
        final userProfile = await db.query('profile', limit: 1);
        final currentUserId = userProfile.first['id'] as String?;

        setState(() {
          // Process messages to set isMe flag and status correctly
          final processedMessages = newMessages.map((message) {
            final isMe = message['sender_id'].toString() == currentUserId;
            return {
              ...message,
              'isMe': isMe ? 1 : 0,
              'status': isMe ? (message['status'] ?? 'sent') : 'received',
              'message': message['message'] ??
                  message['content'] ??
                  '', // Handle both message and content fields
              'type': message['type'] ??
                  message['message_type'] ??
                  'text', // Handle both type and message_type fields
            };
          }).toList();

          _messages.addAll(processedMessages);
          _messages = MessageSort.sortMessagesByDate(_messages);
          _groupedMessages = MessageSort.groupMessagesByDate(_messages);
          _currentPage++;
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
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

  Future<void> _getCurrentUserId() async {
    try {
      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isNotEmpty) {
        setState(() {
          _currentUserId = userProfile.first['id'] as String?;
        });
      }
    } catch (e) {
      print('Error getting current user ID: $e');
    }
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
                          userId: _currentUserId ?? '',
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

  void _initializeWebSocket() {
    _wsService.onMessageReceived = (data) {
      print('WebSocket received message: $data');
      if (data['type'] == 'message') {
        _handleNewMessage(data);
      } else if (data['type'] == 'update_message_status') {
        print('DEBUG: Received message status update: $data');
        _handleMessageStatusUpdate(data);
      } else if (data['type'] == 'message_id_update') {
        print('DEBUG: Received message ID update: $data');
        _handleMessageIdUpdate(data);
      } else if (data['type'] == 'typing') {
        _handleTypingStatus(data['data']);
      }
    };
    _wsService.initialize(widget.groupId.toString());
  }

  void _handleMessageIdUpdate(Map<String, dynamic> data) {
    final oldId = data['old_id'].toString();
    final newId = data['new_id'].toString();
    final groupId = data['group_id'].toString();
    final status = data['status'];

    if (groupId != widget.groupId.toString()) return;

    print(
        'DEBUG: Updating message ID from $oldId to $newId with status $status');
    setState(() {
      // First try to find by temp_id
      final index = _messages.indexWhere((msg) =>
          msg['temp_id']?.toString() == oldId || msg['id'].toString() == oldId);

      if (index != -1) {
        print('DEBUG: Found message at index $index, updating ID and status');
        _messages[index]['id'] = newId;
        if (status != null) {
          _messages[index]['status'] = status;
        }
        _groupedMessages = MessageSort.groupMessagesByDate(_messages);
      } else {
        print(
            'DEBUG: Message with ID/temp_id $oldId not found in messages list');
        print(
            'DEBUG: Available message IDs: ${_messages.map((m) => '${m['id']} (temp: ${m['temp_id']})').join(', ')}');
      }
    });
  }

  void _handleMessageStatusUpdate(Map<String, dynamic> data) {
    print('DEBUG: Looking for message with ID: ${data['message_id']}');
    print('DEBUG: Current messages count: ${_messages.length}');

    final messageId = data['message_id'].toString();
    final status = data['status'];
    final groupId = data['group_id']?.toString();

    if (groupId != null && groupId != widget.groupId.toString()) return;

    setState(() {
      final index = _messages.indexWhere((msg) =>
          msg['id'].toString() == messageId ||
          msg['temp_id']?.toString() == messageId);
      print('DEBUG: Found message at index: $index');

      if (index != -1) {
        print('DEBUG: Updating message status to: $status');
        _messages[index]['status'] = status;
        _groupedMessages = MessageSort.groupMessagesByDate(_messages);
      } else {
        print('DEBUG: Message $messageId not found in messages list');
        print(
            'DEBUG: Available message IDs: ${_messages.map((m) => '${m['id']} (temp: ${m['temp_id']})').join(', ')}');
      }
    });
  }

  void _handleMessageStatus(Map<String, dynamic> status) {
    print('DEBUG: Received message status update: $status'); // Debug log
    if (!mounted) {
      print('DEBUG: Widget not mounted, skipping status update');
      return;
    }

    final messageId = status['message_id'].toString();
    print('DEBUG: Looking for message with ID: $messageId');
    print('DEBUG: Current messages count: ${_messages.length}');

    final messageIndex =
        _messages.indexWhere((msg) => msg['id'].toString() == messageId);
    print('DEBUG: Found message at index: $messageIndex');

    if (messageIndex != -1) {
      print(
          'DEBUG: Current message status: ${_messages[messageIndex]['status']}');
      print('DEBUG: Updating to new status: ${status['status']}');

      // Create a new list to force UI update
      final updatedMessages = List<Map<String, dynamic>>.from(_messages);
      updatedMessages[messageIndex] = {
        ...updatedMessages[messageIndex],
        'status': status['status'],
      };

      // Update both lists to ensure UI rebuilds
      setState(() {
        _messages = updatedMessages;
        _groupedMessages = MessageSort.groupMessagesByDate(_messages);
      });

      print('DEBUG: Message status updated in list');
      print('DEBUG: New message status: ${_messages[messageIndex]['status']}');

      // If message is now sent, remove it from the queue
      if (status['status'] == 'sent') {
        _wsService.removeFromQueue(messageId);
      }
    } else {
      print('DEBUG: Message $messageId not found in messages list');
      print(
          'DEBUG: Available message IDs: ${_messages.map((m) => m['id']).join(', ')}');
    }
  }

  void _handleMessageUpdate(Map<String, dynamic> update) {
    setState(() {
      final messageId = update['message_id'].toString();
      final messageIndex =
          _messages.indexWhere((msg) => msg['id'].toString() == messageId);
      if (messageIndex != -1) {
        _messages[messageIndex] = {
          ..._messages[messageIndex],
          'message': update['content'],
          'edited': true,
          'edited_at': update['edited_at'],
        };
        _groupedMessages = MessageSort.groupMessagesByDate(_messages);
      }
    });
  }

  void _handleMessageDelete(Map<String, dynamic> delete) {
    setState(() {
      final messageId = delete['message_id'].toString();
      _messages.removeWhere((msg) => msg['id'].toString() == messageId);
      _groupedMessages = MessageSort.groupMessagesByDate(_messages);
    });
  }

  void _sendTypingStatus(bool isTyping) async {
    if (_currentUserId == null) return;

    // Only send typing status through WebSocket, no database operations
    final typingMessage = {
      'type': 'typing',
      'user_id': _currentUserId,
      'group_id': widget.groupId.toString(),
      'is_typing': isTyping,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      // Use the new method that doesn't save to database
      await _wsService.sendTypingStatus(typingMessage);
    } catch (e) {
      print('Error sending typing status: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _currentUserId == null) return;

    try {
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      print('DEBUG: Sending message with temp_id: $tempId');

      // Create the message object
      final message = {
        'type': 'send_message',
        'content': _controller.text.trim(),
        'sender_id': _currentUserId,
        'group_id': widget.groupId.toString(),
        'message_type': 'text',
        'temp_id': tempId,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'sending'
      };

      // Add message to UI immediately with 'sending' status and temp_id
      setState(() {
        _messages.add({
          'id': tempId,
          'temp_id': tempId,
          'group_id': widget.groupId,
          'sender_id': _currentUserId,
          'message': message['content'],
          'type': 'text',
          'timestamp': message['timestamp'],
          'status': 'sending',
          'isMe': 1,
          'edited': false,
        });
        _groupedMessages = MessageSort.groupMessagesByDate(_messages);
        _replyingToMessage = null;
      });

      // Send message through WebSocket service
      await _wsService.sendMessage(message);

      _controller.clear();
      _scrollToBottomIfAtBottom();
      widget.onMessageSent?.call();
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send message: $e")),
      );
    }
  }

  Future<void> _sendImageMessage(String imagePath) async {
    try {
      if (_currentUserId == null) return;

      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      // Read the image file and convert to base64
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      final fileName = imagePath.split('/').last;

      final message = {
        'type': 'send_message',
        'content': 'Image',
        'sender_id': _currentUserId,
        'group_id': widget.groupId.toString(),
        'message_type': 'image',
        'message_id': messageId,
        'attachment_type': 'image',
        'file_name': fileName,
        'file_data': base64Image,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'sending'
      };

      // Add message to UI immediately with 'sending' status
      setState(() {
        _messages.add({
          'id': messageId,
          'group_id': widget.groupId,
          'sender_id': _currentUserId,
          'message': imagePath,
          'type': 'image',
          'timestamp': message['timestamp'],
          'status': 'sending',
          'isMe': 1,
          'reply_to_id': _replyingToMessage?['id'],
          'reply_to_message': _replyingToMessage?['message'],
        });
        _groupedMessages = MessageSort.groupMessagesByDate(_messages);
        _replyingToMessage = null;
      });

      // Send message through WebSocket
      await _wsService.sendMessage(message);

      _scrollToBottomIfAtBottom();
      widget.onMessageSent?.call();
    } catch (e) {
      print('Error sending image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send image: $e")),
      );
    }
  }

  Future<void> _sendAudioMessage(String path) async {
    try {
      if (_currentUserId == null) return;

      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      // Read the audio file and convert to base64
      final file = File(path);
      final bytes = await file.readAsBytes();
      final base64Audio = base64Encode(bytes);
      final fileName = path.split('/').last;

      final message = {
        'type': 'send_message',
        'content': 'Audio message',
        'sender_id': _currentUserId,
        'group_id': widget.groupId.toString(),
        'message_type': 'audio',
        'message_id': messageId,
        'attachment_type': 'file',
        'file_name': fileName,
        'file_data': base64Audio,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'sending'
      };

      // Add message to UI immediately with 'sending' status
      setState(() {
        _messages.add({
          'id': messageId,
          'group_id': widget.groupId,
          'sender_id': _currentUserId,
          'message': path,
          'type': 'audio',
          'timestamp': message['timestamp'],
          'status': 'sending',
          'isMe': 1,
          'reply_to_id': _replyingToMessage?['id'],
          'reply_to_message': _replyingToMessage?['message'],
        });
        _groupedMessages = MessageSort.groupMessagesByDate(_messages);
        _replyingToMessage = null;
      });

      // Send message through WebSocket
      await _wsService.sendMessage(message);

      _scrollToBottomIfAtBottom();
      widget.onMessageSent?.call();
    } catch (e) {
      print('Error sending audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send audio: $e")),
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

  void _scrollToMessage(String messageId) {
    // Find the message in the flattened messages list
    final index =
        _messages.indexWhere((msg) => msg['id'].toString() == messageId);
    if (index != -1) {
      // Calculate the scroll position based on the message index
      final scrollPosition = (_messages.length - index - 1) * 100.0;

      // Get the viewport height
      final viewportHeight = _scrollController.position.viewportDimension;

      // Calculate the target position to center the message in the viewport
      final targetPosition = scrollPosition -
          (viewportHeight / 2) +
          50; // 50 is half the approximate message height

      // Ensure we don't scroll beyond the limits
      final maxScroll = _scrollController.position.maxScrollExtent;
      final minScroll = _scrollController.position.minScrollExtent;
      final finalPosition = targetPosition.clamp(minScroll, maxScroll);

      _scrollController.animateTo(
        finalPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleTypingStatus(Map<String, dynamic> data) {
    setState(() {
      if (data['is_typing'] == true) {
        _typingUsers[data['user_id']] = data['username'] ?? 'Someone';
      } else {
        _typingUsers.remove(data['user_id']);
      }
    });
  }

  void _handleNewMessage(Map<String, dynamic> message) async {
    try {
      print('Received new message: $message'); // Debug log
      // Get the current user's ID from the profile table
      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      final currentUserId = userProfile.first['id'] as String?;

      final isMe = message['sender_id'].toString() == currentUserId;

      // Only add the message if it's not from us (our messages are already added)
      if (!isMe) {
        setState(() {
          _messages.add({
            'id': message['id'] ?? message['message_id'],
            'group_id': widget.groupId,
            'sender_id': message['sender_id'],
            'message': message['content'] ?? message['message'] ?? '',
            'type': message['message_type'] ?? message['type'] ?? 'text',
            'timestamp': message['timestamp'],
            'status': 'received',
            'isMe': 0,
            'reply_to': message['reply_to'],
            'media_url': message['media_url'],
            'edited': message['edited'] ?? false,
            'edited_at': message['edited_at'],
          });
          _groupedMessages = MessageSort.groupMessagesByDate(_messages);
        });
        _scrollToBottomIfAtBottom();
      }
    } catch (e) {
      print('Error handling new message: $e'); // Debug log
    }
  }

  void _onTextChanged() {
    if (_typingTimer?.isActive ?? false) {
      _typingTimer?.cancel();
    }

    if (_controller.text.isNotEmpty) {
      // Only send typing status, no message status
      _sendTypingStatus(true);
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _sendTypingStatus(false);
      });
    } else {
      _sendTypingStatus(false);
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
                          isNotification: message["type"] == "notification",
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
                          onReply: (messageId, messageText) {
                            _setReplyMessage({
                              'id': messageId,
                              'message': messageText,
                              'sender_id': message["sender_id"],
                            });
                          },
                          onReplyTap: _scrollToMessage,
                          messageStatus: message["status"] ?? "sent",
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
            bottom: 80, // Adjust based on your input area height
            left: 0,
            right: 0,
            child: _buildTypingIndicator(),
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
              currentUserId: _currentUserId,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    if (_typingUsers.isEmpty) return const SizedBox.shrink();

    final typingText = _typingUsers.length == 1
        ? '${_typingUsers.values.first} is typing...'
        : '${_typingUsers.length} people are typing...';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        typingText,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
