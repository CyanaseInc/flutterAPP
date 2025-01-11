import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'package:cyanase/theme/theme.dart'; // Import your existing Message screen

class ChatList extends StatelessWidget {
  // Dummy chat data
  final List<Map<String, dynamic>> chats = [
    {
      "name": "John Doe",
      "profilePic": "assets/images/vian.jpg",
      "lastMessage": "Hey, how are you?",
      "time": "10:00 AM",
      "unreadCount": 2,
    },
    {
      "name": "Jane Smith",
      "profilePic": "assets/images/user2.png",
      "lastMessage": "See you tomorrow!",
      "time": "Yesterday",
      "unreadCount": 0,
    },
    {
      "name": "Alice Johnson",
      "profilePic": "assets/images/user3.png",
      "lastMessage": "Sent a photo",
      "time": "12:30 PM",
      "unreadCount": 1,
    },
    {
      "name": "Bob Brown",
      "profilePic": "assets/images/user4.png",
      "lastMessage": "Call me when you're free.",
      "time": "11:11 AM",
      "unreadCount": 3,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage(chat["profilePic"]),
              radius: 30, // Increase the radius to make the CircleAvatar larger
            ),
            title: Text(
              chat["name"],
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(chat["lastMessage"]),
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
                if (chat["unreadCount"] > 0)
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
              // Navigate to the Message screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MessageChatScreen(
                    name: chat["name"],
                    profilePic: chat["profilePic"],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle new chat button press
        },
        child: Icon(
          Icons.chat,
          color: Colors.white, // Set the icon color to white
        ),
        backgroundColor: primaryColor, // Use your primaryColor variable
      ),
    );
  }
}
