import 'package:flutter/material.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'chat_screen.dart'; // Import your existing Message screen
import 'package:cyanase/theme/theme.dart'; // Import your theme
import 'new_group.dart'; // Import the new group screen
import 'dart:io'; // Import for File and FileImage
import 'dart:async';

class ChatList extends StatefulWidget {
  const ChatList({Key? key}) : super(key: key);

  @override
  ChatListState createState() => ChatListState();
}

class ChatListState extends State<ChatList> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  @override
  void dispose() {
    _refreshController.close(); // Close the stream controller
    super.dispose();
  }

  // Callback to reload the chat list
  void _reloadChats() {
    _refreshController.add(null); // Trigger a refresh
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<void>(
        stream: _refreshController.stream,
        builder: (context, snapshot) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadChats(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final chats = snapshot.data!;
              return ListView.builder(
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  final hasUnreadMessages = chat["unreadCount"] > 0;

                  return ListTile(
                    leading: _getAvatar(
                        chat["name"], chat["profilePic"], chat["isGroup"]),
                    title: Text(
                      chat["name"],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: chat["lastMessage"],
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          chat["time"],
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        if (hasUnreadMessages)
                          Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              chat["unreadCount"].toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MessageChatScreen(
                            name: chat["name"],
                            profilePic: chat["profilePic"],
                            groupId: chat["isGroup"] ? chat["id"] : null,
                            onMessageSent: _reloadChats, // Pass the callback
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewGroupScreen(),
            ),
          );
        },
        child: Icon(
          Icons.group_add,
          color: primaryColor,
        ),
        backgroundColor: primaryTwo,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadChats() async {
    final users = await _dbHelper.getUsers();
    final groups = await _dbHelper.getGroups();
    final messages = await _dbHelper.getMessages();

    List<Map<String, dynamic>> chats = [];

    // Load user chats
    for (var user in users) {
      final userMessages =
          messages.where((msg) => msg['sender_id'] == user['id']).toList();
      final lastMessage = userMessages.isNotEmpty ? userMessages.last : null;
      final unreadCount = _calculateUnreadCount(user['id'], userMessages);

      Widget lastMessagePreview = Text(
        "No messages yet",
        style: TextStyle(color: Colors.grey),
      );
      if (lastMessage != null) {
        if (lastMessage['type'] == 'image') {
          lastMessagePreview = Row(
            children: [
              Icon(Icons.image, color: Colors.grey, size: 16),
              SizedBox(width: 4),
              Text(
                "Image",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          );
        } else if (lastMessage['type'] == 'audio') {
          lastMessagePreview = Row(
            children: [
              Icon(Icons.mic, color: Colors.grey, size: 16),
              SizedBox(width: 4),
              Text(
                "Audio",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          );
        } else {
          lastMessagePreview = Text(
            _truncateMessage(lastMessage['message']),
            style: TextStyle(color: Colors.grey),
          );
        }
      }

      chats.add({
        "id": user['id'],
        "name": user['name'],
        "profilePic": user['profile_pic'],
        "lastMessage": lastMessagePreview,
        "time": lastMessage != null
            ? _formatTime(lastMessage['timestamp'])
            : "Just now",
        "unreadCount": unreadCount,
        "isGroup": false,
      });
    }

    // Load group chats
    for (var group in groups) {
      final groupMessages =
          messages.where((msg) => msg['group_id'] == group['id']).toList();
      final lastMessage = groupMessages.isNotEmpty ? groupMessages.last : null;
      final unreadCount =
          _calculateUnreadCount(group['id'].toString(), groupMessages);

      Widget lastMessagePreview = Text(
        "No messages yet",
        style: TextStyle(color: Colors.grey),
      );
      if (lastMessage != null) {
        if (lastMessage['type'] == 'image') {
          lastMessagePreview = Row(
            children: [
              Icon(Icons.image, color: Colors.grey, size: 16),
              SizedBox(width: 4),
              Text(
                "Image",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          );
        } else if (lastMessage['type'] == 'audio') {
          lastMessagePreview = Row(
            children: [
              Icon(Icons.mic, color: Colors.grey, size: 16),
              SizedBox(width: 4),
              Text(
                "Audio",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          );
        } else {
          lastMessagePreview = Text(
            _truncateMessage(lastMessage['message']),
            style: TextStyle(color: Colors.grey),
          );
        }
      }

      chats.add({
        "id": group['id'],
        "name": group['name'],
        "profilePic": group['profile_pic'],
        "lastMessage": lastMessagePreview,
        "time": lastMessage != null
            ? _formatTime(lastMessage['timestamp'])
            : "Just now",
        "unreadCount": unreadCount,
        "isGroup": true,
      });
    }

    // Sort chats by time (most recent first)
    chats.sort((a, b) => b["time"].compareTo(a["time"]));

    return chats;
  }

  // Calculate unread message count
  int _calculateUnreadCount(
      String chatId, List<Map<String, dynamic>> messages) {
    // Example logic: Count messages not seen by the user
    return messages.length; // Replace with your actual logic
  }

  // Format timestamp to a readable time
  String _formatTime(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp);
    String formattedTime =
        "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    return formattedTime;
  }

  // Truncate long messages
  String _truncateMessage(String message, {int maxLength = 30}) {
    if (message.length > maxLength) {
      return "${message.substring(0, maxLength)}...";
    }
    return message;
  }

  // Get avatar for the chat
  Widget _getAvatar(String name, String? profilePic, bool isGroup) {
    if (profilePic != null && profilePic.isNotEmpty) {
      // If a profile picture is available, use it
      return CircleAvatar(
        backgroundImage:
            FileImage(File(profilePic)), // Use FileImage for file paths
        radius: 30,
      );
    } else if (isGroup) {
      // If it's a group with no profile picture, use the group's initials
      final initials = name.isNotEmpty ? name[0].toUpperCase() : "G";
      return CircleAvatar(
        radius: 30,
        backgroundColor: Colors.green, // Group avatar color
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      // If it's a user with no profile picture, use the default avatar (avat.png)
      return CircleAvatar(
        radius: 30,
        backgroundImage:
            AssetImage('assets/avat.png'), // Default avatar for users
      );
    }
  }
}
