import 'package:flutter/material.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'chat_screen.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'new_group.dart';
import 'dart:io';
import 'dart:async';
import 'package:cyanase/helpers/loader.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/cache_image.dart';
import 'package:path/path.dart';

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
  void initState() {
    super.initState();
    _getGroup(); // Fetch groups on initialization
  }

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

  Future<void> _getGroup() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);

      if (userProfile.isEmpty) {
        throw Exception('No user profile found');
      }

      final token = userProfile.first['token'] as String;
      final dynamic response = await ApiService.getGroup(token);

      List<Map<String, dynamic>> groups;
      if (response is List && response.isNotEmpty) {
        final firstItem = response[0];
        if (firstItem is Map<String, dynamic> &&
            firstItem['data'] is Map<String, dynamic> &&
            firstItem['data']['data'] is List) {
          groups = List<Map<String, dynamic>>.from(firstItem['data']['data']);
        } else {
          throw Exception('Unexpected list item format: $firstItem');
        }
      } else if (response is Map<String, dynamic> &&
          response['data'] is Map<String, dynamic> &&
          response['data']['data'] is List) {
        groups = List<Map<String, dynamic>>.from(response['data']['data']);
      } else if (response is List<Map<String, dynamic>>) {
        groups = response;
      } else {
        throw Exception('Invalid API response format: $response');
      }

      print("Extracted groups: $groups");

      for (final groupData in groups) {
        final groupId = groupData['groupId'] as int?;
        final groupName = groupData['name'] as String?;
        final groupDescription = groupData['description'] as String?;
        final profilePic = groupData['profile_pic'] as String?;
        final createdAt = groupData['created_at'] as String?;
        final createdBy = groupData['created_by'] as String?;
        final lastActivity = groupData['last_activity'] as String?;
        final participants = groupData['participants'] as List<dynamic>?;

        if (groupId == null || groupName == null) {
          print("Skipping group with missing ID or name: $groupData");
          continue;
        }

        print("Processing group: $groupName (ID: $groupId)");

        final existingGroup = await db.query(
          'groups',
          where: 'id = ?',
          whereArgs: [groupId],
          limit: 1,
        );

        if (existingGroup.isEmpty) {
          String? localImagePath;
          if (profilePic != null && profilePic.isNotEmpty) {
            final String fileName = 'group_$groupId${extension(profilePic)}';
            localImagePath =
                await ImageHelper.downloadAndSaveImage(profilePic, fileName);
          }

          await dbHelper.insertGroup({
            'id': groupId,
            'name': groupName,
            'description': groupDescription ?? '',
            'profile_pic': localImagePath ?? '',
            'type': 'group',
            'created_at': createdAt ?? DateTime.now().toIso8601String(),
            'created_by': createdBy ?? 'unknown',
            'last_activity': lastActivity ?? DateTime.now().toIso8601String(),
            'settings': '',
          });
          print("Inserted group: $groupName (ID: $groupId)");
        } else {
          print(
              "Group $groupName (ID: $groupId) already exists, skipping insert");
        }

        if (participants != null && participants.isNotEmpty) {
          print("Participants to process: $participants");
          for (final participantData in participants) {
            print("Raw participant data: $participantData");

            // Safe type extraction
            final userIdDynamic = participantData['user_id'];
            final roleDynamic = participantData['role'];
            final joinedAtDynamic = participantData['joined_at'];
            final mutedDynamic = participantData['muted'];

            // Convert types safely
            final String? userId = userIdDynamic is String
                ? userIdDynamic
                : userIdDynamic?.toString();
            final String? role = roleDynamic is String ? roleDynamic : null;
            final String? joinedAt =
                joinedAtDynamic is String ? joinedAtDynamic : null;
            int? muted;
            if (mutedDynamic is bool) {
              muted = mutedDynamic ? 1 : 0;
            } else if (mutedDynamic is int) {
              muted = mutedDynamic;
            } else {
              print(
                  "Unexpected muted type: ${mutedDynamic?.runtimeType}, value: $mutedDynamic");
              muted = 0; // Default to 0 for unknown types
            }

            if (userId == null) {
              print("Skipping participant with null user_id in group $groupId");
              continue;
            }

            print("Attempting to add participant: $userId to group $groupId");

            final existingParticipant = await db.query(
              'participants',
              where: 'group_id = ? AND user_id = ?',
              whereArgs: [groupId, userId],
              limit: 1,
            );
            print("Existing participant check: $existingParticipant");

            if (existingParticipant.isEmpty) {
              await dbHelper.insertParticipant({
                'group_id': groupId,
                'user_id': userId,
                'role': role ?? 'member',
                'joined_at': joinedAt ?? DateTime.now().toIso8601String(),
                'muted': muted ?? 0,
              });
              print("Inserted participant $userId into group $groupId");
            } else {
              print("Participant $userId already in group $groupId, skipping");
            }
          }

          // Verify participants in DB after insertion
          final participantCheck = await db.query(
            'participants',
            where: 'group_id = ?',
            whereArgs: [groupId],
          );
          print("Participants in DB for group $groupId: $participantCheck");
        } else {
          print("No participants found for group $groupId");
        }
      }

      _reloadChats();
    } catch (e) {
      print("Error retrieving groups: $e");
      rethrow; // Temporarily keep for stack trace
    }
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
                                  description:
                                      chat["description"] ?? 'Our Saving Group',
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
              onPressed: () {
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
        limit: 1,
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
                  _truncateMessage(lastMessage['message']),
                  style: const TextStyle(
                      color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ],
            );
            break;
          default:
            lastMessagePreview = Text(
              _truncateMessage(lastMessage['message']),
              style: const TextStyle(color: Colors.grey),
            );
            break;
        }
      }

      final timestamp = lastMessage != null
          ? lastMessage['timestamp']
          : group['created_at'] ?? DateTime.now().toIso8601String();

      chats.add({
        "id": group['id'],
        "name": _toSentenceCase(group['name'] ?? ''),
        "description": group['description'],
        "profilePic": group['profile_pic'],
        "lastMessage": lastMessagePreview,
        "time": lastMessage != null
            ? _formatTime(lastMessage['timestamp'])
            : "Just now",
        "timestamp": timestamp,
        "unreadCount": unreadCount,
        "isGroup": true,
        "hasMessages": lastMessage != null,
      });
    }

    chats.sort((a, b) {
      final bool aHasMessages = a["hasMessages"];
      final bool bHasMessages = b["hasMessages"];

      if (aHasMessages && bHasMessages) {
        final DateTime timeA = DateTime.parse(a["timestamp"]);
        final DateTime timeB = DateTime.parse(b["timestamp"]);
        return timeB.compareTo(timeA);
      } else if (aHasMessages) {
        return -1;
      } else if (bHasMessages) {
        return 1;
      } else {
        final DateTime timeA = DateTime.parse(a["timestamp"]);
        final DateTime timeB = DateTime.parse(b["timestamp"]);
        return timeB.compareTo(timeA);
      }
    });

    return chats;
  }

  int _calculateUnreadCount(
      String chatId, List<Map<String, dynamic>> messages) {
    return messages.where((m) => m['isMe'] == 0).length;
  }

  String _formatTime(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp);
    return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  String _truncateMessage(String message, {int maxLength = 20}) {
    if (message.length > maxLength) {
      return "${message.substring(0, maxLength)}...";
    }
    return message;
  }

  Widget _getAvatar(String name, String? profilePic, bool isGroup) {
    if (profilePic != null && profilePic.isNotEmpty) {
      if (profilePic.startsWith('http')) {
        final String fileName =
            'group_${name.hashCode}${extension(basename(profilePic))}';
        return FutureBuilder<String?>(
          future: ImageHelper.downloadAndSaveImage(profilePic, fileName),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              return CircleAvatar(
                backgroundImage: FileImage(File(snapshot.data!)),
                radius: 30,
              );
            }
            return CircleAvatar(
              radius: 30,
              backgroundColor: primaryColor,
              child: const Icon(Icons.image, color: white),
            );
          },
        );
      } else {
        return CircleAvatar(
          backgroundImage: FileImage(File(profilePic)),
          radius: 30,
        );
      }
    } else if (isGroup) {
      final initials = name.isNotEmpty ? name[0].toUpperCase() : "G";
      return CircleAvatar(
        radius: 30,
        backgroundColor: primaryColor,
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
