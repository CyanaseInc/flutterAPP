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

  bool get isConnected => _isConnected;

  void _initConnectivity() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final result = results.first;
      _isNetworkAvailable = result != ConnectivityResult.none;
      print('Network status changed: ${result.toString()}');

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
      final wsUrl =
          'ws://${ApiEndpoints.myIp}:8000/ws/messages/$groupId/?token=$_token';
      print('Connecting to WebSocket at: $wsUrl');

      try {
        _webSocket = await WebSocket.connect(wsUrl);
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
              'conversation_id': message['group_id'],
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
      'conversation_id': message['conversation_id'],
      'timestamp': message['timestamp'],
      'temp_id': message['temp_id'],
      'attachment_type': message['attachment_type'],
      'file_name': message['file_name'],
      'file_data': message['file_data'],
      'reply_to_id': message['reply_to_id'],
      'reply_to_message': message['reply_to_message'],
    };

    messageToSend.removeWhere((key, value) => value == null);
    print(
        'DEBUG WEBSOCKET SEND: Sending message to WebSocket: ${json.encode(messageToSend)}');
    _webSocket?.add(json.encode(messageToSend));
  }

  void _listenToMessages() {
    _webSocket?.listen(
      (message) async {
        try {
          final data = json.decode(message);
          print(
              'DEBUG WEBSOCKET RECEIVE: Received message from WebSocket: ${json.encode(data)}');
          print('DEBUG 8.1: Message type being compared: ${data['type']}');

          switch (data['type']) {
            case 'message':
              print('DEBUG 9: Processing received message');
              if (data['temp_id'] != null) {
                print('DEBUG 10: Found matching temp_id: ${data['temp_id']}');
                print('DEBUG 10.1: New message ID from server: ${data['id']}');

                await _dbHelper.updateMessageId(
                    data['temp_id'].toString(), data['id'].toString());

                final idUpdate = {
                  'type': 'message_id_update',
                  'old_id': data['temp_id'].toString(),
                  'new_id': data['id'].toString(),
                  'group_id':
                      data['conversation_id'] ?? data['group_id'] ?? _groupId,
                };
                print('DEBUG 14.1: Sending ID update to UI: $idUpdate');
                onMessageReceived?.call(idUpdate);

                final statusUpdate = {
                  'type': 'update_message_status',
                  'message_id': data['id'].toString(),
                  'status': 'sent',
                  'timestamp': data['timestamp'],
                  'group_id':
                      data['conversation_id'] ?? data['group_id'] ?? _groupId,
                };
                print('DEBUG 14.2: Sending status update to UI: $statusUpdate');
                onMessageReceived?.call(statusUpdate);
              }

              // Only insert if we don't already have this message
              final db = await _dbHelper.database;
              final existingMessage = await db.query(
                'messages',
                where: 'id = ?',
                whereArgs: [data['id'].toString()],
              );

              if (existingMessage.isEmpty) {
                await _dbHelper.insertMessage({
                  'group_id': data['conversation_id'] ?? data['group_id'],
                  'sender_id': data['sender_id'].toString(),
                  'message': data['content'],
                  'type':
                      data['attachment_type'] ?? data['message_type'] ?? 'text',
                  'timestamp': data['timestamp'],
                  'status': data['status'] ?? 'received',
                  'isMe': 0,
                  'id': data['id'].toString(),
                  'temp_id': data['temp_id'],
                  'reply_to_id': data['reply_to_id'],
                  'reply_to_message': data['reply_to_message'],
                });
              }

              if (data['id'] != null) {
                print(
                    'DEBUG 11: Sending delivered status for message ${data['id']}');
                _sendDeliveredStatus(data['id'].toString());
              }

              onMessageReceived?.call(data);
              break;

            case 'update_message_status':
            case 'message_status':
              print('DEBUG 12: Processing message status update');
              final messageId = data['message_id'] ?? data['id'];
              final status = data['status'];

              if (messageId != null && status != null) {
                print(
                    'DEBUG 13: Updating message $messageId to status $status');
                await _dbHelper.updateMessageStatus(
                    messageId.toString(), status);

                final statusUpdate = {
                  'type': 'update_message_status',
                  'message_id': messageId.toString(),
                  'status': status,
                  'timestamp': data['timestamp'],
                  'group_id':
                      data['conversation_id'] ?? data['group_id'] ?? _groupId,
                };
                print('DEBUG 14: Sending status update to UI: $statusUpdate');
                onMessageReceived?.call(statusUpdate);
              }
              break;

            case 'error':
              print('WebSocket error: ${data['message']}');
              break;

            case 'typing':
              onMessageReceived?.call(data);
              break;

            case 'initial_messages':
              onMessageReceived?.call(data);
              break;

            case 'pong':
              print('Received pong from server');
              break;

            default:
              print('DEBUG 16: Unknown message type: ${data['type']}');
          }
        } catch (e) {
          print('DEBUG 17: Error processing WebSocket message: $e');
        }
      },
      onError: (error) {
        print('DEBUG 18: WebSocket error: $error');
        _isConnected = false;
        onConnectionStatusChanged?.call(false);
        _startRetryTimer();
      },
      onDone: () {
        print('DEBUG 19: WebSocket connection closed');
        _isConnected = false;
        onConnectionStatusChanged?.call(false);
        _startRetryTimer();
      },
    );
  }

  Future<void> _sendDeliveredStatus(String messageId) async {
    if (!_isConnected || _webSocket == null) return;

    try {
      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isEmpty) return;

      final senderId = userProfile.first['id'];
      if (senderId == null) return;

      final statusMessage = {
        'type': 'update_message_status',
        'message_id': messageId,
        'status': 'delivered',
        'user_id': senderId,
        'conversation_id': _groupId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('Sending delivered status for message $messageId');
      _webSocket?.add(json.encode(statusMessage));
    } catch (e) {
      print('Error sending delivered status: $e');
    }
  }

  Future<void> _sendReadStatus(String messageId) async {
    if (!_isConnected || _webSocket == null) return;

    try {
      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isEmpty) return;

      final senderId = userProfile.first['id'];
      if (senderId == null) return;

      final statusMessage = {
        'type': 'update_message_status',
        'message_id': messageId,
        'status': 'read',
        'user_id': senderId,
        'conversation_id': _groupId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('Sending read status for message $messageId');
      _webSocket?.add(json.encode(statusMessage));
    } catch (e) {
      print('Error sending read status: $e');
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

      print('Sending typing status: $typingMessage');
      _webSocket?.add(json.encode(typingMessage));
    } catch (e) {
      print('Error sending typing status: $e');
    }
  }

  Future<void> sendMessage(Map<String, dynamic> message) async {
    try {
      if (message['file_data'] != null) {
        // For messages with file data, track upload progress
        final fileData = message['file_data'];
        final chunkSize = 1024 * 1024; // 1MB chunks
        final totalChunks = (fileData.length / chunkSize).ceil();
        var currentChunk = 0;

        // Send initial message with progress
        message['upload_progress'] = 0.0;
        await _sendMessageInternal(message);

        // Send file data in chunks
        for (var i = 0; i < fileData.length; i += chunkSize) {
          final end = (i + chunkSize < fileData.length)
              ? i + chunkSize
              : fileData.length;
          final chunk = fileData.substring(i, end);

          // Send chunk
          await _sendMessageInternal({
            'type': 'file_chunk',
            'message_id': message['temp_id'],
            'chunk': chunk,
            'chunk_index': currentChunk,
            'total_chunks': totalChunks,
          });

          currentChunk++;

          // Update progress
          final progress = currentChunk / totalChunks;
          message['upload_progress'] = progress;
          await _sendMessageInternal({
            'type': 'upload_progress',
            'message_id': message['temp_id'],
            'progress': progress,
          });
        }

        // Send completion message
        await _sendMessageInternal({
          'type': 'file_complete',
          'message_id': message['temp_id'],
        });
      } else {
        // For regular messages, send as is
        await _sendMessageInternal(message);
      }
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
