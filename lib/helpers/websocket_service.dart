import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cyanase/helpers/endpoints.dart';

class WebSocketService {
  static final WebSocketService instance = WebSocketService._internal();
  WebSocketService._internal() {
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
          '$protocol://${ApiEndpoints.myIp}/ws/chat-list/token=$_token';

      
      try {
        _webSocket = await WebSocket.connect(
          wsUrl,
          headers: {
            'Connection': 'Upgrade',
            'Upgrade': 'websocket',
            'Sec-WebSocket-Version': '13',
          },
        );
       
        _isConnected = true;
        onConnectionStatusChanged?.call(true);
        _listenToMessages();

        // Get all unsent messages and send them
        final db = await _dbHelper.database;
        final unsentMessages = await db.query(
          'messages',
          where: 'status = ? AND group_id = ?',
          whereArgs: ['sending', groupId],
        );

        print('Found ${unsentMessages.length} unsent messages');
        for (final message in unsentMessages) {
          try {
            await _sendMessageInternal({
              'type': 'send_message',
              'content': message['message'],
              'sender_id': message['sender_id'],
              'room_id': message['group_id'],
              'timestamp': message['timestamp'],
              'temp_id': message['id'].toString(),
              'attachment_type': message['type'],
              'file_name': message['file_name'],
              'file_data': message['file_data'],
              'online_send': true
            });
            await _dbHelper.updateMessageStatus(
                message['id'].toString(), 'sent');
            print('Sent queued message ${message['id']}');
          } catch (e) {
            print('Failed to send message ${message['id']}: $e');
          }
        }
      } catch (e) {
        print('WebSocket connection error: $e');
        _isConnected = false;
        onConnectionStatusChanged?.call(false);
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
        print('Attempting to reconnect WebSocket...');
        await initialize(_groupId ?? '');
      } else if (_messageQueue.isNotEmpty) {
        print('WebSocket connected, processing message queue...');
        await _processMessageQueue();
      }
    });
  }

  Future<void> _processMessageQueue() async {
    if (!_isConnected || _webSocket == null || !_isNetworkAvailable) {
      print('Cannot process queue: WebSocket not connected or no network');
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
      throw Exception('WebSocket is not connected');
    }

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
    print('🔵 [STATUS] Sending message to WebSocket with temp_id: ${message['temp_id']}');
    _webSocket?.add(json.encode(messageToSend));
  }

  void _listenToMessages() {
    _webSocket?.listen(
      (message) async {
        try {
          final data = json.decode(message);
         
          switch (data['type']) {
            case 'message':
              // Handle received message
              if (data['temp_id'] != null) {
                // This is a sent message confirmation
                print('🔵 [STATUS] Processing sent message confirmation');
                await _handleSentMessageConfirmation(data);
              } else {
                // This is a new received message
                print('🔵 [STATUS] Processing new received message');
                await _handleReceivedMessage(data);
              }
              break;

            case 'message_status':
              print('🔵 [STATUS] Processing message status update');
              await _handleMessageStatusUpdate(data);
              break;

            case 'typing':
              onMessageReceived?.call(data);
              break;

            default:
              print('🔵 [STATUS] Unknown message type: ${data['type']}');
          }
        } catch (e) {
          print('🔴 [STATUS] Error processing WebSocket message: $e');
        }
      },
      onError: (error) {
        print('🔴 [STATUS] WebSocket error: $error');
        _isConnected = false;
        onConnectionStatusChanged?.call(false);
        _startRetryTimer();
      },
      onDone: () {
        print('🔵 [STATUS] WebSocket connection closed');
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
      final groupId = data['room_id']?.toString();
      
      print('🔵 [STATUS] Updating sent message status');
      print('🔵 [STATUS] Temp ID: $tempId');
      print('🔵 [STATUS] New ID: $newId');

      // First check if message with new ID already exists
      final db = await _dbHelper.database;
      final existingMessage = await db.query(
        'messages',
        where: 'id = ? OR temp_id = ?',
        whereArgs: [newId, tempId],
      );

      if (existingMessage.isEmpty) {
        // Update message ID and status in database
        await _dbHelper.updateMessageId(tempId, newId, 'sent');
        
        // Notify UI through message status stream
        _messageStatusController.add({
          'type': 'message_id_update',
          'old_id': tempId,
          'new_id': newId,
          'status': 'sent',
          'group_id': groupId,
        });
      } else {
        print('🔵 [STATUS] Message with ID $newId or temp_id $tempId already exists, skipping update');
      }
    } catch (e) {
      print('🔴 [STATUS] Error handling sent message confirmation: $e');
    }
  }

  Future<void> _handleReceivedMessage(Map<String, dynamic> data) async {
    try {
      final messageData = data['message'] ?? data;
      print('🔵 [STATUS] Processing received message');
      print('🔵 [STATUS] Message ID: ${messageData['id']}');

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
      });

      // Notify UI through message status stream
      _messageStatusController.add({
        'type': 'new_message',
        'message': messageData,
        'group_id': messageData['room_id'],
      });

      // Send delivered status
      await sendDeliveredStatus(messageData['id'].toString());
    } catch (e) {
      print('🔴 [STATUS] Error handling received message: $e');
    }
  }

  Future<void> _handleMessageStatusUpdate(Map<String, dynamic> data) async {
    try {
      final messageId = data['message_id']?.toString();
      final status = data['status'];
      final userId = data['user_id']?.toString();
      final timestamp = data['timestamp'];
      final groupId = data['group_id']?.toString();

      if (messageId == null || status == null) {
        print('🔴 [STATUS] Missing required fields for status update');
        return;
      }

      print('🔵 [STATUS] Updating message status');
      print('🔵 [STATUS] Message ID: $messageId');
      print('🔵 [STATUS] New Status: $status');

      // Update status in database
      await _dbHelper.updateMessageStatus(messageId, status);

      // Notify UI of status update through message status stream
      _messageStatusController.add({
        'type': 'update_message_status',
        'message_id': messageId,
        'status': status,
        'user_id': userId,
        'timestamp': timestamp,
        'group_id': groupId,
      });
    } catch (e) {
      print('🔴 [STATUS] Error handling message status update: $e');
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

      print('🔵 [STATUS] Sending delivered status for message $messageId');
      _webSocket?.add(json.encode(statusMessage));
    } catch (e) {
      print('🔴 [STATUS] Error sending delivered status: $e');
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

      print('Sending typing status: $typingMessage');
      _webSocket?.add(json.encode(typingMessage));
    } catch (e) {
      print('Error sending typing status: $e');
    }
  }

  Future<void> sendMessage(Map<String, dynamic> message) async {
    try {
      // First check if message with temp_id already exists
      final db = await _dbHelper.database;
      final tempId = message['temp_id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      final existingMessage = await db.query(
        'messages',
        where: 'temp_id = ?',
        whereArgs: [tempId],
      );

      if (existingMessage.isEmpty) {
        // Create database message
        final dbMessage = {
          'id': tempId,
          'temp_id': tempId,
          'group_id': message['room_id'],
          'sender_id': message['sender_id'],
          'message': message['content'],
          'type': message['message_type'] ?? 'text',
          'timestamp': message['timestamp'],
          'status': 'sending',
          'isMe': 1,
        };

        // Save to database
        await _dbHelper.insertMessage(dbMessage);
        print('🔵 [STATUS] Message saved to database with temp_id: $tempId');

        // If WebSocket is not connected, add to queue
        if (!_isConnected || _webSocket == null) {
          print('🔵 [STATUS] WebSocket not connected, adding message to queue');
          _messageQueue.add(message);
          return;
        }

        // Send through WebSocket
        await _sendMessageInternal(message);
        print('🔵 [STATUS] Message sent through WebSocket');
      } else {
        print('🔵 [STATUS] Message with temp_id $tempId already exists, skipping');
      }
    } catch (e) {
      print('🔴 [STATUS] Error sending message: $e');
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