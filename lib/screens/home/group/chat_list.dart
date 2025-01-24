import 'package:flutter/material.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'chat_screen.dart'; // Import your existing Message screen
import 'package:cyanase/theme/theme.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import your theme
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
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allChats = []; // Store all chats
  List<Map<String, dynamic>> _filteredChats = []; // Store filtered chats

  @override
  void dispose() {
    _refreshController.close(); // Close the stream controller
    _searchController.dispose(); // Dispose the search controller
    super.dispose();
  }

  // Callback to reload the chat list
  void _reloadChats() {
    _refreshController.add(null); // Trigger a refresh
  }

  // Filter chats based on search query
  void _filterChats(String query) {
    setState(() {
      _filteredChats = _allChats
          .where((chat) =>
              chat["name"].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search groups...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: _filterChats, // Filter chats as the user types
            ),
          ),
          SizedBox(
            height: 20,
          ),
          Expanded(
            child: StreamBuilder<void>(
              stream: _refreshController.stream,
              builder: (context, snapshot) {
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadChats(),
                  builder: (context, futureSnapshot) {
                    if (!futureSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    _allChats = futureSnapshot.data!;
                    _filteredChats = _searchController.text.isEmpty
                        ? _allChats
                        : _allChats
                            .where((chat) => chat["name"]
                                .toLowerCase()
                                .contains(_searchController.text.toLowerCase()))
                            .toList();

                    if (_filteredChats.isEmpty) {
                      // Display introduction message and button to create groups
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Add an image before the welcome text with a circular grey background
                            Container(
                              width: 140, // Adjust size as needed
                              height: 140, // Adjust size as needed
                              decoration: BoxDecoration(
                                color: Colors.grey[200], // Grey background
                                shape: BoxShape.circle, // Circular shape
                              ),
                              child: Center(
                                child: SvgPicture.asset(
                                  'assets/images/new_user.svg', // Replace with your SVG path
                                  width: 100, // Adjust SVG size as needed
                                  height: 100,
                                  color: primaryColor, // Add color to the SVG
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Welcome to Cyanase Groups
                            const Text(
                              "Welcome to Cyanase Groups",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Small text below the welcome note
                            const Text(
                              "Start by creating a group to save and invest money with your friends or colleagues.",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            // Create a Group button with a plus icon
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NewGroupScreen(),
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.add, // Plus icon
                                color: primaryColor,
                              ),
                              label: Text(
                                "Create a Group",
                                style: TextStyle(
                                  color: primaryColor,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryTwo,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Display the list of chats
                    return ListView.builder(
                      itemCount: _filteredChats.length,
                      itemBuilder: (context, index) {
                        final chat = _filteredChats[index];
                        final hasUnreadMessages = chat["unreadCount"] > 0;

                        return ListTile(
                          leading: _getAvatar(chat["name"], chat["profilePic"],
                              chat["isGroup"]),
                          title: Text(
                            chat["name"],
                            style: const TextStyle(
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
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              if (hasUnreadMessages)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    chat["unreadCount"].toString(),
                                    style: const TextStyle(
                                      color: white,
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
                                  onMessageSent:
                                      _reloadChats, // Pass the callback
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
          ),
        ],
      ),
      // Show FloatingActionButton only when there are chats
      floatingActionButton: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadChats(),
        builder: (context, futureSnapshot) {
          if (futureSnapshot.hasData && futureSnapshot.data!.isNotEmpty) {
            return FloatingActionButton(
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
            );
          }
          return Container(); // Hide FloatingActionButton when there are no chats
        },
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

      Widget lastMessagePreview = const Text(
        "No messages yet",
        style: TextStyle(color: Colors.grey),
      );
      if (lastMessage != null) {
        if (lastMessage['type'] == 'image') {
          lastMessagePreview = Row(
            children: const [
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
            children: const [
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
            style: const TextStyle(color: Colors.grey),
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

      Widget lastMessagePreview = const Text(
        "No messages yet",
        style: TextStyle(color: Colors.grey),
      );
      if (lastMessage != null) {
        if (lastMessage['type'] == 'image') {
          lastMessagePreview = Row(
            children: const [
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
            children: const [
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
            style: const TextStyle(color: Colors.grey),
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
          style: const TextStyle(
            color: white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      // If it's a user with no profile picture, use the default avatar (avat.png)
      return CircleAvatar(
        radius: 30,
        backgroundImage: const AssetImage(
            'assets/images/avatar.png'), // Default avatar for users
      );
    }
  }
}
