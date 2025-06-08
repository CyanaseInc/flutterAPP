import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cyanase/helpers/endpoints.dart';
import 'package:cyanase/helpers/notification_service.dart';

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
  final _messageStatusController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messageStatusStream => _messageStatusController.stream;

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
  
    final messageToSend = {
      'type': message['type'],
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
 print("were are sending to websokets, $messageToSend");

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

            case 'update_message_status':  
           
                await  _handleSentMessageConfirmation(data);
              break;

            case 'typing':
              onMessageReceived?.call(data);
              break;

            case 'error':
              print('🔴 [ChatWebSocket] Error from server: ${data['message']}');
              break;

            default:
              print('🔵 [ChatWebSocket] Unhandled message type: ${data['type']}');
          }
        } catch (e) {
          print('🔴 [ChatWebSocket] Error processing message: $e');
        }
      },
      onError: (error) {
        print('🔴 [ChatWebSocket] WebSocket error: $error');
        _isConnected = false;
        onConnectionStatusChanged?.call(false);
        _startRetryTimer();
      },
    );
  }

  Future<void> _handleSentMessageConfirmation(Map<String, dynamic> data) async {
    try {
      final messageData = data['message'];
      final tempId = messageData['temp_id']?.toString();
      final newId = messageData['id']?.toString();
       
      if (tempId == null || newId == null) {
        print('Missing temp_id or new_id in message confirmation');
        return;
      }

      print('Message confirmation received - tempId: $tempId, newId: $newId');

      final db = await _dbHelper.database;
      
      // First check if a message with the new ID already exists
      final existingWithNewId = await db.query(
        'messages',
        where: 'id = ?',
        whereArgs: [newId],
      );

      if (existingWithNewId.isNotEmpty) {
        print('Message with new ID $newId already exists, skipping update');
        return;
      }

      // Update message ID and status in database
      final updateResult = await db.update(
        'messages',
        {
          'id': newId,
          'temp_id': null, // Clear the temp_id to prevent duplicates
          'status': 'sent'
        },
        where: 'temp_id = ?',
        whereArgs: [tempId],
      );

      if (updateResult > 0) {
        // Update media records if any
        await db.update(
          'media',
          {
            'message_id': newId,
            'temp_id': null
          },
          where: 'temp_id = ?',
          whereArgs: [tempId],
        );

        // Notify UI of the update
        _messageStatusController.add({
          'type': 'update_message_status',
          'message_id': newId,
          'status': 'sent',
          'group_id': messageData['room_id']?.toString(),
        });
      } else {
        print('No message found with temp_id $tempId to update');
      }
    } catch (e) {
      print('Error in _handleSentMessageConfirmation: $e');
      print('Error stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _handleReceivedMessage(Map<String, dynamic> data) async {
    try {
      // Extract message data from either format
      final messageData = data['message'] ?? data;
      final messageId = messageData['id']?.toString();
      final tempId = messageData['temp_id']?.toString();
      print('🔵 [ChatWebSocket] Processing received message: $messageData');

      // Check if message already exists in database using both id and temp_id
      final db = await _dbHelper.database;
      final existingMessage = await db.query(
        'messages',
        where: '(id = ? AND id IS NOT NULL) OR (temp_id = ? AND temp_id IS NOT NULL)',
        whereArgs: [messageId, tempId],
      );

      // Only save if message doesn't exist
      if (existingMessage.isEmpty) {
        // Save message to database with 'unread' status
        await _dbHelper.insertMessage({
          'id': messageId,
          'group_id': messageData['room_id']?.toString(),
          'sender_id': messageData['sender_id']?.toString(),
          'message': messageData['content']?.toString(),
          'type': messageData['message_type']?.toString() ?? 'text',
          'timestamp': messageData['timestamp']?.toString(),
          'status': 'unread',
          'isMe': 0,
          'username': messageData['username']?.toString(),
          'sender_info': messageData['sender_info'],
          'is_edited': messageData['is_edited'] ?? false,
          'is_deleted': messageData['is_deleted'] ?? false,
          'is_forwarded': messageData['is_forwarded'] ?? false,
          'reply_to_id': messageData['reply_to_id']?.toString(),
          'reply_to_message': messageData['reply_to_message']?.toString(),
          'reply_to_type': messageData['reply_to_type']?.toString(),
          'temp_id': tempId,
        });

        // Handle media for image or audio messages
        if (messageData['message_type'] == 'image' || messageData['message_type'] == 'audio') {
          if (messageData['attachment_url'] != null) {
            await _dbHelper.insertMedia(
              messageId: int.parse(messageId ?? '0'),
              type: messageData['message_type']?.toString() ?? 'text',
              url: messageData['attachment_url']?.toString() ?? '',
              blurhash: messageData['thumbnail_id']?.toString(),
              mimeType: messageData['attachment_type'] == 'audio' ? 'audio/mpeg' : 'image/jpeg',
            );
            print('🔵 [ChatWebSocket] Inserted media for message $messageId');
          } else {
            print('🔴 [ChatWebSocket] Missing attachment_url for ${messageData['message_type']} message $messageId');
          }
        }

        // Get group info for notification
        final groupInfo = await db.query(
          'groups',
          where: 'id = ?',
          whereArgs: [messageData['room_id']?.toString()],
          columns: ['name'],
        );
        final groupName = groupInfo.isNotEmpty ? groupInfo.first['name'] as String : 'Group';

        // Show notification for new message
        final senderName = messageData['username']?.toString() ?? 'Unknown';
        final messageContent = messageData['content']?.toString() ?? '';
        final messageType = messageData['message_type']?.toString() ?? 'text';
        final groupId = messageData['room_id']?.toString();
        final senderInfo = messageData['sender_info'] ?? {};
        final senderProfilePic = senderInfo['profile_pic']?.toString();

        // Show notification based on message type
        String notificationBody = messageContent;
        if (messageType == 'image') {
          notificationBody = '📷 Image';
        } else if (messageType == 'audio') {
          notificationBody = '🎵 Audio';
        }

        // Always show notification for new messages
        await NotificationService().showGroupMessageNotification(
          groupName: groupName,
          senderName: senderName,
          message: notificationBody,
          groupId: groupId ?? '',
          profilePic: senderProfilePic,
        );

        // Notify UI of new message and status update
        onMessageReceived?.call({
          'type': 'new_message',
          'message': messageData,
        });

        // Send delivered status
        if (messageId != null) {
          await sendDeliveredStatus(messageId);
        }

        // Update message status stream
        _messageStatusController.add({
          'type': 'update_message_status',
          'message_id': messageId,
          'status': 'unread',
          'group_id': groupId,
        });
      } else {
        print('🔵 [ChatWebSocket] Message already exists in database, skipping save');
      }
    } catch (e, stackTrace) {
      print('🔴 [ChatWebSocket] Error handling received message: $e');
      print('🔴 [ChatWebSocket] Stack trace: $stackTrace');
    }
  }

  Future<void> _handleMessageStatusUpdate(Map<String, dynamic> data) async {
    print('🔵 [ChatWebSocket] Handling message status update: $data');
    try {
      final messageId = data['id']?.toString();
      final status = data['status'];
      final groupId = data['room_id']?.toString();

      if (messageId == null || status == null) {
        print('Missing message_id or status in status update');
        return;
      }

      // Update the message status in database
      await _dbHelper.updateMessageStatus(messageId, status);
      
      // Notify UI of status update
      onMessageReceived?.call({
        'type': 'update_message_status',
        'message_id': messageId,
        'status': status,
        'group_id': groupId,
      });
      
      // Also notify through message status stream
      _messageStatusController.add({
        'type': 'update_message_status',
        'message_id': messageId,
        'status': status,
        'group_id': groupId,
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
        'room_id': _groupId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _webSocket?.add(json.encode(statusMessage));
      
      // Notify listeners about the status update
      _messageStatusController.add({
        'message_id': messageId,
        'status': 'delivered',
        'group_id': _groupId,
      });
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
          'room_id': message['group_id'],
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
    print("We got to sendMessage Function");
    try {
      print('my message is $message');
      
      // If WebSocket is not connected, add to queue
      if (!_isConnected || _webSocket == null) {
        _messageQueue.add(message);
        return;
      }
  
      // Send through WebSocket
      await _sendMessageInternal(message);
      
      // Don't update status here - wait for server confirmation
      // This prevents duplicate status updates
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
    _messageStatusController.close();
  }

  void removeFromQueue(String messageId) {
    _messageQueue.removeWhere((msg) => msg['id'].toString() == messageId);
  }
} 