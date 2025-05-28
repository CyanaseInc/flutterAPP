import 'package:flutter/material.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'chat_screen.dart';
import 'package:cyanase/theme/theme.dart';
import 'new_group.dart';
import 'dart:async';
import 'package:cyanase/helpers/loader.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/endpoints.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';
import 'chatlist_header.dart';
import 'dart:convert';
import 'dart:io' show WebSocket;
import 'dart:math';

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
  List<Map<String, dynamic>> _pendingAdminLoans = [];
  List<Map<String, dynamic>> _pendingUserLoans = [];
  List<Map<String, dynamic>> _pendingWithdraw = [];
  List<Map<String, dynamic>> _ongoingUserLoans = [];
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  WebSocketChannel? _channel;
  String? _userId;
  Timer? _pingTimer;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;

  @override
  void initState() {
    super.initState();
    _allChats = [];
    _filteredChats = [];
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController!);
    print('🔵 Initializing WebSocket connection...');
    
    // Initialize WebSocket and load chats
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeWebSocket();
      await _loadChats(); // Load initial chats
    });
    
    _animationController!.forward();
  }

  @override
  void dispose() {
    print('🔵 Disposing WebSocket connection...');
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _animationController?.dispose();
    _refreshController.close();
    _searchController.dispose();
    super.dispose();
  }

  void _reloadChats() {
    _refreshController.add(null);
  }

  Future<void> _initializeWebSocket() async {
    if (_isConnecting) {
      print('🔵 Already attempting to connect...');
      return;
    }

    _isConnecting = true;
    print('🔵 Starting WebSocket initialization...');

    // Close existing connection if any
    if (_channel != null) {
      print('🔵 Closing existing WebSocket connection');
      _channel?.sink.close();
      _channel = null;
    }

    // Cancel existing ping timer
    _pingTimer?.cancel();
    _pingTimer = null;

    try {
      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isEmpty) {
        throw Exception('User profile not found');
      }

      final token = userProfile.first['token'] as String;
      _userId = userProfile.first['user_id'] as String? ?? '145';

      // Ensure we're using ws:// protocol with correct port
      final wsUrl = 'ws://${ApiEndpoints.myIp}/ws/chat-list/?token=$token';
      print('🔵 Connecting to WebSocket: $wsUrl');

      try {
        _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
        print('🔵 WebSocket connected successfully');
        _reconnectAttempts = 0; // Reset reconnect attempts on successful connection

        // Listen for WebSocket messages
        _channel?.stream.listen(
          (message) async {
            try {
              
              final response = json.decode(message);
              
              if (response['type'] == 'chat_list') {
               
                final chatList = List<Map<String, dynamic>>.from(
                    response['chat_list'] ?? []);
                print('🔵 Number of chats received: ${chatList.length}');

                if (chatList.isEmpty) {
                  print('🔵 No chat list data received');
                  return;
                }

                // Process the chat list data
                print('🔵 Starting to process group data');
                await processGroupData({'success': true, 'data': chatList});
                print('🔵 Finished processing group data');
              } else if (response['type'] == 'new_message') {
                print('🔵 Processing new_message');
                final message = response['message'];
                print('🔵 New message data: $message');
                
                if (message != null) {
                  print('🔵 Message details:');
                  print('  - Group ID: ${message['room_id']}');
                  print('  - Sender ID: ${message['sender_id']}');
                  print('  - Content: ${message['content']}');
                  print('  - Timestamp: ${message['timestamp']}');
                  print('  - Message Type: ${message['message_type']}');
                  
                  // Validate required fields
                  if (message['room_id'] == null) {
                    print('🔴 Error: group_id is null in message');
                    return;
                  }

                  print('🔵 Inserting new message into database');
                  // Update local database with new message
                  await _dbHelper.insertMessage({
                    'group_id': message['room_id'].toString(), // Ensure it's a string
                    'sender_id': message['sender_id']?.toString() ?? _userId,
                    'message': message['content'] ?? '',
                    'timestamp': message['timestamp'] ?? DateTime.now().toIso8601String(),
                    'type': message['message_type'] ?? 'text',
                    'isMe': 0,
                    'status': 'unread', // Add required status field
                  });
                  print('🔵 Message inserted successfully');
                  
                  // Immediately reload chats to update UI
                  print('🔵 Reloading chats to update UI');
                  await _loadChats();
                  print('🔵 Chats reloaded');
                } else {
                  print('🔴 Error: Message data is null');
                }
              }   else {
                print('🔵 Unknown message type received: ${response['type']}');
                print('🔵 Full message content: $response');
              }
            } catch (e, stackTrace) {
              print('🔴 Error processing WebSocket message: $e');
              print('🔴 Stack trace: $stackTrace');
            }
          },
          onError: (error, stackTrace) {
            print('🔴 WebSocket error: $error');
            print('🔴 Stack trace: $stackTrace');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Connection error: $error')),
              );
            }
            _attemptReconnect();
          },
          onDone: () {
            print('🔵 WebSocket connection closed');
            _attemptReconnect();
          },
        );

      } catch (e) {
        print('🔴 Error establishing WebSocket connection: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to establish connection: $e')),
          );
        }
        _attemptReconnect();
      }
    } catch (e) {
      print('🔴 Error in _initializeWebSocket: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: $e')),
        );
      }
      _attemptReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void _attemptReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      print('🔴 Max reconnection attempts reached');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection lost. Please restart the app.')),
        );
      }
      return;
    }

    _reconnectAttempts++;
    print('🔵 Attempting to reconnect (attempt $_reconnectAttempts of $maxReconnectAttempts)...');
    
    // Exponential backoff for reconnection attempts
    final delay = Duration(seconds: min(30, pow(2, _reconnectAttempts).toInt()));
    Future.delayed(delay, () {
      if (mounted && !_isConnecting) {
        print('🔵 Initiating reconnection after ${delay.inSeconds} seconds...');
        _initializeWebSocket();
      }
    });
  }

  Future<void> processGroupData(Map<String, dynamic> response) async {
    if (!response.containsKey('success') || !response['success']) {
      throw Exception(
          'API request failed: ${response['message'] ?? 'Unknown error'}');
    }

    if (!response.containsKey('data') || response['data'] is! List) {
      throw Exception('Invalid data format in response');
    }

    final db = await _dbHelper.database;
    final groups = List<Map<String, dynamic>>.from(response['data']);

    // Handle deletions
    final localGroups = await db.query('groups', columns: ['id']);
    final localGroupIds = localGroups.map((g) => g['id'].toString()).toSet();
    final apiGroupIds = groups.map((g) => g['groupId'].toString()).toSet();
    final groupsToDelete = localGroupIds.difference(apiGroupIds);

    for (final groupId in groupsToDelete) {
      await db
          .delete('participants', where: 'group_id = ?', whereArgs: [groupId]);
      await db.delete('groups', where: 'id = ?', whereArgs: [groupId]);
    }

    // Variables to hold categorized results
    List<Map<String, dynamic>> adminGroups = [];
    int totalPending = 0;
    List<Map<String, dynamic>> pendingAdminLoans = [];
    List<Map<String, dynamic>> pendingUserLoans = [];
    List<Map<String, dynamic>> pendingWithdraw = [];
    List<Map<String, dynamic>> ongoingUserLoans = [];

    for (final groupData in groups) {
      try {
        final groupId = groupData['groupId']?.toString();
        if (groupId == null || groupId.isEmpty) {
          continue;
        }

        // Process group data with null checks
        final messageRestriction =
            groupData['restrict_messages_to_admins'] as bool? ?? false;
        final groupName = groupData['name'] as String? ?? 'Unnamed Group';
        final groupDescription = groupData['description'] as String? ?? '';
        final profilePic = groupData['profile_pic'] != null
            ? '${ApiEndpoints.server}${groupData['profile_pic']}'
            : '';
        final createdAt = groupData['created_at'] as String? ??
            DateTime.now().toIso8601String();
        final createdBy = groupData['created_by'] as String? ?? 'unknown';
        final lastActivity = groupData['last_activity'] as String? ?? createdAt;
        final participants = groupData['participants'] as List<dynamic>? ?? [];

        final allowsSubscription =
            groupData['allows_subscription'] as bool? ?? false;
        final hasUserPaid = groupData['has_user_paid'] as bool? ?? false;
        final subscriptionAmount =
            (groupData['subscription_amount'] as num?)?.toDouble() ?? 0.0;

        bool isCurrentUserAdmin = false;
        int pendingCount = 0;

        // Process participants
        final existingParticipants = await db.query(
          'participants',
          where: 'group_id = ?',
          whereArgs: [groupId],
          columns: ['user_id'],
        );
        final existingParticipantIds =
            existingParticipants.map((p) => p['user_id'].toString()).toSet();

        final apiParticipantIds = <String>{};
        for (final participantData in participants) {
          try {
            if (participantData is! Map<String, dynamic>) {
              continue;
            }

            final participantUserId = participantData['user_id']?.toString();
            if (participantUserId == null) continue;

            apiParticipantIds.add(participantUserId);

            // Check if current user is admin
            if (participantUserId == _userId) {
              final role = participantData['role'] as String?;
              final isAdminDynamic = participantData['is_admin'] ?? false;
              isCurrentUserAdmin = (role == 'admin' || isAdminDynamic == true);
            }

            // Count pending requests for admins
            final isApproved = participantData['is_approved'] is bool
                ? participantData['is_approved'] as bool
                : participantData['is_approved'] == 1;
            final isDenied = participantData['is_denied'] is bool
                ? participantData['is_denied'] as bool
                : participantData['is_denied'] == 1;
            final role = participantData['role'] as String?;
            final isAdminDynamic = participantData['is_admin'] ?? false;

            if (!isApproved &&
                !isDenied &&
                !(role == 'admin' || isAdminDynamic == true)) {
              pendingCount++;
            }

            // Prepare participant data for storage
            final participantDataToStore = {
              'group_id': groupId,
              'user_id': participantUserId,
              'user_name': participantData['user_name'] as String? ?? 'Unknown',
              'role': role ?? 'member',
              'joined_at': participantData['joined_at'] as String? ??
                  DateTime.now().toIso8601String(),
              'muted': participantData['muted'] is bool
                  ? (participantData['muted'] as bool ? 1 : 0)
                  : participantData['muted'] as int? ?? 0,
              'is_admin': (role == 'admin' || isAdminDynamic == true) ? 1 : 0,
              'is_approved': isApproved ? 1 : 0,
              'is_denied': isDenied ? 1 : 0,
              'is_removed': 0,
            };

            // Update or insert participant
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
          } catch (e) {
            print('Error processing participant: $e');
          }
        }

        // Delete participants that no longer exist
        final participantsToDelete =
            existingParticipantIds.difference(apiParticipantIds);
        for (final participantId in participantsToDelete) {
          await db.delete(
            'participants',
            where: 'group_id = ? AND user_id = ?',
            whereArgs: [groupId, participantId],
          );
        }

        // Process loans
        final pendingLoans =
            (groupData['pending_loan_requests'] as List<dynamic>? ?? [])
                .cast<Map<String, dynamic>>();
        final userPendingLoans =
            (groupData['user_pending_loans'] as List<dynamic>? ?? []);
        final adminPendingWithdraws =
            (groupData['pending_withdraw_requests'] as List<dynamic>? ?? [])
                .cast<Map<String, dynamic>>();

        final userActiveLoans =
            (groupData['user_active_loans'] as List<dynamic>? ?? [])
                .cast<Map<String, dynamic>>();

        // Add pending admin loans (only for admins)
        if (isCurrentUserAdmin) {
          for (final loan in pendingLoans) {
            pendingAdminLoans.add({
              'group_id': groupId,
              'group_name': groupName,
              'loan_id': loan['loan_id']?.toString(),
              'full_name': loan['full_name'] as String?,
              'total_savings': (loan['total_savings'] as num?)?.toDouble(),
              'amount': (loan['amount'] as num?)?.toDouble(),
              'payback': (loan['payback'] as num?)?.toDouble(),
              'repayment_period': loan['repayment_period'] as int?,
              'created_at': loan['created_at'] as String?,
            });
          }
        }

        // Add user pending and active loans
        for (final loan in userPendingLoans) {
          pendingUserLoans.add({
            'group_id': groupId,
            'group_name': groupName,
            'loan_id': loan['loan_id']?.toString(),
            'amount': (loan['amount'] as num?)?.toDouble(),
            'payback': (loan['payback'] as num?)?.toDouble(),
            'repayment_period': loan['repayment_period'] as int?,
            'created_at': loan['created_at'] as String?,
          });
        }
        for (final withdraw in adminPendingWithdraws) {
          pendingWithdraw.add({
            'group_id': groupId,
            'group_name': groupName,
            'withdraw_id': withdraw['withdraw_id']?.toString(),
            'amount': (withdraw['amount'] as num?)?.toDouble(),
            'full_name': withdraw['full_name'] as String?,
            'total_savings': (withdraw['total_savings'] as num?)?.toDouble(),
            'created_at': withdraw['created_at'] as String?,
          });
        }
        for (final loan in userActiveLoans) {
          ongoingUserLoans.add({
            'group_id': groupId,
            'group_name': groupName,
            'loan_id': loan['loan_id']?.toString(),
            'amount': (loan['amount'] as num?)?.toDouble(),
            'payback': (loan['payback'] as num?)?.toDouble(),
            'amount_paid': (loan['amount_paid'] as num?)?.toDouble() ?? 0.0,
            'repayment_period': loan['repayment_period'] as int?,
            'outstanding_balance':
                (loan['outstanding_balance'] as num?)?.toDouble() ?? 0.0,
            'created_at': loan['created_at'] as String?,
          });
        }

        // Prepare group data for storage
        final groupDataToStore = {
          'id': groupId,
          'name': groupName,
          'amAdmin': isCurrentUserAdmin ? 1 : 0,
          'description': groupDescription,
          'profile_pic': profilePic,
          'type': 'group',
          'created_at': createdAt,
          'created_by': createdBy,
          'last_activity': lastActivity,
          'subscription_amount': subscriptionAmount,
          'deposit_amount':
              (groupData['deposit_amount'] as num?)?.toDouble() ?? 0.0,
          'restrict_messages_to_admins': messageRestriction ? 1 : 0,
          'allows_subscription': allowsSubscription ? 1 : 0,
          'has_user_paid': hasUserPaid ? 1 : 0,
        };

        // Update or insert group
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

        // Track admin groups with pending requests
        if (isCurrentUserAdmin && pendingCount > 0) {
          totalPending += pendingCount;
          adminGroups.add({
            'group_id': groupId,
            'group_name': groupName,
            'pending_count': pendingCount,
          });
        }
      } catch (e) {
        print('Error processing group ${groupData['groupId']}: $e');
      }
    }

    setState(() {
      _pendingRequestCount = adminGroups.fold(
          0, (sum, group) => sum + (group['pending_count'] as int));
      _adminGroups = adminGroups;
      _pendingAdminLoans = pendingAdminLoans;
      _pendingUserLoans = pendingUserLoans;
      _pendingWithdraw = pendingWithdraw;
      _ongoingUserLoans = ongoingUserLoans;
    });

    _reloadChats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SearchAndHeaderComponent(
            pendingRequestCount: _pendingRequestCount,
            adminGroups: _adminGroups,
            searchController: _searchController,
            fadeAnimation: _fadeAnimation,
            onFilterChats: _filterChats,
            onReloadChats: _reloadChats,
            pendingAdminLoans: _pendingAdminLoans,
            pendingUserLoans: _pendingUserLoans,
            ongoingUserLoans: _ongoingUserLoans,
            pendingWithdraw: _pendingWithdraw,
          ),
          Expanded(
            child: ChatListComponent(
              allChats: _allChats,
              filteredChats: _filteredChats,
              onReloadChats: _reloadChats,
              refreshStream: _refreshController.stream,
              loadChats: _loadChats,
              toSentenceCase: _toSentenceCase,
              markMessagesAsRead: _markMessagesAsRead,
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

  void _filterChats(String query) {
    setState(() {
      _filteredChats = _allChats
          .where((chat) =>
              chat["name"].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<List<Map<String, dynamic>>> _loadChats() async {
    final groups = await _dbHelper.getGroups();
    List<Map<String, dynamic>> chats = [];

    for (var group in groups) {
      final isApproved = await _isUserApproved(group['id']);
      if (!isApproved) {
        continue;
      }

      // Get the latest message for this group
      final groupMessages = await _dbHelper.getMessages(
        groupId: group['id'],
        limit: 1,
      );

      final lastMessage = groupMessages.isNotEmpty ? groupMessages.first : null;
      
      // Count unread messages directly
      final unreadMessages = await _dbHelper.getMessages(
        groupId: group['id'],
      );
      final unreadCount = unreadMessages.where((m) => 
        m['isMe'] == 0 && m['status'] == 'unread'
      ).length;

      Widget lastMessagePreview = const Text(
        "No messages yet",
        style: TextStyle(color: Colors.grey),
      );

      if (lastMessage != null) {
        final messageType = lastMessage['type'] as String? ?? 'text';
        final messageText = lastMessage['message'] as String? ?? '';

        switch (messageType) {
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
                  _truncateMessage(messageText),
                  style: const TextStyle(
                      color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ],
            );
            break;
          default:
            lastMessagePreview = Text(
              _truncateMessage(messageText),
              style: const TextStyle(color: Colors.grey),
            );
            break;
        }
      }

      // Use the message timestamp if available, otherwise use group creation time
      final timestamp = lastMessage != null
          ? lastMessage['timestamp'] as String? ??
              DateTime.now().toIso8601String()
          : group['created_at'] as String? ?? DateTime.now().toIso8601String();

      chats.add({
        'id': group['id'],
        'name': _toSentenceCase(group['name'] as String? ?? ''),
        'description': group['description'] as String? ?? '',
        'profilePic': group['profile_pic'] as String? ?? '',
        'lastMessage': lastMessagePreview,
        'time': lastMessage != null
            ? _formatTime(lastMessage['timestamp'] as String? ??
                DateTime.now().toIso8601String())
            : 'Just now',
        'timestamp': timestamp,
        'unreadCount': unreadCount,
        'isGroup': true,
        'hasMessages': lastMessage != null,
        'restrict_messages_to_admins':
            group['restrict_messages_to_admins'] == 1,
        'amAdmin': group['amAdmin'] == 1,
        'allows_subscription': group['allows_subscription'] == 1,
        'has_user_paid': group['has_user_paid'] == 1,
        'subscription_amount': _parseDouble(group['subscription_amount']),
      });
    }

    // Sort chats by timestamp, most recent first
    chats.sort((a, b) {
      final DateTime timeA = DateTime.parse(a['timestamp']);
      final DateTime timeB = DateTime.parse(b['timestamp']);
      return timeB.compareTo(timeA); // Descending order (most recent first)
    });

    // Update state with new chat list
    if (mounted) {
      setState(() {
        _allChats = chats;
        _filteredChats = chats; // Reset filtered chats to include new messages
      });
    }
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

  String _toSentenceCase(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
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

  // Update the markMessagesAsRead method to just update message status
  Future<void> _markMessagesAsRead(String groupId) async {
    try {
      print('🔵 Marking messages as read for group: $groupId');
      final db = await _dbHelper.database;
      
      // Update all unread messages for this group
      print('🔵 Updating messages to read status');
      await db.update(
        'messages',
        {'status': 'read'},
        where: 'group_id = ? AND isMe = 0 AND status = ?',
        whereArgs: [groupId, 'unread'],
      );
      print('🔵 Messages marked as read successfully');
      
      // Reload chats to update UI
      print('🔵 Reloading chats to update UI');
      await _loadChats();
      print('🔵 Chats reloaded');
    } catch (e, stackTrace) {
      print('🔴 Error marking messages as read: $e');
      print('🔴 Stack trace: $stackTrace');
    }
  }
}

// Component for Chat List
class ChatListComponent extends StatefulWidget {
  final List<Map<String, dynamic>> allChats;
  final List<Map<String, dynamic>> filteredChats;
  final VoidCallback onReloadChats;
  final Stream<void> refreshStream;
  final Future<List<Map<String, dynamic>>> Function() loadChats;
  final String Function(String) toSentenceCase;
  final Future<void> Function(String) markMessagesAsRead;

  const ChatListComponent({
    Key? key,
    required this.allChats,
    required this.filteredChats,
    required this.onReloadChats,
    required this.refreshStream,
    required this.loadChats,
    required this.toSentenceCase,
    required this.markMessagesAsRead,
  }) : super(key: key);

  @override
  State<ChatListComponent> createState() => _ChatListComponentState();
}

class _ChatListComponentState extends State<ChatListComponent> with TickerProviderStateMixin {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Map<String, dynamic>> _displayChats = [];
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _displayChats = widget.filteredChats.isEmpty && widget.allChats.isNotEmpty
        ? List.from(widget.allChats)
        : List.from(widget.filteredChats);
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatListComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final newDisplayChats = widget.filteredChats.isEmpty && widget.allChats.isNotEmpty
        ? widget.allChats
        : widget.filteredChats;

    // Handle removals
    for (int i = _displayChats.length - 1; i >= 0; i--) {
      final oldChat = _displayChats[i];
      if (!newDisplayChats.any((chat) => chat['id'] == oldChat['id'])) {
        _displayChats.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => _buildAnimatedItem(oldChat, animation),
          duration: const Duration(milliseconds: 300),
        );
      }
    }

    // Handle additions and updates
    for (int i = 0; i < newDisplayChats.length; i++) {
      final newChat = newDisplayChats[i];
      final oldIndex = _displayChats.indexWhere((chat) => chat['id'] == newChat['id']);
      
      if (oldIndex == -1) {
        // New item
        _displayChats.insert(i, newChat);
        _listKey.currentState?.insertItem(i, duration: const Duration(milliseconds: 300));
      } else if (oldIndex != i || _displayChats[oldIndex]['timestamp'] != newChat['timestamp']) {
        // Item moved or updated
        _displayChats.removeAt(oldIndex);
        _displayChats.insert(i, newChat);
        _listKey.currentState?.removeItem(
          oldIndex,
          (context, animation) => _buildAnimatedItem(_displayChats[oldIndex], animation),
          duration: const Duration(milliseconds: 300),
        );
        _listKey.currentState?.insertItem(i, duration: const Duration(milliseconds: 300));
      }
    }
  }

  Widget _buildAnimatedItem(Map<String, dynamic> chat, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: _buildChatItem(chat),
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat) {
    final chatId = chat['id'].toString();
    final hasUnreadMessages = chat["unreadCount"] > 0;

    return Container(
      key: ValueKey('chat_${chatId}_${chat['timestamp']}'),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            // Mark messages as read before navigating
            await widget.markMessagesAsRead(chatId);
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return MessageChatScreen(
                    name: chat["name"],
                    isAdminOnlyMode: chat["restrict_messages_to_admins"],
                    isCurrentUserAdmin: chat["amAdmin"],
                    description: chat["description"] ?? 'Our Saving Group',
                    profilePic: chat["profilePic"],
                    groupId: chat["isGroup"] ? chat["id"] : null,
                    onMessageSent: widget.onReloadChats,
                    allowSubscription: chat["allows_subscription"],
                    hasUserPaid: chat["has_user_paid"],
                    subscriptionAmount: chat["subscription_amount"].toString(),
                  );
                },
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  children: [
                    _getAvatar(chat["name"], chat["profilePic"], chat["isGroup"]),
                    if (hasUnreadMessages)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text(
                            chat["unreadCount"].toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              chat["name"],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            chat["time"],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: chat["lastMessage"],
                          ),
                          if (hasUnreadMessages)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getAvatar(String name, String? profilePic, bool isGroup) {
    if (profilePic != null && profilePic.isNotEmpty) {
      return Hero(
        tag: 'avatar_${name}_${DateTime.now().millisecondsSinceEpoch}',
        child: CircleAvatar(
          radius: 30,
          backgroundImage: CachedNetworkImageProvider(profilePic),
          onBackgroundImageError: (exception, stackTrace) {},
        ),
      );
    }

    if (isGroup) {
      final initials = name.isNotEmpty ? name[0].toUpperCase() : 'G';
      return Hero(
        tag: 'avatar_${name}_${DateTime.now().millisecondsSinceEpoch}',
        child: CircleAvatar(
          radius: 30,
          backgroundColor: primaryColor,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: widget.refreshStream,
      builder: (context, snapshot) {
        if (_displayChats.isEmpty) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryTwo.withOpacity(0.1),
                    ),
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
                  const SizedBox(height: 24),
                  const Text(
                    "Welcome to Saving Groups",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryTwo,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      "Create or join a group to start saving and investing with friends and family",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
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
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTwo,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return AnimatedList(
          key: _listKey,
          initialItemCount: _displayChats.length,
          itemBuilder: (context, index, animation) {
            return _buildAnimatedItem(_displayChats[index], animation);
          },
        );
      },
    );
  }
}
