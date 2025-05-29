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
  String? _lastMessageTimestamp;

  // Add progress tracking maps
  Map<String, double> _uploadProgress = {};
  Map<String, double> _downloadProgress = {};

  @override
  void initState() {
    super.initState();
    _loadGroupMembers();
    _loadMessages();
    _scrollController.addListener(_onScroll);
    _initializeWebSocket();
    _getCurrentUserId();
    _getToken();
    if (widget.allowSubscription && !widget.hasUserPaid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSubscriptionReminder(context);
      });
    }
    _controller.addListener(_onTextChanged);
    _startDbPolling();
  }

  @override
  void dispose() {
    _wsService.dispose();
    _scrollController.dispose();
    _controller.dispose();
    _recordingTimer?.cancel();
    _audioFunctions.dispose();
    _typingTimer?.cancel();
    _dbPollingTimer?.cancel();
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
              'message': message['media_path'] ??
                  message['message'] ??
                  message['content'] ??
                  '',
              'type': message['type'] ?? message['message_type'] ?? 'text',
              'reply_to_id': message['reply_to_id'],
              'reply_to_message': message['reply_to_message'],
              'isReply': message['reply_to_id'] != null,
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
      print('DEBUG: Received WebSocket message: $data');
      
      if (data['type'] == 'initial_messages') {
        _handleInitialMessages(data['messages']);
      } else if (data['type'] == 'message') {
        print('DEBUG: Handling new message from WebSocket');
        _handleNewMessage(data);
      } else if (data['type'] == 'update_message_status') {
        _handleMessageStatusUpdate(data);
      } else if (data['type'] == 'message_id_update') {
        _handleMessageIdUpdate(data);
      } else if (data['type'] == 'typing') {
        _handleTypingStatus(data['data']);
      }
    };
    
    // Initialize WebSocket connection
    _wsService.initialize(widget.groupId.toString());
  }

  void _handleInitialMessages(List<dynamic> messages) {
    print('Handling initial messages: ${messages.length} messages');
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
    final oldId = data['old_id'].toString();
    final newId = data['new_id'].toString();
    final groupId = data['group_id'].toString();
    final status = data['status'];

    if (groupId != widget.groupId.toString()) return;

    setState(() {
      // First try to find by temp_id
      final index = _messages.indexWhere((msg) =>
          msg['temp_id']?.toString() == oldId || msg['id'].toString() == oldId);

      if (index != -1) {
        _messages[index]['id'] = newId;
        if (status != null) {
          _messages[index]['status'] = status;
        }
        _groupedMessages = MessageSort.groupMessagesByDate(_messages);
      }
    });
  }

  void _handleMessageStatusUpdate(Map<String, dynamic> data) {
    final messageId = data['message_id'].toString();
    final status = data['status'];
    final groupId = data['group_id']?.toString();

    if (groupId != null && groupId != widget.groupId.toString()) return;

    setState(() {
      final index = _messages.indexWhere((msg) =>
          msg['id'].toString() == messageId ||
          msg['temp_id']?.toString() == messageId);

      if (index != -1) {
        _messages[index]['status'] = status;
        _groupedMessages = MessageSort.groupMessagesByDate(_messages);
      }
    });
  }

  void _handleMessageStatus(Map<String, dynamic> status) {
    if (!mounted) {
      return;
    }

    final messageId = status['message_id'].toString();

    final messageIndex =
        _messages.indexWhere((msg) => msg['id'].toString() == messageId);

    if (messageIndex != -1) {
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

      // If message is now sent, remove it from the queue
      if (status['status'] == 'sent') {
        _wsService.removeFromQueue(messageId);
      }
    } else {}
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
    print('FUNCTION CALLED: _sendMessage');
    print('DEBUG 1: Starting _sendMessage......Oh yeah');
 
    
    if (_controller.text.trim().isEmpty || _currentUserId == null) {
      print('DEBUG 2: Message empty or no user ID, returning');
      return;
    }

    try {
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      print('DEBUG 3: Generated temp_id: $tempId');

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
        print('DEBUG 5: Adding reply information');
        wsMessage['reply_to_id'] = _replyingToMessage!['id'];
        wsMessage['reply_to_message'] = _replyingToMessage!['message'];
        wsMessage['reply_to_type'] = _replyingToMessage!['type'] ?? 'text';
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
        print('DEBUG 7: Adding reply information to database message');
        dbMessage['reply_to_id'] = _replyingToMessage!['id'];
        dbMessage['reply_to_message'] = _replyingToMessage!['message'];
        dbMessage['reply_to_type'] = _replyingToMessage!['type'] ?? 'text';
      }
      await _dbHelper.insertMessage(dbMessage);
     
      setState(() {
        _messages.add(dbMessage);
        _groupedMessages = MessageSort.groupMessagesByDate(_messages);
        _replyingToMessage = null;
      });
    

    
      try {
        await _wsService.sendMessage(wsMessage);
        print('DEBUG 12.3: WebSocket message sent, waiting for acknowledgment');
      } catch (e) {
        print('ERROR in WebSocket send: $e');
        print('ERROR stack trace: ${StackTrace.current}');
        
        setState(() {
          final index = _messages.indexWhere((msg) => msg['temp_id'] == tempId);
          if (index != -1) {
            _messages[index]['status'] = 'failed';
            _groupedMessages = MessageSort.groupMessagesByDate(_messages);
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send message: $e")),
        );
        return;
      }

      _controller.clear();
      _scrollToBottomIfAtBottom();
      widget.onMessageSent?.call();
      print('DEBUG 14: Message sending process completed successfully');
    } catch (e) {
      print('ERROR in WebSocket send: $e');
      print('ERROR stack trace: ${StackTrace.current}');
      
      // Update message status to failed in UI
      setState(() {
        
          _groupedMessages = MessageSort.groupMessagesByDate(_messages);
        
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send message: $e")),
      );
      return; // Exit the function on error
    }
  }

  Future<void> _sendImageMessage(String imagePath) async {
    try {
      print('DEBUG 1: Starting _sendImageMessage with path: $imagePath');
      print('DEBUG 1.1: widget.groupId = ${widget.groupId}');

      if (_currentUserId == null) {
        print('DEBUG 2: _currentUserId is null, aborting');
        return;
      }

      if (widget.groupId == null) {
        print('DEBUG 2.1: widget.groupId is null, aborting');
        return;
      }

      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      print('DEBUG 3: Generated tempId: $tempId and fileName: $fileName');

      // Create a copy in the app's documents directory
      print('DEBUG 4: Setting up local storage');
      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${appDir.path}/media');
      if (!await mediaDir.exists()) {
        print('DEBUG 5: Creating media directory');
        await mediaDir.create(recursive: true);
      }

      final localPath = '${mediaDir.path}/$fileName';
      print('DEBUG 6: Copying file to local path: $localPath');
      await File(imagePath).copy(localPath);
      print('DEBUG 7: File copied successfully to local storage');

      // Read file as base64
      print('DEBUG 8: Reading file as base64');
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);
      print('DEBUG 9: File converted to base64');

      // Insert into media table
      print('DEBUG 10: Inserting into media table');
      final mediaId = await _dbHelper.insertImageFile(localPath);
      print('DEBUG 11: Media ID from database: $mediaId');

      // Store message in database
      print('DEBUG 12: Storing message in database');
      final groupId = widget.groupId!;
      print('DEBUG 12.1: Using groupId: $groupId');

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
      print('DEBUG 13: Message stored in database');

      // Update UI immediately
      setState(() {
        _messages.add(message);
        _messages = MessageSort.sortMessagesByDate(_messages);
        _groupedMessages = MessageSort.groupMessagesByDate(_messages);
      });
      print('DEBUG 13.1: UI updated with new message');

      // Send through WebSocket
      print('DEBUG 14: Sending message through WebSocket');
      final wsMessage = {
        'type': 'send_message',
        'content': localPath, // Send local path as content
        'sender_id': _currentUserId,
        'group_id': groupId,
        'conversation_id': groupId.toString(),
        'message_type': 'image',
        'temp_id': tempId,
        'file_data': base64Image,
        'file_name': fileName,
        'attachment_type': 'image',
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'sending'
      };
      print(
          'DEBUG 14.1: WebSocket message prepared with group_id: ${wsMessage['group_id']}');
      print(
          'DEBUG 14.2: WebSocket message has file_data: ${wsMessage['file_data'] != null}');
      await _wsService.sendMessage(wsMessage);
      print('DEBUG 15: WebSocket message sent');

      _replyingToMessage = null;
      _scrollToBottomIfAtBottom();
      widget.onMessageSent?.call();
      print('DEBUG 17: Image message process completed successfully');
    } catch (e) {
      print('ERROR in _sendImageMessage: $e');
      print('ERROR stack trace: ${StackTrace.current}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send image: $e")),
      );
    }
  }

  Future<void> _sendAudioMessage(String path) async {
    try {
      print('DEBUG 1: Starting _sendAudioMessage with path: $path');

      if (_currentUserId == null) {
        print('DEBUG 2: _currentUserId is null, aborting');
        return;
      }

      if (widget.groupId == null) {
        print('DEBUG 2.1: widget.groupId is null, aborting');
        return;
      }

      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      print('DEBUG 3: Generated tempId: $tempId and fileName: $fileName');

      // Create a copy in the app's documents directory
      print('DEBUG 4: Setting up local storage');
      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${appDir.path}/media');
      if (!await mediaDir.exists()) {
        print('DEBUG 5: Creating media directory');
        await mediaDir.create(recursive: true);
      }

      final localPath = '${mediaDir.path}/$fileName';
      print('DEBUG 6: Copying file to local path: $localPath');
      await File(path).copy(localPath);
      print('DEBUG 7: File copied successfully to local storage');

      // Read file as base64
      print('DEBUG 8: Reading file as base64');
      final bytes = await File(path).readAsBytes();
      final base64Audio = base64Encode(bytes);
      print('DEBUG 9: File converted to base64');

      // Insert into media table
      print('DEBUG 10: Inserting into media table');
      final mediaId = await _dbHelper.insertAudioFile(localPath);
      print('DEBUG 11: Media ID from database: $mediaId');

      // Store message in database
      print('DEBUG 12: Storing message in database');
      final groupId = widget.groupId!;
      print('DEBUG 12.1: Using groupId: $groupId');

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
      print('DEBUG 13: Message stored in database');

      // Update UI immediately
      setState(() {
        _messages.add(message);
        _messages = MessageSort.sortMessagesByDate(_messages);
        _groupedMessages = MessageSort.groupMessagesByDate(_messages);
      });
      print('DEBUG 13.1: UI updated with new message');

      // Send through WebSocket
      print('DEBUG 14: Sending message through WebSocket');
      final wsMessage = {
        'type': 'send_message',
        'content': 'Audio message',
        'sender_id': _currentUserId,
        'group_id': groupId,
        'conversation_id': groupId.toString(),
        'message_type': 'audio',
        'temp_id': tempId,
        'file_data': base64Audio,
        'file_name': fileName,
        'attachment_type': 'audio',
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'sending'
      };
      print(
          'DEBUG 14.1: WebSocket message prepared with group_id: ${wsMessage['group_id']}');
      print(
          'DEBUG 14.2: WebSocket message has file_data: ${wsMessage['file_data'] != null}');
      await _wsService.sendMessage(wsMessage);
      print('DEBUG 15: WebSocket message sent');

      // Reload messages from database
      print('DEBUG 16: Reloading messages');
      await _loadMessages();
      _replyingToMessage = null;
      _scrollToBottomIfAtBottom();
      widget.onMessageSent?.call();
      print('DEBUG 17: Audio message process completed successfully');
    } catch (e) {
      print('ERROR in _sendAudioMessage: $e');
      print('ERROR stack trace: ${StackTrace.current}');
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

  void _handleNewMessage(Map<String, dynamic> message) {
    try {
      print('DEBUG: Starting _handleNewMessage');
      
      // Extract message data
      final messageData = message['message'] ?? message;
      print('DEBUG: Message data: $messageData');
      
      // Check if we're in the current chat
      if (messageData['room_id']?.toString() == widget.groupId.toString()) {
        print('DEBUG: Message is for current chat');
        
        // Check if message already exists in the UI
        final messageExists = _messages.any((m) => 
          m['id'].toString() == messageData['id'].toString() ||
          m['temp_id']?.toString() == messageData['id'].toString()
        );

        if (!messageExists) {
          print('DEBUG: Adding new message to UI');
          
          // Create message object for UI
          final dbMessage = {
            'id': messageData['id']?.toString() ?? message['temp_id'],
            'group_id': widget.groupId,
            'sender_id': messageData['sender_id'],
            'message': messageData['content'] ?? messageData['message'] ?? '',
            'type': messageData['attachment_type'] ?? 'text',
            'timestamp': messageData['timestamp'],
            'status': messageData['status'] ?? 'received',
            'isMe': 0,
            'attachment_url': messageData['attachment_url'],
            'attachment_type': messageData['attachment_type'],
          };

          // Add reply information if available
          if (message['reply_to_id'] != null) {
            dbMessage['reply_to_id'] = message['reply_to_id'];
            dbMessage['reply_to_message'] = message['reply_to_message'];
            dbMessage['reply_to_type'] = message['reply_to_type'] ?? 'text';
          }

          // Update UI immediately with the new message
          setState(() {
            _messages.insert(0, dbMessage);
            _groupedMessages = MessageSort.groupMessagesByDate(_messages);
          });

          // Scroll to bottom if we're already near the bottom
          if (_scrollController.hasClients) {
            final isNearBottom = _scrollController.position.pixels >=
                _scrollController.position.maxScrollExtent - 100;
            if (isNearBottom) {
              _scrollToBottom();
            }
          }

          // Mark message as read
          _dbHelper.updateMessageStatus(
            messageData['id'].toString(),
            'read'
          );
          
          print('DEBUG: Message added to UI successfully');
        } else {
          print('DEBUG: Message already exists in UI');
        }
      } else {
        print('DEBUG: Message is not for current chat');
      }
    } catch (e) {
      print('ERROR in _handleNewMessage: $e');
      print('ERROR stack trace: ${StackTrace.current}');
    }
  }

  void _startDbPolling() {
    // Poll database every 1 second for new messages
    _dbPollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;
      
      try {
        final db = await _dbHelper.database;
        final newMessages = await db.query(
          'messages',
          where: 'group_id = ? AND timestamp > ?',
          whereArgs: [_lastMessageTimestamp ?? '', _lastMessageTimestamp ?? ''],
          orderBy: 'timestamp DESC',
        );

        if (newMessages.isNotEmpty) {
          // Update last message timestamp
          _lastMessageTimestamp = newMessages.first['timestamp'] as String?;

          // Process new messages
          for (final message in newMessages) {
            // Check if message already exists in UI
            final messageExists = _messages.any((m) => 
              m['id'].toString() == message['id'].toString() ||
              m['temp_id']?.toString() == message['id'].toString()
            );

            if (!messageExists) {
              setState(() {
                _messages.insert(0, message);
                _groupedMessages = MessageSort.groupMessagesByDate(_messages);
              });

              // Mark message as read if it's not from current user
              if (message['isMe'] == 0) {
                _dbHelper.updateMessageStatus(
                  message['id'].toString(),
                  'read'
                );
              }

              // Scroll to bottom if near bottom
              if (_scrollController.hasClients) {
                final isNearBottom = _scrollController.position.pixels >=
                    _scrollController.position.maxScrollExtent - 100;
                if (isNearBottom) {
                  _scrollToBottom();
                }
              }
            }
          }
        }
      } catch (e) {
        print('Error polling database: $e');
      }
    });
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
            child: AnimatedList(
              key: _listKey,
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.only(top: 16, bottom: 80),
              initialItemCount: _groupedMessages.length + 1,
              itemBuilder: (context, index, animation) {
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

                return SlideTransition(
                  position: animation.drive(
                    Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).chain(CurveTween(curve: Curves.easeOut)),
                  ),
                  child: FadeTransition(
                    opacity: animation,
                    child: Column(
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
                                  "notification";
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
                              messageContent: _buildMessageContent(message),
                              isHighlighted: message["isHighlighted"] ?? false,
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
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
    print('DEBUG 1: Building message content for type: ${message['type']}');
    print('DEBUG 2: Message has media_id: ${message['media_id'] != null}');
    print('DEBUG 3: Message has local_path: ${message['local_path'] != null}');
    print('DEBUG 4: Message content: ${message['message']}');

    if (message['type'] == 'image' || message['type'] == 'audio') {
      // If we have a local path, show the file
      if (message['local_path'] != null ||
          message['message']?.startsWith('/') == true) {
        final path = message['local_path'] ?? message['message'];
        print('DEBUG 5: Showing local file from path: $path');

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
        print(
            'DEBUG 6: Showing download button for attachment_url: ${message['attachment_url']}');

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
        color: message['isMe'] == 1 ? Colors.white : Colors.black87,
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
}