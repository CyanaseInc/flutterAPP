// lib/services/background_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/notification_service.dart';
import 'package:cyanase/helpers/endpoints.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  WebSocketChannel? _channel;
  String? _userId;
  String? _token;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: false,
        autoStart: true,
        autoStartOnBoot: true,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    await service.startService();
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });
      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    final backgroundService = BackgroundService();
    await backgroundService._initializeWebSocket();

    // Monitor connectivity changes
    Connectivity().onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        await backgroundService._initializeWebSocket();
      }
    });

    // Keep service alive
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (result == ConnectivityResult.none) {
        return;
      }
      await backgroundService._checkWebSocket();
    });
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  Future<void> _initializeWebSocket() async {
    if (_isConnecting) return;
    _isConnecting = true;

    try {
      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isEmpty) {
        throw Exception('User profile not found');
      }

      _token = userProfile.first['token'] as String;
      _userId = userProfile.first['user_id'] as String? ?? '145';
      final wsUrl = 'ws://${ApiEndpoints.myIp}/ws/chat-list/?token=$_token';

      _channel?.sink.close();
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _reconnectAttempts = 0;

      _channel?.stream.listen(
        (message) async {
          final response = json.decode(message);
          await _handleWebSocketMessage(response);
        },
        onError: (error) {
          _attemptReconnect();
        },
        onDone: () {
          _attemptReconnect();
        },
      );
    } catch (e) {
      _attemptReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> _checkWebSocket() async {
    if (_channel == null || _channel?.closeCode != null) {
      await _initializeWebSocket();
    }
  }

  void _attemptReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) return;

    _reconnectAttempts++;
    final delay = Duration(seconds: pow(2, _reconnectAttempts).toInt());
    Timer(delay, () {
      _initializeWebSocket();
    });
  }

  Future<void> _handleWebSocketMessage(Map<String, dynamic> response) async {
    if (response['type'] == 'new_message') {
      final message = response['message'];
      if (message != null && message['room_id'] != null) {
        final groupId = message['room_id'].toString();
        await _handleNewMessage(groupId, message);
      }
    } else if (response['type'] == 'update_message_status') {
      final groupId = response['group_id']?.toString();
      if (groupId != null) {
        await _dbHelper.updateMessageStatus(
          response['message_id']?.toString(),
          response['status'],
        );
      }
    } else if (response['type'] == 'chat_list') {
      final chatList = List<Map<String, dynamic>>.from(response['chat_list'] ?? []);
      if (chatList.isNotEmpty) {
        await _processGroupData({'success': true, 'data': chatList});
      }
    }
  }

  Future<void> _handleNewMessage(String groupId, Map<String, dynamic> message) async {
    // Similar to your existing _handleNewMessage logic
    final messageId = message['id']?.toString() ?? '';
    final tempId = message['temp_id']?.toString() ?? '';
    final senderId = message['sender_id']?.toString() ?? '';
    final isMe = senderId == _userId;
    final messageStatus = isMe ? 'sent' : 'unread';

    final db = await _dbHelper.database;
    final existingMessage = await db.query(
      'messages',
      where: isMe ? 'temp_id = ?' : 'id = ? OR temp_id = ?',
      whereArgs: isMe ? [tempId] : [messageId, tempId],
    );

    if (existingMessage.isNotEmpty) return;

    final messageData = {
      'id': messageId,
      'group_id': groupId,
      'sender_id': senderId,
      'message': message['content'] ?? '',
      'timestamp': message['timestamp'] ?? DateTime.now().toIso8601String(),
      'type': message['message_type'] ?? 'text',
      'isMe': isMe ? 1 : 0,
      'status': messageStatus,
      'sender_name': message['full_name'] ?? 'Unknown',
      'sender_avatar': message['sender_info']?['profile_picture'] ?? '',
      'sender_role': message['sender_info']?['role'] ?? 'member',
      'temp_id': tempId.isNotEmpty ? tempId : null,
      'attachment_url': message['attachment_url'] ?? '',
      'blurhash': message['blurhash'] ?? '',
    };

    await _dbHelper.insertMessage(messageData);

    if (!isMe) {
      await _showMessageNotification(message, groupId);
    }
  }

  Future<void> _showMessageNotification(Map<String, dynamic> message, String groupId) async {
    final db = await _dbHelper.database;
    final group = await db.query(
      'groups',
      where: 'id = ?',
      whereArgs: [groupId],
      limit: 1,
    );

    if (group.isEmpty) return;

    final groupName = group.first['name'] as String? ?? 'Group';
    final senderName = message['full_name'] as String? ?? 'Someone';
    final content = message['content'] as String? ?? 'New message';
    final messageType = message['message_type'] as String? ?? 'text';

    String notificationContent;
    switch (messageType) {
      case 'image':
        notificationContent = '📷 Image';
        break;
      case 'audio':
        notificationContent = '🎤 Audio message';
        break;
      default:
        notificationContent = content;
    }

    await NotificationService().showMessageNotification(
      title: '$groupName - $senderName',
      body: notificationContent,
      payload: json.encode({
        'type': 'message',
        'groupId': groupId,
        'messageId': message['id'],
      }),
      groupId: groupId,
    );
  }

  Future<void> _processGroupData(Map<String, dynamic> response) async {
    // Similar to your existing processGroupData logic
    // Update groups and participants in the database
  }
}