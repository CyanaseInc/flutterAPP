import 'package:flutter/material.dart';
import 'dart:io'; // Import for File and FileImage
import 'chat_screen.dart'; // Import your existing Message screen
import 'package:cyanase/theme/theme.dart'; // Import your theme
import 'hash_numbers.dart'; // Import the hash functions
import 'new_group.dart'; // Import the new group screen
import 'package:cyanase/helpers/database_helper.dart'; // Import your DatabaseHelper
import 'package:cyanase/new_user.dart'; // Import the NewUserScreen

class ChatList extends StatefulWidget {
  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _chats = [];
  Map<String, String> _lastSeenTimestamps = {};

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  String _formatTime(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp);
    String formattedTime =
        "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    return formattedTime;
  }

  String _truncateMessage(String message, {int maxLength = 30}) {
    if (message.length > maxLength) {
      return "${message.substring(0, maxLength)}...";
    }
    return message;
  }

  Future<void> _loadChats() async {
    final users = await _dbHelper.getUsers();
    final groups = await _dbHelper.getGroups();
    final messages = await _dbHelper.getMessages();

    List<Map<String, dynamic>> chats = [];

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
        "isGroup": true,
      });
    }

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

    chats.sort((a, b) => b["time"].compareTo(a["time"]));

    setState(() {
      _chats = chats;
    });
  }

  int _calculateUnreadCount(
      String chatId, List<Map<String, dynamic>> messages) {
    final lastSeenTimestamp = _lastSeenTimestamps[chatId];
    if (lastSeenTimestamp == null) {
      return messages.length;
    }

    return messages.where((msg) => msg['timestamp'] > lastSeenTimestamp).length;
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _chats.isEmpty
          ? NewUserScreen()
          : ListView.builder(
              itemCount: _chats.length,
              itemBuilder: (context, index) {
                final chat = _chats[index];
                final hasUnreadMessages = chat["unreadCount"] > 0;

                return ListTile(
                  leading: _getAvatar(
                      chat["name"], chat["profilePic"], chat["isGroup"]),
                  title: Text(
                    chat["name"],
                    style: TextStyle(
                      fontWeight: hasUnreadMessages
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: chat["lastMessage"], // Use the widget directly
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
                    _lastSeenTimestamps[chat["id"].toString()] =
                        DateTime.now().toIso8601String();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MessageChatScreen(
                          name: chat["name"],
                          profilePic: chat["profilePic"],
                          groupId: chat["isGroup"] ? chat["id"] : null,
                          onMessageSent: _loadChats, // Pass the callback
                        ),
                      ),
                    ).then((_) {
                      _loadChats(); // Reload chats when returning
                    });
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
}
