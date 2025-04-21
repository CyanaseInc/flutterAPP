import 'package:flutter/material.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'chat_screen.dart';
import 'package:cyanase/theme/theme.dart';
import 'new_group.dart';
import 'dart:async';
import 'package:cyanase/helpers/loader.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/endpoints.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'pending_groups_screen.dart';
import 'package:lottie/lottie.dart';

class ChatList extends StatefulWidget {
  const ChatList({Key? key}) : super(key: key);

  @override
  ChatListState createState() => ChatListState();
}

class ChatListState extends State<ChatList>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allChats = [];
  List<Map<String, dynamic>> _filteredChats = [];
  int _pendingRequestCount = 0;
  List<Map<String, dynamic>> _adminGroups = [];
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController!);
    _getGroup();
    _animationController!.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
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

  Future<bool> _isUserApproved(int groupId) async {
    final db = await _dbHelper.database;
    final userProfile = await db.query('profile', limit: 1);
    final userId = userProfile.first['user_id'] as String? ?? '145';

    final participant = await db.query(
      'participants',
      where: 'group_id = ? AND user_id = ?',
      whereArgs: [groupId, userId],
      limit: 1,
    );

    if (participant.isNotEmpty) {
      return participant.first['is_approved'] == 1;
    }
    return false;
  }

  Future<bool> _isUserAdminForGroup(int groupId) async {
    final db = await _dbHelper.database;
    final userProfile = await db.query('profile', limit: 1);
    final userId = userProfile.first['user_id'] as String? ?? '145';

    // First check the group table for quick access
    final group = await db.query(
      'groups',
      where: 'id = ?',
      whereArgs: [groupId],
      limit: 1,
    );

    if (group.isNotEmpty && group.first['amAdmin'] == 1) {
      return true;
    }

    // Fallback to participants table for accuracy
    final participant = await db.query(
      'participants',
      where: 'group_id = ? AND user_id = ?',
      whereArgs: [groupId, userId],
      limit: 1,
    );

    return participant.isNotEmpty && participant.first['is_admin'] == 1;
  }

  Future<void> _getGroup() async {
    try {
      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isEmpty) {
        throw Exception('User profile not found');
      }

      final token = userProfile.first['token'] as String;
      final userId = userProfile.first['user_id'] as String? ?? '145';

      final dynamic response = await ApiService.getGroup(token);

      List<Map<String, dynamic>> groups;
      if (response is Map<String, dynamic> &&
          response['data'] is Map<String, dynamic> &&
          response['data']['data'] is List) {
        groups = List<Map<String, dynamic>>.from(response['data']['data']);
      } else {
        throw Exception('Invalid API response format: $response');
      }

      List<Map<String, dynamic>> adminGroups = [];
      int totalPending = 0;

      for (final groupData in groups) {
        final groupId = groupData['groupId'] as int?;
        final messageRestriction =
            groupData['restrict_messages_to_admins'] as bool? ?? false;
        final groupName = groupData['name'] as String?;
        final groupDescription = groupData['description'] as String?;
        final profilePic = groupData['profile_pic'] != null
            ? '${ApiEndpoints.server}${groupData['profile_pic']}'
            : '';
        final createdAt = groupData['created_at'] as String?;
        final createdBy = groupData['created_by'] as String?;
        final lastActivity = groupData['last_activity'] as String?;
        final participants = groupData['participants'] as List<dynamic>?;

        if (groupId == null || groupName == null) {
          continue;
        }

        bool isCurrentUserAdmin = false;
        int pendingCount = 0;

        if (participants != null && participants.isNotEmpty) {
          for (final participantData in participants) {
            final participantUserId = participantData['user_id']?.toString();
            final userName = participantData['user_name'] as String?;
            final role = participantData['role'] as String?;
            final joinedAt = participantData['joined_at'] as String?;
            final muted = participantData['muted'] is bool
                ? participantData['muted']
                    ? 1
                    : 0
                : participantData['muted'] as int? ?? 0;
            final isAdminDynamic = participantData['is_admin'] ?? false;
            final isApproved = participantData['is_approved'] is bool
                ? participantData['is_approved']
                : participantData['is_approved'] == 1;
            final isDenied = participantData['is_denied'] is bool
                ? participantData['is_denied']
                : participantData['is_denied'] == 1;

            if (participantUserId == userId) {
              isCurrentUserAdmin = (role == 'admin' || isAdminDynamic == true);
            }

            if (!isApproved &&
                !isDenied &&
                !(role == 'admin' || isAdminDynamic == true)) {
              pendingCount++;
            }

            final participantDataToStore = {
              'group_id': groupId,
              'user_id': participantUserId,
              'role': role ?? 'member',
              'joined_at': joinedAt ?? DateTime.now().toIso8601String(),
              'is_admin': (role == 'admin' || isAdminDynamic == true) ? 1 : 0,
              'is_approved': isApproved ? 1 : 0,
              'is_denied': isDenied ? 1 : 0,
              'user_name': userName ?? '',
            };

            final existingParticipant = await db.query(
              'participants',
              where: 'group_id = ? AND user_id = ?',
              whereArgs: [groupId, participantUserId],
              limit: 1,
            );

            if (existingParticipant.isEmpty) {
              await _dbHelper.insertParticipant(participantDataToStore);
            } else {
              await db.update(
                'participants',
                participantDataToStore,
                where: 'group_id = ? AND user_id = ?',
                whereArgs: [groupId, participantUserId],
              );
            }
          }
        }

        final groupDataToStore = {
          'id': groupId,
          'name': groupName,
          'amAdmin': isCurrentUserAdmin ? 1 : 0,
          'description': groupDescription ?? '',
          'profile_pic': profilePic,
          'type': 'group',
          'created_at': createdAt ?? DateTime.now().toIso8601String(),
          'created_by': createdBy ?? 'unknown',
          'last_activity': lastActivity ?? DateTime.now().toIso8601String(),
          'settings': '',
          'deposit_amount': groupData['deposit_amount'] as double? ?? null,
          'restrict_messages_to_admins': messageRestriction ? 1 : 0,
        };

        final existingGroup = await db.query(
          'groups',
          where: 'id = ?',
          whereArgs: [groupId],
          limit: 1,
        );

        if (existingGroup.isEmpty) {
          await _dbHelper.insertGroup(groupDataToStore);
        } else {
          await db.update(
            'groups',
            groupDataToStore,
            where: 'id = ?',
            whereArgs: [groupId],
          );
        }

        if (isCurrentUserAdmin && pendingCount > 0) {
          totalPending += pendingCount;
          adminGroups.add({
            'group_id': groupId,
            'group_name': groupName,
            'pending_count': pendingCount,
          });
        }
      }

      setState(() {
        _pendingRequestCount = totalPending;
        _adminGroups = adminGroups;
      });

      _reloadChats();
    } catch (e, stackTrace) {
      print('Error loading groups: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load groups: $e')),
        );
      }
      setState(() {
        _pendingRequestCount = 0;
        _adminGroups = [];
      });
    }
  }

  Widget _buildPendingBanner() {
    return AnimatedOpacity(
      opacity: _fadeAnimation!.value,
      duration: const Duration(seconds: 1),
      child: InkWell(
        onTap: () {
          if (_adminGroups.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PendingGroupsScreen(
                  adminGroups: _adminGroups,
                  onRequestProcessed: _getGroup,
                ),
              ),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: primaryTwo,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.person_add, color: white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$_pendingRequestCount pending group request${_pendingRequestCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: white, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 20),
          if (_pendingRequestCount > 0) _buildPendingBanner(),
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
          const SizedBox(height: 15),
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
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primaryTwo.withOpacity(0.1)),
                              child: Center(
                                child: Container(
                                  width: 240,
                                  height: 200,
                                  color: Colors.transparent,
                                  child: Lottie.asset(
                                    'assets/animations/group.json',
                                  ),
                                ),
                              ),
                            ),
                            const Text(
                              "Welcome to Saving Groups",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryTwo,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Create or join a group to start saving and investing with friends and family",
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
                                  isAdminOnlyMode:
                                      chat["restrict_messages_to_admins"],
                                  isCurrentUserAdmin: chat["amAdmin"],
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
      final isApproved = await _isUserApproved(group['id']);
      if (!isApproved) continue;

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
        'id': group['id'],
        'name': _toSentenceCase(group['name'] ?? ''),
        'description': group['description'],
        'profilePic': group['profile_pic'],
        'lastMessage': lastMessagePreview,
        'time': lastMessage != null
            ? _formatTime(lastMessage['timestamp'])
            : 'Just now',
        'timestamp': timestamp,
        'unreadCount': unreadCount,
        'isGroup': true,
        'hasMessages': lastMessage != null,
        'restrict_messages_to_admins':
            group['restrict_messages_to_admins'] == 0 ? false : true,
        'amAdmin': group['amAdmin'] == 0 ? false : true,
      });
    }

    chats.sort((a, b) {
      final bool aHasMessages = a['hasMessages'];
      final bool bHasMessages = b['hasMessages'];

      if (aHasMessages && bHasMessages) {
        final DateTime timeA = DateTime.parse(a['timestamp']);
        final DateTime timeB = DateTime.parse(b['timestamp']);
        return timeB.compareTo(timeA);
      } else if (aHasMessages) {
        return -1;
      } else if (bHasMessages) {
        return 1;
      } else {
        final DateTime timeA = DateTime.parse(a['timestamp']);
        final DateTime timeB = DateTime.parse(b['timestamp']);
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
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _truncateMessage(String message, {int maxLength = 20}) {
    if (message.length > maxLength) {
      return '${message.substring(0, maxLength)}...';
    }
    return message;
  }

  Widget _getAvatar(String name, String? profilePic, bool isGroup) {
    if (profilePic != null && profilePic.isNotEmpty) {
      return CircleAvatar(
        radius: 30,
        backgroundImage: CachedNetworkImageProvider(profilePic),
        onBackgroundImageError: (exception, stackTrace) {},
      );
    }

    if (isGroup) {
      final initials = name.isNotEmpty ? name[0].toUpperCase() : 'G';
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
