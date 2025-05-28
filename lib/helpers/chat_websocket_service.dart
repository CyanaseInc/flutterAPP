import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cyanase/helpers/endpoints.dart';

class ChatWebSocketService {
  static final ChatWebSocketService instance = ChatWebSocketService._internal();
  ChatWebSocketService._internal() {
    _initConnectivity();
  }

  WebSocket? _webSocket;
  Function(Map<String, dynamic>)? onMessageReceived;
  Function(bool)? onConnectionStatusChanged;
  String? _groupId;
  bool _isConnected = false;
  List<Map<String, dynamic>> _messageQueue = [];
  Timer? _retryTimer;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String? _token;
  StreamSubscription? _connectivitySubscription;
  bool _isNetworkAvailable = false;

  bool get isConnected => _isConnected;

  void _initConnectivity() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final result = results.first;
      _isNetworkAvailable = result != ConnectivityResult.none;

      if (_isNetworkAvailable) {
        print('Network available, attempting to reconnect WebSocket');
        _reconnectAndProcessQueue();
      } else {
        print('Network unavailable, marking WebSocket as disconnected');
        _isConnected = false;
        onConnectionStatusChanged?.call(false);
      }
    });
  }

  Future<void> _reconnectAndProcessQueue() async {
    if (_groupId != null) {
      await initialize(_groupId!);
    }
  }

  Future<void> initialize(String groupId) async {
    _groupId = groupId;
    await _getTokenFromDatabase();
    if (_webSocket == null || _webSocket!.readyState != WebSocket.open) {
      final protocol = ApiEndpoints.server.startsWith('https') ? 'wss' : 'ws';
      final wsUrl =
          '$protocol://${ApiEndpoints.myIp}/ws/chat/$groupId/?token=$_token';

      print('DEBUG [ChatWebSocket] Attempting to connect to: $wsUrl');

      try {
        _webSocket = await WebSocket.connect(
          wsUrl,
          headers: {
            'Connection': 'Upgrade',
            'Upgrade': 'websocket',
            'Sec-WebSocket-Version': '13',
          },
        );
        print('DEBUG [ChatWebSocket] Connection established successfully');
        _isConnected = true;
        onConnectionStatusChanged?.call(true);
        _listenToMessages();

        // Process any queued messages
        await _processMessageQueue();
      } catch (e) {
        print('ChatWebSocket connection error: $e');
        _isConnected = false;
        onConnectionStatusChanged?.call(false);
        _startRetryTimer();
      }
    }
  }

  Future<void> _getTokenFromDatabase() async {
    try {
      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isNotEmpty) {
        _token = userProfile.first['token'] as String?;
      }
    } catch (e) {
      print('Error getting token from database: $e');
    }
  }

  void _startRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!_isConnected) {
        print('Attempting to reconnect ChatWebSocket...');
        await initialize(_groupId ?? '');
      } else if (_messageQueue.isNotEmpty) {
        print('ChatWebSocket connected, processing message queue...');
        await _processMessageQueue();
      }
    });
  }

  Future<void> _processMessageQueue() async {
    if (!_isConnected || _webSocket == null || !_isNetworkAvailable) {
      print('Cannot process queue: ChatWebSocket not connected or no network');
      return;
    }

    print('Processing message queue. Queue size: ${_messageQueue.length}');
    final messagesToProcess = List<Map<String, dynamic>>.from(_messageQueue);

    for (final message in messagesToProcess) {
      try {
        print('Processing queued message: ${message['id']}');
        await _sendMessageInternal(message);

        if (message['id'] != null) {
          await _dbHelper.updateMessageStatus(message['id'].toString(), 'sent');
          print('Updated message ${message['id']} status to sent');
        }

        _messageQueue.remove(message);
        print('Removed message ${message['id']} from queue');
      } catch (e) {
        print('Error processing queued message: $e');
        if (message['id'] != null) {
          await _dbHelper.updateMessageStatus(
              message['id'].toString(), 'failed');
          print('Updated message ${message['id']} status to failed');
        }
      }
    }
  }

  Future<void> _sendMessageInternal(Map<String, dynamic> message) async {
    if (!_isConnected || _webSocket == null) {
      throw Exception('ChatWebSocket is not connected');
    }
   print("were are sending, $message ");

    final messageToSend = {
      'type': 'send_message',
      'content': message['content'],
      'sender_id': message['sender_id'],
      'room_id': message['room_id'],
      'timestamp': message['timestamp'],
      'temp_id': message['temp_id'],
      'attachment_type': message['attachment_type'],
      'file_name': message['file_name'],
      'file_data': message['file_data'],
      'reply_to_id': message['reply_to_id'],
      'reply_to_message': message['reply_to_message'],
      'message_type': message['message_type'],
    };

    messageToSend.removeWhere((key, value) => value == null);
    print('🔵 [CHAT] Sending message to WebSocket with temp_id: ${message['temp_id']}');
    _webSocket?.add(json.encode(messageToSend));
  }

  void _listenToMessages() {
    _webSocket?.listen(
      (message) async {
        try {
          final data = json.decode(message);
          print('Received ChatWebSocket message: $data');

          switch (data['type']) {
            case 'initial_messages':
              print('Processing initial messages');
              if (data['messages'] != null) {
                onMessageReceived?.call({
                  'type': 'initial_messages',
                  'messages': data['messages']
                });
              }
              break;

            case 'new_message':
              await _handleReceivedMessage(data);
              break;

            case 'message':
              if (data['temp_id'] != null) {
                await _handleSentMessageConfirmation(data);
              } else {
                await _handleReceivedMessage(data);
              }
              break;

            case 'message_status':
              await _handleMessageStatusUpdate(data);
              break;

            case 'typing':
              onMessageReceived?.call(data);
              break;

            default:
              print('Unknown message type: ${data['type']}');
          }
        } catch (e) {
          print('Error processing ChatWebSocket message: $e');
        }
      },
      onError: (error) {
        print('ChatWebSocket error: $error');
        _isConnected = false;
        onConnectionStatusChanged?.call(false);
        _startRetryTimer();
      },
      onDone: () {
        print('ChatWebSocket connection closed');
        _isConnected = false;
        onConnectionStatusChanged?.call(false);
        _startRetryTimer();
      },
    );
  }

  Future<void> _handleSentMessageConfirmation(Map<String, dynamic> data) async {
    try {
        final tempId = data['temp_id'].toString();
        final newId = data['id'].toString();
        print('Message confirmation received - tempId: $tempId, newId: $newId');

        // Debug: Check if message exists before update
        final db = await _dbHelper.database;
        final beforeUpdate = await db.query(
            'messages',
            where: 'temp_id = ?',
            whereArgs: [tempId],
        );
        print('Message before update: $beforeUpdate');

        // // Update message ID
        // print('Attempting to update message ID from $tempId to $newId');
        // await _dbHelper.updateMessageId(tempId, newId);
        
        // Verify ID update
        final afterIdUpdate = await db.query(
            'messages',
            where: 'id = ?',
            whereArgs: [newId],
        );
        print('Message after ID update: $afterIdUpdate');

        // Update status
        print('Attempting to update message status to sent');
        await _dbHelper.updateMessageStatus(newId, 'sent');
        
        // Verify status update
        final afterStatusUpdate = await db.query(
            'messages',
            where: 'id = ?',
            whereArgs: [newId],
        );
        print('Message after status update: $afterStatusUpdate');

        // Notify UI of ID update
        onMessageReceived?.call({
            'type': 'message_id_update',
            'old_id': tempId,
            'new_id': newId,
            'status': 'sent',
            'group_id': data['room_id'],
        });
    } catch (e) {
        print('Error in _handleSentMessageConfirmation: $e');
        print('Error stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _handleReceivedMessage(Map<String, dynamic> data) async {
    try {
      // Extract message data from either format
      final messageData = data['message'] ?? data;
      print('Processing received message: $messageData');

      // Save message to database with 'unread' status
      await _dbHelper.insertMessage({
        'id': messageData['id'].toString(),
        'group_id': messageData['room_id'],
        'sender_id': messageData['sender_id'],
        'message': messageData['content'],
        'type': messageData['message_type'] ?? 'text',
        'timestamp': messageData['timestamp'],
        'status': 'unread',
        'isMe': 0,
        'username': messageData['username'],
        'sender_info': messageData['sender_info'],
        'is_edited': messageData['is_edited'] ?? false,
        'is_deleted': messageData['is_deleted'] ?? false,
        'is_forwarded': messageData['is_forwarded'] ?? false,
        'reply_to_id': messageData['reply_to_id'],
        'reply_to_message': messageData['reply_to_message'],
        'reply_to_type': messageData['reply_to_type']
      });

      // Notify UI of new message
      onMessageReceived?.call({
        'type': 'message',
        'message': messageData,
      });

      // Send delivered status
      await sendDeliveredStatus(messageData['id'].toString());
    } catch (e) {
      print('Error handling received message: $e');
    }
  }

  Future<void> _handleMessageStatusUpdate(Map<String, dynamic> data) async {
    try {
        final messageId = data['message_id']?.toString();
        final tempId = data['temp_id']?.toString();
        final status = data['status'];
        final groupId = data['group_id']?.toString();

        if (groupId != null && groupId != _groupId) return;
        if (messageId == null || tempId == null) return;

        final db = await _dbHelper.database;
        final beforeUpdate = await db.query(
            'messages',
            where: 'temp_id = ?',
            whereArgs: [tempId],
        );
        print('Message before status update: $beforeUpdate');
          final existingMessage = await db.query(
            'messages',
            where: 'id = ?',
            whereArgs: [messageId],
        );

        if (existingMessage.isEmpty) {
            // Only update ID if message doesn't exist with new ID
            await _dbHelper.updateMessageId(tempId, messageId);
        }// Update status in database
        print('Attempting to update message status to: $status');
        await _dbHelper.updateMessageStatus(messageId, status);
        
        // Verify status update
        final afterUpdate = await db.query(
            'messages',
            where: 'id = ?',
            whereArgs: [messageId],
        );
        print('Message after status update: $afterUpdate');

        // Notify UI of status update
        onMessageReceived?.call({
            'type': 'update_message_status',
            'message_id': messageId,
            'status': status,
            'group_id': _groupId,
        });
         // Also send a message_id_update to ensure UI has latest ID
        onMessageReceived?.call({
            'type': 'message_id_update',
            'old_id': tempId,
            'new_id': messageId,
            'status': status,
            'group_id': _groupId,
        });
    } catch (e) {
        print('Error in _handleMessageStatusUpdate: $e');
        print('Error stack trace: ${StackTrace.current}');
    }
  }

  Future<void> sendDeliveredStatus(String messageId) async {
    if (!_isConnected || _webSocket == null) return;

    try {
      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isEmpty) return;

      final senderId = userProfile.first['id'];
      if (senderId == null) return;

      final statusMessage = {
        'type': 'delivery_receipt',
        'message_id': messageId,
        'user_id': senderId,
        'conversation_id': _groupId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _webSocket?.add(json.encode(statusMessage));
    } catch (e) {
      print('Error sending delivered status: $e');
    }
  }

  Future<void> sendTypingStatus(Map<String, dynamic> message) async {
    if (!_isConnected || _webSocket == null) return;

    try {
      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isEmpty) {
        print('No user profile found in database');
        return;
      }

      final senderId = userProfile.first['id'];
      if (senderId == null) return;

      final typingMessage = {
        'type': 'typing',
        'data': {
          'conversation_id': message['group_id'],
          'sender_id': senderId,
          'is_typing': message['is_typing'],
        }
      };

      _webSocket?.add(json.encode(typingMessage));
    } catch (e) {
      print('Error sending typing status: $e');
    }
  }

  Future<void> sendMessage(Map<String, dynamic> message) async {
    print("We got ot  sendMessage Function");
    try {
      // First check if message with temp_id already exists
      
       print('my message is $message');
      
     
     
   
        // If WebSocket is not connected, add to queue
        if (!_isConnected || _webSocket == null) {
          _messageQueue.add(message);
        
          return;
        }
  
        // Send through WebSocket
        await _sendMessageInternal(message);
     
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  void dispose() {
    _retryTimer?.cancel();
    _connectivitySubscription?.cancel();
    _webSocket?.close();
    _webSocket = null;
    _isConnected = false;
    _messageQueue.clear();
  }

  void removeFromQueue(String messageId) {
    _messageQueue.removeWhere((msg) => msg['id'].toString() == messageId);
  }
} 