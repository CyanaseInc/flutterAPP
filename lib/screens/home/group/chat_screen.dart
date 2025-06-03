import 'dart:async';
import 'package:cyanase/helpers/loader.dart';
import 'package:cyanase/helpers/pay_subscriptions.dart';
import 'package:cyanase/screens/home/group/functions/sort_message_ui_function.dart';
import 'package:cyanase/screens/home/group/widgets/audio_player_widget.dart';
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
import 'package:cyanase/helpers/chat_websocket_service.dart';
import 'package:cyanase/helpers/notification_service.dart';
import 'package:intl/intl.dart';

import 'dart:io';
import 'dart:convert';

import 'package:path_provider/path_provider.dart';


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
  final ChatWebSocketService _wsService = ChatWebSocketService.instance;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  Map<String, dynamic>? _replyingToMessage;
  String? _currentUserId;
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<String> _memberNames = [];
  Timer? _dbPollingTimer;

  List<Map<String, dynamic>> _messages = [];
  Map<String, bool> _isPlayingMap = {};
  Map<String, Duration> _audioDurationMap = {};
  Map<String, Duration> _audioPositionMap = {};
StreamSubscription<Map<int, List<Map<String, dynamic>>>>? _messageStreamSubscription;
String? _lastMessageTimestamp;
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

  String? _token;


  // Add progress tracking maps
  Map<String, double> _uploadProgress = {};
  Map<String, double> _downloadProgress = {};

  // Add these new variables
  int _unreadCount = 0;
  bool _showUnreadBadge = false;
  final GlobalKey _unreadBadgeKey = GlobalKey();
  Timer? _unreadBadgeTimer;

  // Add these new variables
  bool _isUserScrolling = false;
  bool _shouldAutoScroll = true;
  Timer? _scrollDebounceTimer;
  double _lastScrollPosition = 0;


  // Add these new variables
  List<String> _unreadMessageIds = [];
  bool _hasUnreadMessages = false;
  bool _isInitialLoad = true;

  // Add this new variable to track if we're scrolling up
  bool _isScrollingUp = false;

 @override
void initState() {
  super.initState();
  _loadGroupMembers();
  _loadMessages(isInitialLoad: true);
  _scrollController.addListener(_onScroll);
  _initializeWebSocket();
  _getCurrentUserId();
  _getToken();
  if (widget.allowSubscription == true && widget.hasUserPaid == false) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSubscriptionReminder(context);
    });
  }
  _controller.addListener(_onTextChanged);
  _setupMessageStream(); // Add stream setup
  _initializeUnreadMessages();
}

  @override
@override
void dispose() {
  print('🔵 [ChatScreen] Disposing chat screen');
  _wsService.onMessageReceived = null;
  _scrollController.dispose();
  _controller.dispose();
  _recordingTimer?.cancel();
  _audioFunctions.dispose();
  _typingTimer?.cancel();
  _controller.removeListener(_onTextChanged);
  _unreadBadgeTimer?.cancel();
  _scrollDebounceTimer?.cancel();
  _messageStreamSubscription?.cancel(); // Cancel stream subscription
  super.dispose();
}
void _setupMessageStream() {
  _messageStreamSubscription = _dbHelper.messageStream.listen((groupMessages) {
    if (!mounted) return;
    final messages = groupMessages[widget.groupId];
    if (messages == null || messages.isEmpty) return;

    print('🔵 [ChatScreen] Received ${messages.length} messages from stream for group: ${widget.groupId}');
    setState(() {
      _messages = messages.map((message) {
        final isMe = message['sender_id'].toString() == _currentUserId;
        return {
          ...message,
          'isMe': isMe ? 1 : 0,
          'status': message['status'] ?? (isMe ? 'sent' : 'unread'),
          'message': message['media_path'] ?? message['message'] ?? '',
          'type': message['type'] ?? 'text',
          'sender_name': message['sender_name'] ?? 'Unknown',
          'sender_avatar': message['sender_avatar'] ?? '',
          'sender_role': message['sender_role'] ?? 'member',
        };
      }).toList();

      _messages = MessageSort.sortMessagesByDate(_messages);
      _groupedMessages = MessageSort.groupMessagesByDate(_messages);

      // Update unread messages
      _updateUnreadMessages();

      // Animate new messages
      final newMessageIndex = _messages.indexWhere((m) =>
          m['timestamp'] == messages.first['timestamp'] &&
          !_messages.any((existing) => existing['id'] == m['id']));
      if (newMessageIndex != -1 && messages.first['sender_id'] != _currentUserId) {
        _unreadMessageIds.add(messages.first['id'].toString());
        _hasUnreadMessages = true;
        _showUnreadBadge = true;
        _listKey.currentState?.insertItem(
          newMessageIndex,
          duration: const Duration(milliseconds: 300),
        );
      }

      // Update last timestamp
      if (_messages.isNotEmpty) {
        _lastMessageTimestamp = _messages.first['timestamp'];
      }
    });

    // Auto-scroll if at bottom
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }

    // Update notification badge
    NotificationService().updateBadgeCountFromDatabase();
  }, onError: (e) {
    print('🔴 [ChatScreen] Stream error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error receiving messages: $e')),
    );
  });
}
void _scrollToBottom() {
  if (_scrollController.hasClients) {
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}
void _scrollToFirstUnreadOrBottom() {
  if (_unreadMessageIds.isNotEmpty) {
    final unreadIndex = _messages.indexWhere((msg) => _unreadMessageIds.contains(msg['id'].toString()));
    if (unreadIndex != -1) {
      final scrollPosition = (_messages.length - unreadIndex - 1) * 80.0;
      _scrollController.animateTo(
        scrollPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _scrollToBottom();
    }
  } else {
    _scrollToBottom();
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

Future<void> _loadMessages({bool isInitialLoad = false}) async {
  print('🔵 [DEBUG] Loading messages...');
  setState(() => _isLoading = true);

  try {
    final messages = await _dbHelper.getMessages(
      groupId: widget.groupId,
    );
    print('🔵 [DEBUG] Retrieved ${messages.length} messages from database');
   
    final db = await _dbHelper.database;
    final userProfile = await db.query('profile', limit: 1);
    final currentUserId = userProfile.first['id'] as String?;
    
    final participants = await _dbHelper.getGroupMemberNames(widget.groupId!);
    
    if (!mounted) return;

    setState(() {
      _messages = messages.map((message) {
        final isMe = message['sender_id'].toString() == currentUserId;
        final sender = participants.firstWhere(
          (p) => p['name'] == message['sender_name'],
          orElse: () => {'name': 'Unknown', 'role': 'member'},
        );
        
        final status = message['status'] ?? (isMe ? 'sent' : 'unread');
        
        return {
          ...message,
          'isMe': isMe ? 1 : 0,
          'status': status,
          'message': message['media_path'] ?? message['message'] ?? message['content'] ?? '',
          'type': message['type'] ?? message['message_type'] ?? 'text',
          'reply_to_id': message['reply_to_id'],
          'reply_to_message': message['reply_to_message'],
          'isReply': message['reply_to_id'] != null,
          'sender_name': sender['name'],
          'sender_role': sender['role'],
        };
      }).toList();

      _messages = MessageSort.sortMessagesByDate(_messages);
      _groupedMessages = MessageSort.groupMessagesByDate(_messages);
    });

    // Update unread messages list
    _updateUnreadMessages();

    // Only scroll to bottom on first load
    if (isInitialLoad) {
      print('🔵 [DEBUG] First load, scrolling to first unread or bottom');
      _scrollToFirstUnreadOrBottom();
      _isInitialLoad = false;
    }

  } catch (e, stackTrace) {
    print('🔴 [DEBUG] Error loading messages: $e');
    print('🔴 [DEBUG] Stack trace: $stackTrace');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading messages. Please try again."),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _loadMessages(isInitialLoad: true),
          ),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
  void _onScroll() {
    if (_scrollController.hasClients) {
      final double currentPosition = _scrollController.position.pixels;
      final double maxScrollExtent = _scrollController.position.maxScrollExtent;
      
      // Detect scroll direction
      _isScrollingUp = currentPosition < _lastScrollPosition;
      
      // Detect if user is actively scrolling
      if (_lastScrollPosition != currentPosition) {
        _isUserScrolling = true;
        _shouldAutoScroll = false;
        
        // Reset the debounce timer
        _scrollDebounceTimer?.cancel();
        _scrollDebounceTimer = Timer(const Duration(seconds: 2), () {
          _isUserScrolling = false;
        });
      }
      
      _lastScrollPosition = currentPosition;

      // Calculate the approximate number of messages below the current view
      final double viewportHeight = _scrollController.position.viewportDimension;
      final double remainingScrollDistance = maxScrollExtent - currentPosition;
      final int messagesBelow = (remainingScrollDistance / 80).ceil();

      // Check if the user is at the bottom (within 10px tolerance)
      final bool isAtBottom = currentPosition >= maxScrollExtent - 10;

      setState(() {
        _showScrollToBottomButton = messagesBelow >= 10 && !isAtBottom;
        _updateFloatingDateHeader();
      });

      // Load more messages if at the top and there are more to load
      if (currentPosition == maxScrollExtent && !_isLoading && _hasMoreMessages) {
        _loadMessages();
      }
    }
    _markVisibleMessagesAsRead();
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

  void _scrollToMessage(String messageId) {
    print('🔵 [ChatScreen] Scrolling to message: $messageId');
    // Find the message in the flattened messages list
    final index = _messages.indexWhere((msg) => msg['id'].toString() == messageId);
    if (index != -1) {
      print('🔵 [ChatScreen] Found message at index: $index');
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

      // Add a highlight effect to the message
      setState(() {
        // Remove any existing highlight
        for (var msg in _messages) {
          msg['isHighlighted'] = false;
        }
        // Add highlight to the target message
        _messages[index]['isHighlighted'] = true;
      });

      // Scroll to the message
      _scrollController.animateTo(
        finalPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      // Remove the highlight after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _messages[index]['isHighlighted'] = false;
          });
        }
      });
    } else {
      print('🔵 [ChatScreen] Message not found: $messageId');
    }
  }

  void _setReplyMessage(Map<String, dynamic> message) {
  
    setState(() {
      _replyingToMessage = {
        'id': message['id'],
        'message': message['message'], // Keep original message content
        'sender_id': message['sender_id'],
        'type': message['type'] ?? 'text',
        'local_path': message['local_path'],
        'attachment_url': message['attachment_url'],
      };
    });
    print('🔵 [ChatScreen] Reply message set: $_replyingToMessage');
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

  Future<void> _getToken() async {
    try {
      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isNotEmpty) {
        setState(() {
          _token = userProfile.first['token'] as String?;
        });
      }
    } catch (e) {
      print('Error getting token: $e');
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
                                      style: TextStyle(fontSize: 15),
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
    print('🔵 [DEBUG] Initializing WebSocket connection');
    
    // Set up message handler
    _wsService.onMessageReceived = (data) {
      if (!mounted) {
        print('🔴 [DEBUG] Widget not mounted, ignoring message');
        return;
      }
      
      print('🔵 [DEBUG] Received WebSocket message: ${data['type']}');
      
      try {
        if (data['type'] == 'initial_messages') {
          _handleInitialMessages(data['messages']);
        } else if (data['type'] == 'message' || data['type'] == 'new_message') {
          print('🔵 [DEBUG] Handling new message from WebSocket');
          _handleNewMessage(data);
        } else if (data['type'] == 'update_message_status') {
          _handleMessageStatusUpdate(data);
        } else if (data['type'] == 'message_id_update') {
          _handleMessageIdUpdate(data);
        } else if (data['type'] == 'typing') {
          _handleTypingStatus(data['data']);
        }
      } catch (e, stackTrace) {
        print('🔴 [DEBUG] Error handling WebSocket message: $e');
        print('🔴 [DEBUG] Stack trace: $stackTrace');
      }
    };
    
    // Initialize WebSocket connection
    if (widget.groupId != null) {
      print('🔵 [DEBUG] Connecting to group: ${widget.groupId}');
      try {
        _wsService.initialize(widget.groupId.toString());
        print('🔵 [DEBUG] WebSocket initialization completed');
      } catch (e, stackTrace) {
        print('🔴 [DEBUG] Error initializing WebSocket: $e');
        print('🔴 [DEBUG] Stack trace: $stackTrace');
      }
    } else {
      print('🔴 [DEBUG] No group ID available for WebSocket connection');
    }
  }

  void _handleInitialMessages(List<dynamic> messages) {
    if (!mounted) return; // Don't process if widget is disposed
    print('🔵 [ChatScreen] Handling initial messages: ${messages.length} messages');
    setState(() {
      _messages = messages.map((message) {
        final isMe = message['sender_id'].toString() == _currentUserId;
        return {
          ...message,
          'isMe': isMe ? 1 : 0,
          'status': isMe ? (message['status'] ?? 'sent') : 'received',
          'message': message['content'] ?? '',
          'type': message['attachment_type'] ?? 'text',
        };
      }).map((m) => Map<String, dynamic>.from(m)).toList();
      _messages = MessageSort.sortMessagesByDate(_messages);
      _groupedMessages = MessageSort.groupMessagesByDate(_messages);
    });
  }

  void _handleMessageIdUpdate(Map<String, dynamic> data) {
    if (!mounted) return;
    
    final oldId = data['old_id'].toString();
    final newId = data['new_id'].toString();
    final groupId = data['group_id'].toString();
    final status = data['status'];

   

    if (groupId != widget.groupId.toString()) {
      print('🔵 [DEBUG] Group ID mismatch, skipping update');
      return;
    }

    setState(() {
      // First try to find by temp_id
      final index = _messages.indexWhere((msg) =>
          msg['temp_id']?.toString() == oldId || msg['id'].toString() == oldId);

      print('🔵 [DEBUG] Found message at index: $index');
      if (index != -1) {
    

        // Update the existing message instead of creating a new one
        _messages[index]['id'] = newId;
        _messages[index]['temp_id'] = null; // Clear temp_id to prevent duplicates
        if (status != null) {
          _messages[index]['status'] = status;
        }


        _groupedMessages = MessageSort.groupMessagesByDate(_messages);
      } else {
        print('🔵 [DEBUG] No matching message found for update');
      }
    });
  }

  void _handleMessageStatusUpdate(Map<String, dynamic> data) {
    if (!mounted) return;
    
    final messageId = data['message_id']?.toString();
    final status = data['status'];
    final groupId = data['group_id']?.toString();

    print('🔵 [DEBUG] Message Status Update:');
    print('🔵 [DEBUG] Message ID: $messageId');
    print('🔵 [DEBUG] New Status: $status');
    print('🔵 [DEBUG] Group ID: $groupId');
    print('🔵 [DEBUG] Current messages count: ${_messages.length}');

    if (groupId != null && groupId != widget.groupId.toString()) {
      print('🔵 [DEBUG] Group ID mismatch, skipping update');
      return;
    }

    setState(() {
      final index = _messages.indexWhere((msg) =>
          msg['id']?.toString() == messageId ||
          msg['temp_id']?.toString() == messageId);

      print('🔵 [DEBUG] Found message at index: $index');
      if (index != -1) {
        print('🔵 [DEBUG] Current message state:');
        print('🔵 [DEBUG] ID: ${_messages[index]['id']}');
        print('🔵 [DEBUG] Temp ID: ${_messages[index]['temp_id']}');
        print('🔵 [DEBUG] Current Status: ${_messages[index]['status']}');

        _messages[index]['status'] = status;
        _groupedMessages = MessageSort.groupMessagesByDate(_messages);
      } else {
        print('🔵 [DEBUG] No matching message found for status update');
      }
    });

    // Update badge count if the message status indicates it was read
    if (status == 'read' && groupId != null && groupId == widget.groupId.toString()) {
      print('🔵 [DEBUG] Updating badge count for read message');
      NotificationService().updateBadgeCountFromDatabase();
    }
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
    if (_controller.text.trim().isEmpty || _currentUserId == null) {
      return;
    }

    try {
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      
      print('🔵 [DEBUG] Sending new message:');
      print('🔵 [DEBUG] Temp ID: $tempId');
      print('🔵 [DEBUG] Content: ${_controller.text.trim()}');

      // Create the WebSocket message with the exact structure the server expects
      final Map<String, dynamic> wsMessage = {
        'type': 'send_message',
        'content': _controller.text.trim(),
        'sender_id': _currentUserId,
        'room_id': widget.groupId.toString(),
        'temp_id': tempId,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'sending',
        'message_type': 'text',
        'attachment_type': null,
        'attachment_url': null,
        'username': null,
        'data': {
          'sender_id': _currentUserId,
          'is_typing': false
        }
      };

      // Add reply information if available
      if (_replyingToMessage != null) {
        wsMessage['reply_to_id'] = _replyingToMessage!['id'];
        wsMessage['reply_to_message'] = _replyingToMessage!['message']; // Keep original message
        wsMessage['reply_to_type'] = _replyingToMessage!['type'] ?? 'text';
        
        // Add additional reply information for media messages
        if (_replyingToMessage!['type'] == 'image') {
          wsMessage['reply_to_media_type'] = 'image';
          wsMessage['reply_to_media_url'] = _replyingToMessage!['attachment_url'];
          wsMessage['reply_to_media_path'] = _replyingToMessage!['local_path'];
        }
      }

      // Create the database message object
      final Map<String, dynamic> dbMessage = {
        'id': tempId,
        'temp_id': tempId,
        'group_id': widget.groupId,
        'sender_id': _currentUserId,
        'message': _controller.text.trim(),
        'type': 'text',
        'timestamp': wsMessage['timestamp'],
        'status': 'sending',
        'isMe': 1,
        'edited': false,
        'attachment_type': null,
        'attachment_url': null,
        'username': null
      };

      // Add reply information to database message
      if (_replyingToMessage != null) {
        dbMessage['reply_to_id'] = _replyingToMessage!['id'];
        dbMessage['reply_to_message'] = _replyingToMessage!['message']; // Keep original message
        dbMessage['reply_to_type'] = _replyingToMessage!['type'] ?? 'text';
        
        // Add additional reply information for media messages
        if (_replyingToMessage!['type'] == 'image') {
          dbMessage['reply_to_media_type'] = 'image';
          dbMessage['reply_to_media_url'] = _replyingToMessage!['attachment_url'];
          dbMessage['reply_to_media_path'] = _replyingToMessage!['local_path'];
        }
      }

    
      await _dbHelper.insertMessage(dbMessage);
      print('🔵 [DEBUG] Message inserted into database');
     
      setState(() {
        _messages.add(dbMessage);
        _groupedMessages = MessageSort.groupMessagesByDate(_messages);
        _replyingToMessage = null;
      });
    
      try {
        print('🔵 [DEBUG] Sending message through WebSocket');
        await _wsService.sendMessage(wsMessage);
        print('🔵 [DEBUG] Message sent successfully through WebSocket');
      
      } catch (e) {
        print('🔴 [DEBUG] Error in WebSocket send: $e');
        print('🔴 [DEBUG] Stack trace: ${StackTrace.current}');
        
        setState(() {
          final index = _messages.indexWhere((msg) => msg['temp_id'] == tempId);
          if (index != -1) {
            print('🔵 [DEBUG] Updating message status to failed');
            _messages[index]['status'] = 'failed';
            _groupedMessages = MessageSort.groupMessagesByDate(_messages);
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send message: $e")),
        );
        return;
      }

      // After sending message, force scroll to bottom
      _shouldAutoScroll = true;
      _scrollToBottom();
      
      _controller.clear();
      widget.onMessageSent?.call();
      
    } catch (e) {
      print('🔴 [DEBUG] Error in _sendMessage: $e');
      print('🔴 [DEBUG] Stack trace: ${StackTrace.current}');
      
      setState(() {
        _groupedMessages = MessageSort.groupMessagesByDate(_messages);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send message: $e")),
      );
      return;
    }
  }

  Future<void> _sendImageMessage(String imagePath) async {
    try {
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Create a copy in the app's documents directory
      final extDir = await getExternalStorageDirectory();
      final mediaDir = Directory('${extDir!.path}/Pictures/Cyanase');
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }

      final localPath = '${mediaDir.path}/$fileName';
      await File(imagePath).copy(localPath);

      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      // Insert into media table
      final mediaId = await _dbHelper.insertImageFile(localPath, tempId);

      final groupId = widget.groupId!;

      // Create message object
      final message = {
        'id': tempId,
        'temp_id': tempId,
        'group_id': groupId,
        'sender_id': _currentUserId,
        'message': localPath, // Store local path as message content
        'type': 'image',
        'media_id': mediaId,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'sending',
        'isMe': 1,
        'reply_to_id': _replyingToMessage?['id'],
        'reply_to_message': _replyingToMessage?['message'],
        'local_path': localPath, // Also store as local_path
      };

      // Store in database
      await _dbHelper.insertMessage(message);

      // Update UI immediately with temp message
      setState(() {
        _messages.add(message);
        _messages = MessageSort.sortMessagesByDate(_messages);
        _groupedMessages = MessageSort.groupMessagesByDate(_messages);
      });

      final wsMessage = {
        'type': 'send_message',
        'content': "image_message", // Send local path as content
        'sender_id': _currentUserId,
        'group_id': groupId,
        'room_id': groupId.toString(),
        'message_type': 'image',
        'temp_id': tempId,
        'file_data': base64Image,
        'file_name': fileName,
        'attachment_type': 'image',
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'sending'
      };
     
      await _wsService.sendMessage(wsMessage);

      _replyingToMessage = null;
      _scrollToBottomIfAtBottom();
      widget.onMessageSent?.call();
  
    } catch (e) {
       print("Failed to send image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send image: $e")),
      );
    }
  }

  Future<void> _sendAudioMessage(String path) async {
    try {
      

      if (_currentUserId == null) {

        return;
      }

      

      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      

      // Create a copy in the app's documents directory
     
      final extDir = await getExternalStorageDirectory();
      final mediaDir = Directory('${extDir!.path}/Pictures/Cyanase');
      if (!await mediaDir.exists()) {
   
        await mediaDir.create(recursive: true);
      }

      final localPath = '${mediaDir.path}/$fileName';
     
      await File(path).copy(localPath);
     ;

      // Read file as base64
    
      final bytes = await File(path).readAsBytes();
      final base64Audio = base64Encode(bytes);
   

      // Insert into media table

      final mediaId = await _dbHelper.insertAudioFile(localPath);
    

      // Store message in database
   
      final groupId = widget.groupId!;
    

      // Create message object
      final message = {
        'id': tempId,
        'temp_id': tempId,
        'group_id': groupId,
        'sender_id': _currentUserId,
        'message': localPath, // Store local path as message content
        'type': 'audio',
        'media_id': mediaId,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'sending',
        'isMe': 1,
        'reply_to_id': _replyingToMessage?['id'],
        'reply_to_message': _replyingToMessage?['message'],
        'local_path': localPath, // Also store as local_path
      };

      // Store in database
      await _dbHelper.insertMessage(message);
   

      // Update UI immediately
      setState(() {
        _messages.add(message);
        _messages = MessageSort.sortMessagesByDate(_messages);
        _groupedMessages = MessageSort.groupMessagesByDate(_messages);
      });

      final wsMessage = {
        'type': 'send_message',
        'content': 'Audio message',
        'sender_id': _currentUserId,
        'group_id': groupId,
        'room_id': groupId.toString(),
        'message_type': 'audio',
        'temp_id': tempId,
        'file_data': base64Audio,
        'file_name': fileName,
        'attachment_type': 'audio',
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'sending'
      };
     
      await _wsService.sendMessage(wsMessage);

      await _loadMessages();
      _replyingToMessage = null;
      _scrollToBottomIfAtBottom();
      widget.onMessageSent?.call();
     
    } catch (e) {
      
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

  void _handleTypingStatus(Map<String, dynamic> data) {
    setState(() {
      if (data['is_typing'] == true) {
        _typingUsers[data['user_id']] = data['username'] ?? 'Someone';
      } else {
        _typingUsers.remove(data['user_id']);
      }
    });
  }

void _handleNewMessage(Map<String, dynamic> data) async {
  if (!mounted) {
    print('🔴 [ChatScreen] Widget not mounted, ignoring message');
    return;
  }

  final messageData = data['message'] ?? data;
  final groupId = messageData['group_id']?.toString() ?? messageData['room_id']?.toString();

  if (groupId != widget.groupId.toString()) {
    print('🔵 [DEBUG] Ignoring message for different group: $groupId');
    return;
  }

  print('🔵 [DEBUG] Processing new message for current group');

  // Create new message object with proper type conversion
  final newMessage = {
    'id': messageData['id']?.toString(),
    'group_id': int.tryParse(groupId!) ?? widget.groupId,
    'sender_id': messageData['sender_id']?.toString(),
    'message': messageData['content'] ?? messageData['message'] ?? '',
    'isMe': messageData['sender_id']?.toString() == _currentUserId ? 1 : 0,
    'type': messageData['type'] ?? messageData['message_type'] ?? 'text',
    'status': messageData['sender_id']?.toString() == _currentUserId ? 'sent' : 'unread',
    'timestamp': messageData['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
    'reply_to_id': messageData['reply_to_id'] != null ? 
                  int.tryParse(messageData['reply_to_id'].toString()) : null,
    'reply_to_message': messageData['reply_to_message']?.toString(),
    'forwarded': messageData['forwarded'] is bool ? (messageData['forwarded'] ? 1 : 0) : 
                messageData['forwarded'] is int ? messageData['forwarded'] : 0,
    'edited': messageData['edited'] is bool ? (messageData['edited'] ? 1 : 0) : 
             messageData['edited'] is int ? messageData['edited'] : 0,
    'deleted': messageData['deleted'] is bool ? (messageData['deleted'] ? 1 : 0) : 
              messageData['deleted'] is int ? messageData['deleted'] : 0,
    'temp_id': messageData['temp_id']?.toString(),
    'media_path': messageData['media_path']?.toString(),
    'media_type': messageData['media_type']?.toString(),
    'sender_name': messageData['sender_name'] ?? 'Unknown',
    'sender_avatar': messageData['sender_avatar'] ?? '',
    'sender_role': messageData['sender_role'] ?? 'member',
  };

  print('🔵 [DEBUG] Checking for existing message: ${newMessage['id']}');

  try {
    // Check if message already exists in database
    final db = await _dbHelper.database;
    final existingMessage = await db.query(
      'messages',
      where: 'id = ? OR temp_id = ?',
      whereArgs: [newMessage['id'].toString(), newMessage['temp_id']?.toString() ?? ''],
    );

    if (existingMessage.isEmpty) {
      print('🔵 [DEBUG] Message is new, updating UI only');
      
      // Don't insert into database here - let WebSocket service handle that
      if (!mounted) return;
      
      setState(() {
        // Check if message with same temp_id already exists in UI
        final existingIndex = _messages.indexWhere((m) => 
          m['temp_id'] == newMessage['temp_id'] || m['id'] == newMessage['id']
        );

        if (existingIndex == -1) {
          // Add new message to the list
          _messages.add(newMessage);
          // Sort messages by date
          _messages = MessageSort.sortMessagesByDate(_messages);
          // Update grouped messages
          _groupedMessages = MessageSort.groupMessagesByDate(_messages);
          
          // Update unread messages
          if (newMessage['isMe'] == 0 && newMessage['status'] == 'unread') {
            _unreadMessageIds.add(newMessage['id'].toString());
            _hasUnreadMessages = true;
            _showUnreadBadge = true;
          }
        } else {
          // Update existing message instead of adding a new one
          _messages[existingIndex] = newMessage;
          _messages = MessageSort.sortMessagesByDate(_messages);
          _groupedMessages = MessageSort.groupMessagesByDate(_messages);
        }
      });

      // Auto-scroll if at bottom
      if (_scrollController.hasClients &&
          _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } else {
      print('🔵 [DEBUG] Message already exists in database, skipping UI update');
    }
  } catch (e) {
    print('🔴 [ChatScreen] Error handling new message: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to handle message: $e')),
    );
  }
}
void _markVisibleMessagesAsRead() {
  if (!_scrollController.hasClients) return;

  final viewportHeight = _scrollController.position.viewportDimension;
  final scrollOffset = _scrollController.offset;
  final itemHeight = 80.0;

  final firstVisibleIndex = (_messages.length - (scrollOffset / itemHeight).ceil() - 1).clamp(0, _messages.length - 1);
  final lastVisibleIndex = (_messages.length - ((scrollOffset + viewportHeight) / itemHeight).floor()).clamp(0, _messages.length - 1);

  // Create a batch of messages to mark as read
  final messagesToMark = <String>[];
  
  for (int i = lastVisibleIndex; i <= firstVisibleIndex; i++) {
    if (i < 0 || i >= _messages.length) continue;
    final message = _messages[i];
    // Convert isMe to boolean for comparison
    if (message['isMe'] == 0 && message['status'] == 'unread') {
      messagesToMark.add(message['id'].toString());
    }
  }

  // Mark messages as read in batch
  if (messagesToMark.isNotEmpty) {
    for (final messageId in messagesToMark) {
      _markMessageAsRead(messageId);
    }
  }
}
Future<void> _markMessageAsRead(String messageId) async {
  print('🔵 [ChatScreen] Marking message as read: $messageId');
  try {
    // Update database (stream will handle UI update)
    await _dbHelper.updateMessageStatus(messageId, 'read');

    // Notify WebSocket
    if (widget.groupId != null) {
      _wsService.sendMessage({
        'type': 'update_message_status',
        'group_id': widget.groupId!,
        'message_id': messageId,
        'status': 'read',
      });
    }

    NotificationService().updateBadgeCountFromDatabase();
  } catch (e) {
    print('🔴 [ChatScreen] Error marking message as read: $e');
  }
}

  void _scrollToUnreadMessages() {
    print('🔵 [ChatScreen] Scrolling to unread messages...');
    if (_unreadMessageIds.isEmpty) {
      print('🔵 [ChatScreen] No unread messages to scroll to');
      return;
    }

    final unreadIndex = _messages.indexWhere((msg) => 
      _unreadMessageIds.contains(msg['id'].toString())
    );

    if (unreadIndex != -1) {
      print('🔵 [ChatScreen] Found unread message at index: $unreadIndex');
      final scrollPosition = (_messages.length - unreadIndex - 1) * 100.0;
      
      _scrollController.animateTo(
        scrollPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      // Mark messages as read after scrolling
      Future.delayed(const Duration(milliseconds: 500), () {
        print('🔵 [ChatScreen] Marking messages as read after scroll');
        for (var i = unreadIndex; i < _messages.length; i++) {
          final messageId = _messages[i]['id'].toString();
          if (_unreadMessageIds.contains(messageId)) {
            print('🔵 [ChatScreen] Marking message as read: $messageId');
            _markMessageAsRead(messageId);
          }
        }
      });
    } else {
      print('🔵 [ChatScreen] Could not find unread message in messages list');
    }
  }

  void _onMessageVisible(String messageId) {
    print('🔵 [ChatScreen] Message became visible: $messageId');
    if (_unreadMessageIds.contains(messageId)) {
      print('🔵 [ChatScreen] Marking visible message as read: $messageId');
      _markMessageAsRead(messageId);
    }
  }

  void _startDbPolling() {
    // We don't need polling anymore since we're using WebSocket
    _dbPollingTimer?.cancel();
    _dbPollingTimer = null;
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
        onBackPressed: () async {
          if (widget.groupId != null) {
            await _markMessagesAsRead(widget.groupId.toString());
          }
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
              itemCount: _messages.length + 1,
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: Loader()),
                        )
                      : const SizedBox.shrink();
                }

                final message = _messages[index];
                final messageDate = DateFormat('dd MMMM yyyy').format(DateTime.parse(message['timestamp']));
                final isFirstUnread = _unreadMessageIds.contains(message['id']?.toString()) &&
                    _messages.indexWhere((m) => _unreadMessageIds.contains(m['id']?.toString())) == index;
                final showDateHeader = index == _messages.length - 1 ||
                    DateFormat('dd MMMM yyyy').format(DateTime.parse(_messages[index + 1]['timestamp'])) != messageDate;
                final isSameSender = index < _messages.length - 1 &&
                    _messages[index + 1]['isMe'] == message['isMe'] &&
                    _messages[index + 1]['type'] != 'notification';

                return Column(
                  children: [
                    if (showDateHeader)
                      Center(
                        key: ValueKey('date_$messageDate'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[800]!.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            messageDate,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    if (isFirstUnread && _hasUnreadMessages)
                      Container(
                        key: ValueKey('unread_divider_${_unreadMessageIds.length}'),
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(child: Divider(color: primaryTwo)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                'New Messages (${_unreadMessageIds.length})',
                                style: TextStyle(color: primaryTwo, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(child: Divider(color: primaryTwo)),
                          ],
                        ),
                      ),
                    GestureDetector(
                      key: ValueKey(message['id']?.toString() ?? message['timestamp']),
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity! > 0 && message['type'] != 'notification') {
                          _setReplyMessage(message);
                        }
                      },
                      child: MessageChat(
                        senderAvatar: message['sender_avatar'] ?? '',
                        senderName: message['sender_name'] ?? 'Unknown',
                        senderRole: message['sender_role'] ?? 'member',
                        isMe: message['isMe'] == 1,
                        message: message['message'],
                        time: message['timestamp'],
                        isSameSender: isSameSender,
                        replyToId: message['reply_to_id']?.toString(),
                        replyTo: message['reply_to_message'],
                        isAudio: message['type'] == 'audio',
                        isImage: message['type'] == 'image',
                        isNotification: message['type'] == 'notification',
                        onPlayAudio: _playAudio,
                        isPlaying: _isPlayingMap[message['id'].toString()] ?? false,
                        audioDuration: _audioDurationMap[message['id'].toString()] ?? Duration.zero,
                        audioPosition: _audioPositionMap[message['id'].toString()] ?? Duration.zero,
                        messageId: message['id'].toString(),
                        onReply: (messageId, messageText) {
                          _setReplyMessage(message);
                        },
                        onReplyTap: (messageId) {
                          _scrollToMessage(messageId);
                        },
                        messageStatus: message['status'] ?? 'sent',
                        messageContent: _buildMessageContent(message),
                        isHighlighted: message['isHighlighted'] ?? false,
                        isUnread: message['isMe'] == 0 && message['status'] == 'unread',
                      ),
                    ),
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
                onPressed: _manualScrollToBottom,
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
              onCancelReply: () {
                print('🔵 [ChatScreen] Cancelling reply');
                setState(() => _replyingToMessage = null);
              },
              audioFunctions: _audioFunctions,
              currentUserId: _currentUserId,
            ),
          ),
          // Modify the unread messages badge
          if (_hasUnreadMessages)
            Positioned(
              top: _calculateUnreadBadgePosition(),
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Only show separator when not scrolling up
                 
                  const SizedBox(height: 8),
                  // Unread badge
                  AnimatedOpacity(
                    opacity: _showUnreadBadge ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Center(
                      child: Container(
                        key: _unreadBadgeKey,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: _scrollToUnreadMessages,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    primaryTwo,
                                    primaryTwo.withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryTwo.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _unreadMessageIds.length == 1
                                        ? 'New message'
                                        : '${_unreadMessageIds.length} new messages',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_downward,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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

  Widget _buildMessageContent(Map<String, dynamic> message) {
    // Convert isMe to boolean for UI
    final isMe = message['isMe'] == 1;
    
    if (message['type'] == 'image' || message['type'] == 'audio') {
      // If we have a local path, show the file
      if (message['local_path'] != null ||
          message['message']?.startsWith('/') == true) {
        final path = message['local_path'] ?? message['message'];
        

        // Check if there's an upload in progress
        final uploadProgress = _uploadProgress[message['id'].toString()];
        if (uploadProgress != null && uploadProgress < 1.0) {
          return _buildProgressIndicator(uploadProgress, 'Uploading...');
        }

        return message['type'] == 'image'
            ? Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('ERROR loading image: $error');
                  return Container(
                    width: 200,
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.error_outline,
                          size: 50, color: Colors.red),
                    ),
                  );
                },
              )
            : AudioPlayerWidget(
                audioPath: path,
                isPlaying: _isPlayingMap[message['id'].toString()] ?? false,
                duration: _audioDurationMap[message['id'].toString()] ??
                    Duration.zero,
                position: _audioPositionMap[message['id'].toString()] ??
                    Duration.zero,
                onPlay: () => _playAudio(message['id'], path),
              );
      } else if (message['attachment_url'] != null) {
        // Check if there's a download in progress
        final downloadProgress = _downloadProgress[message['id'].toString()];
        if (downloadProgress != null && downloadProgress < 1.0) {
          return _buildProgressIndicator(downloadProgress, 'Downloading...');
        }

        // Show download button
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message['type'] == 'image')
              Container(
                width: 200,
                height: 200,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.image, size: 50, color: Colors.grey),
                ),
              )
            else
              Container(
                width: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.audio_file, size: 24, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Audio Message', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _handleNewMessage({
                ...message,
                'file_data': message['file_data'],
                'file_name': message['file_name'],
              }),
              icon: const Icon(Icons.download),
              label: const Text('Download'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTwo,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      }
    }

    // Default text message
    return Text(
      message['message'] ?? '',
      style: TextStyle(
        color: isMe ? Colors.white : Colors.black87,
        fontSize: 15,
        fontFamily: 'Roboto',
      ),
    );
  }

  Widget _buildProgressIndicator(double progress, String label) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[400],
            valueColor: AlwaysStoppedAnimation<Color>(primaryTwo),
          ),
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _markMessagesAsRead(String groupId) async {
    try {
      print('🔵 [ChatScreen] Marking messages as read for group: $groupId');
      final db = await _dbHelper.database;
      
      // Update all unread messages for this group
      final result = await db.update(
        'messages',
        {'status': 'read'},
        where: 'group_id = ? AND isMe = 0 AND status = ?',
        whereArgs: [groupId, 'unread'],
      );
      print('🔵 [ChatScreen] Updated $result messages to read status');
      
      // Update UI immediately
      setState(() {
        _unreadMessageIds.clear();
        _hasUnreadMessages = false;
        _showUnreadBadge = false;
        
        // Update message status in the messages list
        for (var message in _messages) {
          if (message['group_id'].toString() == groupId && message['isMe'] == 0) {
            message['status'] = 'read';
          }
        }
        _groupedMessages = MessageSort.groupMessagesByDate(_messages);
      });
      
      // Notify WebSocket service about the status update with numeric IDs
      final numericGroupId = int.tryParse(groupId);
      if (numericGroupId != null) {
        ChatWebSocketService.instance.onMessageReceived?.call({
          'type': 'update_message_status',
          'group_id': numericGroupId,
          'status': 'read',
          'message_id': 'all'
        });
      }
      
      // Update app icon badge count
      NotificationService().updateBadgeCountFromDatabase();

    } catch (e, stackTrace) {
      print('🔴 [ChatScreen] Error marking messages as read: $e');
      print('🔴 [ChatScreen] Stack trace: $stackTrace');
    }
  }

  // Add this new method for manual scroll to bottom
  void _manualScrollToBottom() {
    _shouldAutoScroll = true;
    _scrollToBottom();
  }

  // Modify _initializeUnreadMessages to properly reset state
Future<void> _initializeUnreadMessages() async {
  print('🔵 [ChatScreen] Initializing unread messages...');
  if (widget.groupId == null) return;
  try {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT id FROM messages WHERE group_id = ? AND isMe = 0 AND status = ? ORDER BY timestamp DESC',
      [widget.groupId, 'unread'],
    );
    setState(() {
      _unreadMessageIds = result.map((row) => row['id'].toString()).toList();
      _hasUnreadMessages = _unreadMessageIds.isNotEmpty;
      _showUnreadBadge = _hasUnreadMessages;
    });
    print('🔵 [ChatScreen] Found ${_unreadMessageIds.length} unread messages');
  } catch (e) {
    print('🔴 [ChatScreen] Error initializing unread messages: $e');
  }
}

  // Modify _updateUnreadMessages to be more aggressive
void _updateUnreadMessages() {
  _unreadMessageIds = _messages
      .asMap()
      .entries
      .where((entry) {
        final message = entry.value;
        return message['isMe'] == 0 &&
            message['status'] == 'unread' &&
            message['id'] != null;
      })
      .map((entry) => entry.value['id'].toString())
      .toList();
  _hasUnreadMessages = _unreadMessageIds.isNotEmpty;
  _showUnreadBadge = _hasUnreadMessages;
  print('🔵 [ChatScreen] Found ${_unreadMessageIds.length} unread messages');
}

  // Add this new method to calculate unread badge position
  double _calculateUnreadBadgePosition() {
    if (_unreadMessageIds.isEmpty) return 80.0; // Default top position
    
    // Find the first unread message
    final firstUnreadIndex = _messages.indexWhere((msg) => 
      _unreadMessageIds.contains(msg['id'].toString())
    );
    
    if (firstUnreadIndex == -1) return 80.0;
    
    // Calculate position based on message index
    // Each message is approximately 80 pixels tall
    final messageHeight = 80.0;
    final position = 80.0 + (firstUnreadIndex * messageHeight);
    
    // Ensure the badge is visible within the viewport
    final maxPosition = MediaQuery.of(context).size.height - 200;
    return position.clamp(80.0, maxPosition);
  }
}