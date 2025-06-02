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
  bool _isFirstLoad = true;

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
    _initializeUnreadMessages();
  }

  @override
  void dispose() {
    print('🔵 [ChatScreen] Disposing chat screen');
    _wsService.onMessageReceived = null; // Clear the message handler
    _scrollController.dispose();
    _controller.dispose();
    _recordingTimer?.cancel();
    _audioFunctions.dispose();
    _typingTimer?.cancel();
    _dbPollingTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _unreadBadgeTimer?.cancel();
    _scrollDebounceTimer?.cancel();
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
    print('🔵 [ChatScreen] Loading messages...');
    setState(() => _isLoading = true);

    try {
      final messages = await _dbHelper.getMessages(
        groupId: widget.groupId,
      );
      print('my messages are here $messages');
     

      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      final currentUserId = userProfile.first['id'] as String?;
      

      final participants = await _dbHelper.getGroupMemberNames(widget.groupId!);
      

      setState(() {
        _messages = messages.map((message) {
          final isMe = message['sender_id'].toString() == currentUserId;
          final sender = participants.firstWhere(
            (p) => p['name'] == message['sender_name'],
            orElse: () => {'name': 'Unknown', 'role': 'member'},
          );
          
          // Keep messages unread if they're not from the current user
          final status = isMe ? (message['status'] ?? 'sent') : 'unread';
          print('🔵 [ChatScreen] Message ${message['id']} status: $status (isMe: $isMe)');
          
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
      if (_isInitialLoad) {
        print('🔵 [ChatScreen] First load, scrolling to bottom');
        _scrollToBottom();
        _isInitialLoad = false;
      }

    } catch (e) {
      print('🔴 [ChatScreen] Error loading messages: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading messages: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
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
    print('🔵 [ChatScreen] Initializing WebSocket connection');
    
    // Set up message handler
    _wsService.onMessageReceived = (data) {
      if (!mounted) return; // Don't process messages if widget is disposed
      
      if (data['type'] == 'initial_messages') {
        _handleInitialMessages(data['messages']);
      } else if (data['type'] == 'message' || data['type'] == 'new_message') {
        print('🔵 [ChatScreen] Handling new message from WebSocket');
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
    
    final messageId = data['message_id'].toString();
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
          msg['id'].toString() == messageId ||
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

      print('🔵 [DEBUG] Database message structure:');
      print('🔵 [DEBUG] ${json.encode(dbMessage)}');

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
     
      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${appDir.path}/media');
      if (!await mediaDir.exists()) {
       
        await mediaDir.create(recursive: true);
      }

      final localPath = '${mediaDir.path}/$fileName';
     
      await File(imagePath).copy(localPath);

      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      // Insert into media table
      final mediaId = await _dbHelper.insertImageFile(localPath);

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

      // Update UI immediately
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
        'conversation_id': groupId.toString(),
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
     
      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${appDir.path}/media');
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
        'conversation_id': groupId.toString(),
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

  void _handleNewMessage(Map<String, dynamic> data) {
    if (!mounted) return;
    try {
      final messageData = data['message'] ?? data;
      final groupId = messageData['room_id']?.toString();
      print('🔵 [ChatScreen] Message group ID: $groupId, Current group ID: ${widget.groupId}');

      if (groupId == widget.groupId.toString()) {
        // Check if message already exists by either ID or temp_id
        final messageExists = _messages.any((m) =>
            m['id']?.toString() == messageData['id'].toString() ||
            m['temp_id']?.toString() == messageData['id'].toString() ||
            m['id']?.toString() == messageData['temp_id']?.toString() ||
            m['temp_id']?.toString() == messageData['temp_id']?.toString()
        );

        if (!messageExists) {
          print('🔵 [ChatScreen] Processing new message: ${messageData['id']}');
          _dbHelper.getGroupMemberNames(widget.groupId!).then((participants) {
            final sender = participants.firstWhere(
              (p) => p['name'] == messageData['sender_name'],
              orElse: () => {'name': 'Unknown', 'role': 'member'},
            );
          
            final isMe = messageData['sender_id'].toString() == _currentUserId;
            // Always set status to unread for new messages from others
            final status = isMe ? 'sent' : 'unread';
            
            final dbMessage = {
              'id': messageData['id']?.toString() ?? messageData['temp_id'],
              'temp_id': messageData['temp_id'],
              'group_id': widget.groupId,
              'sender_id': messageData['sender_id'],
              'sender_name': sender['name'],
              'sender_role': sender['role'],
              'message': messageData['content'] ?? messageData['message'] ?? '',
              'type': messageData['attachment_type'] ?? 'text',
              'timestamp': messageData['timestamp'],
              'status': status,
              'isMe': isMe ? 1 : 0,
              'attachment_url': messageData['attachment_url'],
              'attachment_type': messageData['attachment_type'],
            };

            if (messageData['reply_to_id'] != null) {
              dbMessage['reply_to_id'] = messageData['reply_to_id'];
              dbMessage['reply_to_message'] = messageData['reply_to_message'];
              dbMessage['reply_to_type'] = messageData['reply_to_type'] ?? 'text';
            }

            setState(() {
              _messages.insert(0, dbMessage);
              _messages = MessageSort.sortMessagesByDate(_messages);
              _groupedMessages = MessageSort.groupMessagesByDate(_messages);
              
              if (!isMe) {
                print('🔵 [ChatScreen] Adding to unread messages: ${dbMessage['id']}');
                _unreadMessageIds.add(dbMessage['id']);
                _hasUnreadMessages = true;
                _showUnreadBadge = true;
                
                // Update notification badge count
                NotificationService().updateBadgeCountFromDatabase();
              }
            });

            // Don't auto-scroll for new messages
            if (_isInitialLoad) {
              print('🔵 [ChatScreen] First load, scrolling to bottom');
              _scrollToBottom();
            }

            // Keep badge visible longer
            _unreadBadgeTimer?.cancel();
            _unreadBadgeTimer = Timer(const Duration(seconds: 10), () {
              if (mounted) {
                print('🔵 [ChatScreen] Hiding unread badge');
                setState(() {
                  _showUnreadBadge = false;
                });
              }
            });
          });
        } else {
          print('🔵 [ChatScreen] Message already exists: ${messageData['id']}');
        }
      }
    } catch (e) {
      print('🔴 [ChatScreen] Error in _handleNewMessage: $e');
    }
  }

  void _markMessageAsRead(String messageId) async {
    print('🔵 [ChatScreen] Marking message as read: $messageId');
    try {
      await _dbHelper.updateMessageStatus(messageId, 'read');
      print('🔵 [ChatScreen] Successfully marked message as read in DB');
      
      setState(() {
        _unreadMessageIds.remove(messageId);
        _hasUnreadMessages = _unreadMessageIds.isNotEmpty;
        if (!_hasUnreadMessages) {
          _showUnreadBadge = false;
        }
        print('🔵 [ChatScreen] Updated unread count: ${_unreadMessageIds.length}');
      });
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
          // Mark messages as read before navigating back
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
                            print('🔵 [ChatScreen] Setting reply from gesture:');
                            print('🔵 [ChatScreen] Message: $message');
                            _setReplyMessage(message);
                          }
                        },
                        child: MessageChat(
                          senderAvatar: '', // Update with actual avatar logic
                          senderName: message["sender_name"] ?? 'Unknown',
                          senderRole: message["sender_role"] ?? 'member',
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
                        
                            final message = _messages.firstWhere(
                              (m) => m['id'].toString() == messageId,
                              orElse: () => <String, dynamic>{},
                            );
                            
                            if (message.isNotEmpty) {
                              _setReplyMessage(message);
                            } else {
                              print('🔵 [ChatScreen] Message not found for reply: $messageId');
                            }
                          },
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
                  if (!_isScrollingUp)
                    Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryTwo.withOpacity(0.0),
                            primaryTwo.withOpacity(0.5),
                            primaryTwo.withOpacity(0.0),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
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
      
      // Notify WebSocket service about the status update
      ChatWebSocketService.instance.onMessageReceived?.call({
        'type': 'update_message_status',
        'group_id': groupId,
        'status': 'read',
        'message_id': 'all'
      });
      
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
      
      // Get unread messages for this group
      final result = await db.rawQuery('''
        SELECT id, message, timestamp
        FROM messages 
        WHERE group_id = ? AND isMe = 0 AND status = 'unread'
        ORDER BY timestamp DESC
      ''', [widget.groupId]);
      
      print('🔵 [ChatScreen] Found ${result.length} unread messages in DB');
      
      // Update local state
      setState(() {
        _unreadMessageIds = result.map((row) => row['id'].toString()).toList();
        _hasUnreadMessages = _unreadMessageIds.isNotEmpty;
        _showUnreadBadge = _hasUnreadMessages;
      });
      
      // Mark messages as read in the database
      if (_unreadMessageIds.isNotEmpty) {
        await db.rawUpdate('''
          UPDATE messages 
          SET status = 'read' 
          WHERE group_id = ? AND isMe = 0 AND status = 'unread'
        ''', [widget.groupId]);
        
        // Update notification badge count
        NotificationService().updateBadgeCountFromDatabase();
        
        // Notify WebSocket service about the status update
        ChatWebSocketService.instance.onMessageReceived?.call({
          'type': 'update_message_status',
          'group_id': widget.groupId,
          'status': 'read',
          'message_id': 'all',
        });
      }
      
      print('🔵 [ChatScreen] Initialized unread messages: ${_unreadMessageIds.length}');
    } catch (e) {
      print('🔴 [ChatScreen] Error initializing unread messages: $e');
    }
  }

  // Modify _updateUnreadMessages to be more aggressive
  void _updateUnreadMessages() {
    print('🔵 [ChatScreen] Updating unread messages...');
    final unreadMessages = _messages
        .where((msg) => msg['isMe'] == 0 && msg['status'] == 'unread')
        .toList();
    
    print('🔵 [ChatScreen] Found ${unreadMessages.length} unread messages');
    for (var msg in unreadMessages) {
      print('🔵 [ChatScreen] Unread message: ${msg['id']} - ${msg['message']}');
    }

    setState(() {
      _unreadMessageIds = unreadMessages.map((msg) => msg['id'].toString()).toList();
      _hasUnreadMessages = _unreadMessageIds.isNotEmpty;
      _showUnreadBadge = _hasUnreadMessages;
      print('🔵 [ChatScreen] Updated unread count: ${_unreadMessageIds.length}');
    });
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