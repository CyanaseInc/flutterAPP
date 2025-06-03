import 'package:flutter/material.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/websocket_service.dart';
import 'package:cyanase/theme/theme.dart';
import 'message_chat.dart'; // Your MessageChat widget
import 'typing_indicator.dart'; // The new TypingIndicator widget

class MessageChatScreen extends StatefulWidget {
  final String name;
  final String? profilePic;
  final bool isGroup;
  final String? groupId;
  final String? description;
  // Other parameters...

  const MessageChatScreen({
    super.key,
    required this.name,
    this.profilePic,
    required this.isGroup,
    this.groupId,
    this.description,
    // Other parameters...
  });

  @override
  _MessageChatScreenState createState() => _MessageChatScreenState();
}

class _MessageChatScreenState extends State<MessageChatScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  Map<String, Set<String>> _typingUsers = {};
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupWebSocket();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _typingTimer?.cancel();
    ChatWebSocketService.instance.dispose();
    super.dispose();
  }

  void _loadMessages() async {
    // Your existing message loading logic
    final messages = await _dbHelper.getMessages(groupId: widget.groupId);
    if (mounted) {
      setState(() {
        _messages = messages;
      });
    }
  }

  void _setupWebSocket() {
    if (widget.groupId != null) {
      ChatWebSocketService.instance.initialize(widget.groupId!);
      ChatWebSocketService.instance.onMessageReceived = (data) {
        if (!mounted) return;
        if (data['type'] == 'typing') {
          _handleTypingStatus(data);
        } else if (data['type'] == 'new_message') {
          _handleNewMessage(data['message']);
        }
        // Handle other message types...
      };
    }
  }

  void _handleTypingStatus(Map<String, dynamic> data) {
    final groupId = data['group_id']?.toString();
    final username = data['username']?.toString();
    final isTyping = data['isTyping'] as bool? ?? false;

    if (groupId == null || username == null || groupId != widget.groupId) return;

    setState(() {
      _typingUsers[groupId] ??= {};
      if (isTyping) {
        _typingUsers[groupId]!.add(username);
      } else {
        _typingUsers[groupId]!.remove(username);
        if (_typingUsers[groupId]!.isEmpty) {
          _typingUsers.remove(groupId);
        }
      }
    });

    _typingTimer?.cancel();
    if (isTyping) {
      _typingTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _typingUsers[groupId]?.remove(username);
            if (_typingUsers[groupId]?.isEmpty ?? false) {
              _typingUsers.remove(groupId);
            }
          });
        }
      });
    }
  }

  void _handleNewMessage(Map<String, dynamic> message) {
    // Your existing new message handling logic
    setState(() {
      _messages.insert(0, message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        // Your app bar customization...
      ),
      body: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            reverse: true, // New messages at the bottom
            padding: const EdgeInsets.only(bottom: 80, top: 16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final isSameSender = index < _messages.length - 1 &&
                  message['sender_id'] == _messages[index + 1]['sender_id'];
              return MessageChat(
                isMe: message['isMe'] == 1,
                message: message['message'],
                time: message['timestamp'],
                isSameSender: isSameSender,
                replyToId: message['reply_to_id'],
                replyTo: message['reply_to_message'],
                replyToType: message['reply_to_type'],
                isAudio: message['type'] == 'audio',
                isImage: message['type'] == 'image',
                isNotification: message['type'] == 'notification',
                onPlayAudio: (id, path) {
                  // Your audio playback logic
                },
                messageId: message['id'].toString(),
                senderName: message['sender_name'] ?? 'Unknown',
                senderAvatar: message['sender_avatar'] ?? '',
                senderRole: message['sender_role'] ?? 'member',
                onReply: (id, text) {
                  // Your reply logic
                },
                onReplyTap: (id) {
                  // Your reply tap logic
                },
                messageStatus: message['status'] ?? 'sent',
                isUnread: message['status'] == 'unread',
              );
            },
          ),
          // Typing Indicator
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: TypingIndicator(
              typingUsers: _typingUsers[widget.groupId] ?? {},
              groupId: widget.groupId ?? '',
            ),
          ),
          // Your input area (e.g., text field, send button) positioned above the typing indicator
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (text) {
                        // Send typing status via WebSocket
                        ChatWebSocketService.instance.sendTypingStatus({
                          'group_id': widget.groupId,
                          'is_typing': text.isNotEmpty,
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: primaryColor),
                    onPressed: () {
                      // Your send message logic
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}