import 'package:app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'chat_list.dart';

class Chat {
  final String name;
  final String lastMessage;
  final String time;
  final String profilePic;
  final bool isMuted;
  final int unreadCount;

  Chat({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.profilePic,
    this.isMuted = false,
    this.unreadCount = 0,
  });
}

class ChatListScreen extends StatelessWidget {
  final List<Chat> chats = [
    Chat(
      name: "John Doe",
      lastMessage: "Hey, how are you?",
      time: "10:30 AM",
      profilePic: "assets/john_doe.jpg",
      isMuted: false,
      unreadCount: 2,
    ),
    Chat(
      name: "Jane Smith",
      lastMessage: "Let's catch up later!",
      time: "9:15 AM",
      profilePic: "assets/jane_smith.jpg",
      isMuted: true,
      unreadCount: 0,
    ),
    Chat(
      name: "Family Group",
      lastMessage: "Dinner at 7?",
      time: "Yesterday",
      profilePic: "assets/family_group.jpg",
      isMuted: true,
      unreadCount: 5,
    ),
    Chat(
      name: "Work Chat",
      lastMessage: "Please review the document.",
      time: "8:45 AM",
      profilePic: "assets/work_chat.jpg",
      isMuted: false,
      unreadCount: 1,
    ),
    Chat(
      name: "John Doe",
      lastMessage: "Hey, how are you?",
      time: "10:30 AM",
      profilePic: "assets/john_doe.jpg",
      isMuted: false,
      unreadCount: 2,
    ),
    Chat(
      name: "Jane Smith",
      lastMessage: "Let's catch up later!",
      time: "9:15 AM",
      profilePic: "assets/jane_smith.jpg",
      isMuted: true,
      unreadCount: 0,
    ),
    Chat(
      name: "Family Group",
      lastMessage: "Dinner at 7?",
      time: "Yesterday",
      profilePic: "assets/family_group.jpg",
      isMuted: true,
      unreadCount: 5,
    ),
    Chat(
      name: "Work Chat",
      lastMessage: "Please review the document.",
      time: "8:45 AM",
      profilePic: "assets/work_chat.jpg",
      isMuted: false,
      unreadCount: 1,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set the background color to white

      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage(chat.profilePic),
            ),
            title: Text(
              chat.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black, // Black text for visibility
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat.lastMessage,
                  style: TextStyle(color: Colors.black54), // Subtle black text
                ),
                Row(
                  children: [
                    Icon(
                      Icons.check,
                      color: chat.unreadCount == 0 ? Colors.blue : Colors.grey,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      chat.unreadCount == 0 ? "Read" : "Unread",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  chat.time,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                if (chat.unreadCount > 0)
                  Container(
                    margin: EdgeInsets.only(top: 5),
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryColor, // Use primaryColor for the badge
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      chat.unreadCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () {
              // Navigate to chat screen
            },
          );
        },
      ),
    );
  }
}
