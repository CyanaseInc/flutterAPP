import 'package:flutter/material.dart';
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
  Map<String, String> _lastSeenTimestamps =
      {}; // Track last seen timestamps for each chat

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  // Load chats from the database
  Future<void> _loadChats() async {
    // Fetch users, groups, and messages from the database
    final users = await _dbHelper.getUsers();
    final groups = await _dbHelper.getGroups();
    final messages = await _dbHelper.getMessages();

    // Combine data into a list of chats
    List<Map<String, dynamic>> chats = [];

    // Add user chats
    for (var user in users) {
      final userMessages =
          messages.where((msg) => msg['sender_id'] == user['id']).toList();
      final lastMessage = userMessages.isNotEmpty ? userMessages.last : null;

      // Calculate unread messages
      final unreadCount = _calculateUnreadCount(user['id'], userMessages);

      chats.add({
        "id": user['id'],
        "name": user['name'],
        "profilePic": user['profile_pic'],
        "lastMessage":
            lastMessage != null ? lastMessage['message'] : "No messages yet",
        "time": lastMessage != null ? lastMessage['timestamp'] : "Just now",
        "unreadCount": unreadCount,
        "isGroup": false,
      });
    }

    // Add group chats
    for (var group in groups) {
      final groupMessages =
          messages.where((msg) => msg['group_id'] == group['id']).toList();
      final lastMessage = groupMessages.isNotEmpty ? groupMessages.last : null;

      // Calculate unread messages
      final unreadCount =
          _calculateUnreadCount(group['id'].toString(), groupMessages);

      chats.add({
        "id": group['id'],
        "name": group['name'],
        "profilePic": group['profile_pic'],
        "lastMessage":
            lastMessage != null ? lastMessage['message'] : "No messages yet",
        "time": lastMessage != null ? lastMessage['timestamp'] : "Just now",
        "unreadCount": unreadCount,
        "isGroup": true,
      });
    }

    // Sort chats by the timestamp of the last message (most recent first)
    chats.sort((a, b) => b["time"].compareTo(a["time"]));

    // Update the state with the loaded chats
    setState(() {
      _chats = chats;
    });
  }

  // Calculate unread messages for a chat
  int _calculateUnreadCount(
      String chatId, List<Map<String, dynamic>> messages) {
    final lastSeenTimestamp = _lastSeenTimestamps[chatId];
    if (lastSeenTimestamp == null) {
      // If no last seen timestamp, assume all messages are unread
      return messages.length;
    }

    // Count messages sent after the last seen timestamp
    return messages.where((msg) => msg['timestamp'] > lastSeenTimestamp).length;
  }

  // Get a default avatar for users with no profile picture
  Widget _getAvatar(String name, String? profilePic) {
    if (profilePic != null && profilePic.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: AssetImage(profilePic),
        radius: 30,
      );
    } else {
      // Use initials as a fallback
      final initials = name.isNotEmpty ? name[0].toUpperCase() : "U";
      return CircleAvatar(
        radius: 30,
        backgroundColor: Colors.blue, // Replace with your primaryColor
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _chats.isEmpty
          ? NewUserScreen() // Show NewUserScreen if there are no chats
          : ListView.builder(
              itemCount: _chats.length,
              itemBuilder: (context, index) {
                final chat = _chats[index];
                final hasUnreadMessages = chat["unreadCount"] > 0;

                return ListTile(
                  leading: _getAvatar(chat["name"], chat["profilePic"]),
                  title: Text(
                    chat["name"],
                    style: TextStyle(
                      fontWeight: hasUnreadMessages
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    chat["lastMessage"],
                    style: TextStyle(
                      fontWeight: hasUnreadMessages
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
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
                    // Update the last seen timestamp for this chat
                    _lastSeenTimestamps[chat["id"].toString()] =
                        DateTime.now().toIso8601String();

                    // Navigate to the Message screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MessageChatScreen(
                          name: chat["name"],
                          profilePic: chat["profilePic"],
                          groupId: chat["isGroup"]
                              ? chat["id"]
                              : null, // Pass groupId if it's a group
                        ),
                      ),
                    ).then((_) {
                      // Reload chats when returning from the message screen
                      _loadChats();
                    });
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Step 3: Navigate to the new chat screen
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
        backgroundColor: primaryTwo, // Replace with your primaryColor
      ),
    );
  }
}
