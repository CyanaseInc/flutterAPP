import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/chat_websocket_service.dart';
import 'package:cyanase/screens/home/group/message_chat_screen.dart';
import 'package:intl/intl.dart';

class ChatList extends StatefulWidget {
  const ChatList({super.key});

  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ChatWebSocketService _wsService = ChatWebSocketService.instance;
  List<Map<String, dynamic>> _groups = [];
  Map<String, int> _unreadCounts = {};
  Map<String, Set<String>> _typingUsers = {};
  String? _currentUserId;
  bool _isLoading = true;

  StreamSubscription<Map<int, List<Map<String, dynamic>>>>? _messageStreamSubscription;
  StreamSubscription<Map<String, int>>? _unreadCountSubscription;
  StreamSubscription<Map<String, Set<String>>>? _typingStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _getCurrentUserId();
    await _loadGroups();
    _setupWebSocket();
    _setupStreams();
    setState(() => _isLoading = false);
  }

  Future<void> _getCurrentUserId() async {
    final db = await _dbHelper.database;
    final userProfile = await db.query('profile', limit: 1);
    if (userProfile.isNotEmpty) {
      _currentUserId = userProfile.first['id'] as String?;
    }
  }

  Future<void> _loadGroups() async {
    final groups = await _dbHelper.getGroups();
    final unreadCounts = await _dbHelper.getTotalUnreadMessageCount();
    setState(() {
      _groups = groups;
      _unreadCounts = {for (var group in groups) group['id'].toString(): unreadCounts};
    });
  }

  void _setupWebSocket() {
    _wsService.onMessageReceived = (data) {
      if (!mounted) return;
      try {
        if (data['type'] == 'new_message') {
          _handleNewMessage(data['group_id'].toString(), data);
        } else if (data['type'] == 'update_message_status') {
          _handleMessageStatusUpdate(data);
        } else if (data['type'] == 'typing') {
          _handleTypingStatus(data);
        }
      } catch (e) {
        print('🔴 [ChatList] Error handling WebSocket message: $e');
      }
    };
    _wsService.initialize('chat_list'); // Initialize for all groups
  }

  void _setupStreams() {
    _messageStreamSubscription = _dbHelper.messageStream.listen((groupMessages) {
      if (!mounted) return;
      setState(() {
        for (var groupId in groupMessages.keys) {
          final messages = groupMessages[groupId]!;
          final groupIndex = _groups.indexWhere((g) => g['id'] == groupId);
          if (groupIndex != -1) {
            _groups[groupIndex]['last_message'] = messages.isNotEmpty ? messages.first['message'] : null;
            _groups[groupIndex]['last_activity'] = messages.isNotEmpty ? messages.first['timestamp'] : null;
          }
        }
        _groups.sort((a, b) => (b['last_activity'] ?? '').compareTo(a['last_activity'] ?? ''));
      });
    });

    _unreadCountSubscription = _dbHelper.unreadCountStream.listen((counts) {
      if (!mounted) return;
      setState(() {
        _unreadCounts = counts;
      });
    });

    _typingStreamSubscription = _dbHelper.typingStream.listen((typingUsers) {
      if (!mounted) return;
      setState(() {
        _typingUsers = typingUsers;
      });
    });
  }

  void _handleNewMessage(String groupId, Map<String, dynamic> message) async {
    if (!mounted) return;
    final isMe = message['sender_id'] == _currentUserId;
    await _dbHelper.insertMessage({
      'group_id': groupId,
      'sender_id': message['sender_id'],
      'message': message['content'],
      'type': message['message_type'] ?? 'text',
      'timestamp': message['timestamp'] ?? DateTime.now().toIso8601String(),
      'status': isMe ? 'sent' : 'unread',
      'isMe': isMe ? 1 : 0,
    });
    // Stream will handle UI update
  }

  void _handleMessageStatusUpdate(Map<String, dynamic> data) async {
    if (!mounted) return;
    await _dbHelper.updateMessageStatus(data['message_id'], data['status']);
    // Stream will handle UI update
  }

  void _handleTypingStatus(Map<String, dynamic> data) {
    if (!mounted) return;
    _dbHelper.updateTypingStatus(
      data['group_id'].toString(),
      data['username'],
      data['isTyping'] ?? false,
    );
    // Stream will handle UI update
  }

  @override
  void dispose() {
    _messageStreamSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    _typingStreamSubscription?.cancel();
    _wsService.onMessageReceived = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<Map<int, List<Map<String, dynamic>>>>(
              stream: _dbHelper.messageStream,
              builder: (context, messageSnapshot) {
                return StreamBuilder<Map<String, int>>(
                  stream: _dbHelper.unreadCountStream,
                  builder: (context, unreadSnapshot) {
                    return StreamBuilder<Map<String, Set<String>>>(
                      stream: _dbHelper.typingStream,
                      builder: (context, typingSnapshot) {
                        return ListView.builder(
                          itemCount: _groups.length,
                          itemBuilder: (context, index) {
                            final group = _groups[index];
                            final groupId = group['id'].toString();
                            final unreadCount = _unreadCounts[groupId] ?? 0;
                            final isTyping = _typingUsers.containsKey(groupId) && _typingUsers[groupId]!.isNotEmpty;
                            final lastMessage = messageSnapshot.data?[group['id']]?.first;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: group['profile_pic'] != null
                                    ? NetworkImage(group['profile_pic'])
                                    : const AssetImage('assets/images/avatar.png') as ImageProvider,
                              ),
                              title: Text(group['name']),
                              subtitle: isTyping
                                  ? Text(
                                      'Typing...',
                                      style: TextStyle(color: Theme.of(context).primaryColor),
                                    )
                                  : Text(
                                      lastMessage?['message'] ?? 'No messages',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (lastMessage != null)
                                    Text(
                                      _formatTimestamp(lastMessage['timestamp']),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  if (unreadCount > 0)
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        unreadCount.toString(),
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                  if (lastMessage?['isMe'] == 1)
                                    _buildStatusIcon(lastMessage['status']),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MessageChatScreen(
                                      name: group['name'],
                                      profilePic: group['profile_pic'] ?? '',
                                      isGroup: true,
                                      groupId: group['id'],
                                      description: group['description'] ?? '',
                                      isAdminOnlyMode: group['restrict_messages_to_admins'] == 1,
                                      isCurrentUserAdmin: group['amAdmin'] == 1,
                                      allowSubscription: group['allows_subscription'] == 1,
                                      hasUserPaid: group['has_user_paid'] == 1,
                                      subscriptionAmount: group['subscription_amount']?.toString() ?? '0',
                                      onMessageSent: _loadGroups, // Refresh on message sent
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildStatusIcon(String? status) {
    switch (status) {
      case 'sending':
        return const Icon(Icons.access_time, size: 16, color: Colors.grey);
      case 'sent':
        return const Icon(Icons.check, size: 16, color: Colors.grey);
      case 'delivered':
        return const Icon(Icons.done_all, size: 16, color: Colors.grey);
      case 'read':
        return const Icon(Icons.done_all, size: 16, color: Colors.blue);
      default:
        return const SizedBox.shrink();
    }
  }

  String _formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    if (now.difference(dateTime).inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (now.difference(dateTime).inDays < 7) {
      return DateFormat('EEE').format(dateTime);
    } else {
      return DateFormat('dd/MM').format(dateTime);
    }
  }
}