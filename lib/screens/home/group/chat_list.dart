import 'package:flutter/material.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'chat_screen.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'new_group.dart';
import 'dart:io';
import 'dart:async';
import 'package:cyanase/helpers/loader.dart';

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
  List<Map<String, dynamic>> _allChats = [];
  List<Map<String, dynamic>> _filteredChats = [];

  @override
  void dispose() {
    _refreshController.close();
    _searchController.dispose();
    super.dispose();
  }

  void _reloadChats() {
    _refreshController.add(null);
  }

  void _filterChats(String query) {
    setState(() {
      _filteredChats = _allChats
          .where((chat) =>
              chat["name"].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  String _toSentenceCase(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 20),
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
              onChanged: _filterChats,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<void>(
              stream: _refreshController.stream,
              builder: (context, snapshot) {
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadChats(),
                  builder: (context, futureSnapshot) {
                    if (!futureSnapshot.hasData) {
                      return const Center(child: Loader());
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
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: SvgPicture.asset(
                                  'assets/images/group.png',
                                  width: 100,
                                  height: 100,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Welcome to Cyanase Groups",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Start by creating a group to save and invest money with your friends or colleagues.",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NewGroupScreen(),
                                  ),
                                );
                              },
                              icon: Icon(Icons.add, color: primaryColor),
                              label: Text(
                                "Create a Group",
                                style: TextStyle(color: primaryColor),
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                                  onMessageSent: _reloadChats,
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
              child: Icon(Icons.group_add, color: primaryColor),
              backgroundColor: primaryTwo,
            );
          }
          return Container();
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadChats() async {
    final groups = await _dbHelper.getGroups();

    List<Map<String, dynamic>> chats = [];

    for (var group in groups) {
      final groupMessages = await _dbHelper.getMessages(
        groupId: group['id'],
        limit: 1, // Get only the most recent message
      );
      final lastMessage = groupMessages.isNotEmpty ? groupMessages.first : null;
      final unreadCount =
          _calculateUnreadCount(group['id'].toString(), groupMessages);

      Widget lastMessagePreview = const Text(
        "No messages yet",
        style: TextStyle(color: Colors.grey),
      );
      if (lastMessage != null) {
        switch (lastMessage['type']) {
          case 'image':
            lastMessagePreview = Row(
              children: const [
                Icon(Icons.image, color: Colors.grey, size: 16),
                SizedBox(width: 4),
                Text("Image", style: TextStyle(color: Colors.grey)),
              ],
            );
            break;
          case 'audio':
            lastMessagePreview = Row(
              children: const [
                Icon(Icons.mic, color: Colors.grey, size: 16),
                SizedBox(width: 4),
                Text("Audio", style: TextStyle(color: Colors.grey)),
              ],
            );
            break;
          case 'notification':
            lastMessagePreview = Row(
              children: [
                const Icon(Icons.info, color: Colors.grey, size: 16),
                const SizedBox(width: 4),
                Text(
                  _truncateMessage(
                      lastMessage['message']), // Truncate notification
                  style: const TextStyle(
                    color: Colors.grey,
                    fontStyle:
                        FontStyle.italic, // Visually distinguish notifications
                  ),
                ),
              ],
            );
            break;
          default:
            lastMessagePreview = Text(
              _truncateMessage(
                  lastMessage['message']), // Truncate regular messages
              style: const TextStyle(color: Colors.grey),
            );
            break;
        }
      }

      chats.add({
        "id": group['id'],
        "name": _toSentenceCase(group['name'] ?? ''),
        "profilePic": group['profile_pic'],
        "lastMessage": lastMessagePreview,
        "time": lastMessage != null
            ? _formatTime(lastMessage['timestamp'])
            : "Just now",
        "timestamp": lastMessage != null
            ? lastMessage['timestamp']
            : DateTime.now().toIso8601String(), // Added for proper sorting
        "unreadCount": unreadCount,
        "isGroup": true,
      });
    }

    // Sort chats by timestamp, newest first
    chats.sort((a, b) => DateTime.parse(b["timestamp"])
        .compareTo(DateTime.parse(a["timestamp"])));

    return chats;
  }

  int _calculateUnreadCount(
      String chatId, List<Map<String, dynamic>> messages) {
    // Placeholder: counts all messages; replace with actual unread logic
    return messages.where((m) => m['isMe'] == 0).length;
  }

  String _formatTime(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp);
    String formattedTime =
        "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    return formattedTime;
  }

  String _truncateMessage(String message, {int maxLength = 20}) {
    if (message.length > maxLength) {
      return "${message.substring(0, maxLength)}...";
    }
    return message;
  }

  Widget _getAvatar(String name, String? profilePic, bool isGroup) {
    if (profilePic != null && profilePic.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: FileImage(File(profilePic)),
        radius: 30,
      );
    } else if (isGroup) {
      final initials = name.isNotEmpty ? name[0].toUpperCase() : "G";
      return CircleAvatar(
        radius: 30,
        backgroundColor: Colors.green,
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
      return const CircleAvatar(
        radius: 30,
        backgroundImage: AssetImage('assets/images/avatar.png'),
      );
    }
  }
}
