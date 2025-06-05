import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';
import 'package:cyanase/helpers/endpoints.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/chat_websocket_service.dart';
import 'package:cyanase/helpers/loader.dart';

class PendingRequestsScreen extends StatefulWidget {
  final int groupId;
  final String groupName;
  final VoidCallback onRequestProcessed;

  const PendingRequestsScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.onRequestProcessed,
  });

  @override
  _PendingRequestsScreenState createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String? _processingUserId;
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
    _fetchPendingRequests();
  }

  Future<void> _initializeWebSocket() async {
    try {
      print('Initializing WebSocket for group ${widget.groupId}');
      await ChatWebSocketService.instance.initialize(widget.groupId.toString());
      if (ChatWebSocketService.instance.isConnected) {
        print('WebSocket connected successfully');
      } else {
        print('WebSocket initialization failed');
      }
    } catch (e) {
      print('Error initializing WebSocket: $e');
    }
  }

  Future<void> _fetchPendingRequests() async {
    try {
      final db = await _dbHelper.database;

      final requests = await db.query(
        'participants',
        where: 'group_id = ? AND is_approved = ? AND is_denied = ?',
        whereArgs: [widget.groupId.toString(), 0, 0],
      );

      if (mounted) {
        setState(() {
          _pendingRequests = List<Map<String, dynamic>>.from(requests);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching pending requests: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _approveRequest(Map<String, dynamic> request) async {
    if (_processingUserId != null) return;

    final userId = request['user_id'].toString();
    setState(() => _processingUserId = userId);

    // Show loader
    _showLoader();

    // Optimistic update
    final originalRequests = List<Map<String, dynamic>>.from(_pendingRequests);
    
    setState(() {
      _pendingRequests.removeWhere((r) {
        final rUserId = r['user_id'].toString();
        return rUserId == userId;
      });
    });

    try {
      final db = await _dbHelper.database;

      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isEmpty || userProfile.first['token'] == null) {
        throw Exception('User profile or token not found');
      }

      final token = userProfile.first['token'] as String;
      final adminId = userProfile.first['id'] as String? ?? 'self';
    

      final approveData = {
        'groupid': widget.groupId.toString(),
        'user_id': userId,
        'role': 'member',
        'approved_by': adminId,
      };

      final response = await ApiService.approveRequest(token, approveData);

      if (!response['success']) {
        throw Exception(response['message'] ?? 'Failed to approve request');
      }

      final userName = request['user_name'] as String? ?? 'A user';

      // Insert notification in database
      await _dbHelper.insertNotification(
        groupId: widget.groupId,
        message: "$userName has joined the group",
        senderId:adminId,
      );

      // Send notification through WebSocket
      final wsMessage = {
        'type': 'send_message',
        'content': "$userName has joined the group",
        'sender_id': adminId,
        'group_id': widget.groupId.toString(),
        'room_id': widget.groupId.toString(),
        'message_type': 'notification',
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'sending',
      };

      try {
        await ChatWebSocketService.instance.sendMessage(wsMessage);
      } catch (e) {
        print('WebSocket send error: $e');
        // Queue message if WebSocket fails
        await _dbHelper.insertMessage({
          'group_id': widget.groupId.toString(),
          'sender_id': userId,
          'message': "$userName has joined the group",
          'type': 'notification',
          'timestamp': DateTime.now().toIso8601String(),
          'status': 'sending',
          'isMe': 0,
        });
      }

      // Notify parent
      widget.onRequestProcessed();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName approved!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error approving request: $e');
      setState(() {
        _pendingRequests = originalRequests;
        _processingUserId = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve request: $e')),
        );
      }
    } finally {
      // Hide loader
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  Future<void> _denyRequest(Map<String, dynamic> request) async {
    if (_processingUserId != null) return;

    final userId = request['user_id'].toString();
    setState(() => _processingUserId = userId);

    // Show loader
    _showLoader();

    final originalRequests = List<Map<String, dynamic>>.from(_pendingRequests);
    setState(() {
      _pendingRequests.removeWhere((r) {
        final rUserId = r['user_id'].toString();
        return rUserId == userId;
      });
    });

    try {
      final db = await _dbHelper.database;

      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isEmpty || userProfile.first['token'] == null) {
        throw Exception('User profile or token not found');
      }

      final token = userProfile.first['token'] as String;

      final denyData = {
        'groupid': widget.groupId.toString(),
        'user_id': userId,
      };

      debugPrint('Calling ApiService.denyRequest with data: $denyData');
      final response = await ApiService.denyRequest(token, denyData);
      debugPrint('ApiService.denyRequest response: $response');

      if (!response['success']) {
        throw Exception(response['message'] ?? 'Failed to deny request');
      }

      final userName = request['user_name'] as String? ?? 'A user';
 final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      // Insert notification in database
      await _dbHelper.insertNotification(
        groupId: widget.groupId,
        message: "$userName's request was denied",
        senderId: 'system',
      );

      // Send notification through WebSocket
      final wsMessage = {
        'type': 'send_message',
        'content': "$userName's request was denied",
        'sender_id': userId,
        'temp_id': tempId,
        'group_id': widget.groupId.toString(),
        'room_id': widget.groupId.toString(),
        'message_type': 'notification',
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'sending',
      };

      try {
        await ChatWebSocketService .instance.sendMessage(wsMessage);
      } catch (e) {
        print('WebSocket send error: $e');
        // Queue message if WebSocket fails
        await _dbHelper.insertMessage({
          'group_id': widget.groupId.toString(),
          'temp_id': tempId,
          'sender_id': userId,
          'message': "$userName's request was denied",
          'type': 'notification',
          'timestamp': DateTime.now().toIso8601String(),
          'status': 'sending',
          'isMe': 0,
        });
      }

      // Notify parent
      widget.onRequestProcessed();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName denied'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Deny error: $e');
      setState(() {
        _pendingRequests = originalRequests;
        debugPrint(
            'Reverted to original requests, length: ${_pendingRequests.length}');
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to deny: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingUserId = null);
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  void _showLoader() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Stack(
        children: [
          ModalBarrier(
            color: Colors.black.withOpacity(0.4),
            dismissible: false,
          ),
          const Center(
            child: Loader(
            
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmationDialog(
      BuildContext context, String action, String userName) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('$action $userName?'),
            content: Text('Are you sure you want to $action this request?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  action,
                  style: TextStyle(
                    color: action == 'Approve' ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildAvatar(String? profilePic, String name) {

  print('my mour $profilePic');
    final avatarUrl = profilePic != null && profilePic.isNotEmpty
        ? '${ApiEndpoints.server}/media/$profilePic'
        : null;

    return CircleAvatar(
      radius: 24,
      backgroundImage:
          avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
      child: avatarUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(fontSize: 20, color: white),
            )
          : null,
      backgroundColor: primaryColor,
    );
  }

  Widget _buildRequestItem(Map<String, dynamic> request) {
    final requestedAt = DateTime.parse(
        request['joined_at'] ?? DateTime.now().toIso8601String());
    final timeAgo = _formatTimeAgo(requestedAt);
    final isProcessing = _processingUserId == request['user_id'].toString();

    return Dismissible(
      key: Key(request['user_id'].toString()),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: const Icon(Icons.check, color: white),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.close, color: white),
      ),
      onDismissed: (direction) async {
        final confirmed = await _showConfirmationDialog(
          context,
          direction == DismissDirection.startToEnd ? 'Approve' : 'Deny',
          request['user_name'] ?? 'this request',
        );
        if (confirmed) {
          if (direction == DismissDirection.startToEnd) {
            await _approveRequest(request);
          } else {
            await _denyRequest(request);
          }
        } else {
          setState(() {
            _fetchPendingRequests();
          });
        }
      },
      confirmDismiss: (direction) => _showConfirmationDialog(
        context,
        direction == DismissDirection.startToEnd ? 'Approve' : 'Deny',
        request['user_name'] ?? 'this request',
      ),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAvatar(
                      request['profile_pic'], request['user_name'] ?? ''),
                  const SizedBox(height: 16),
                  Text(
                    request['user_name'] ?? 'Unknown',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text('Requested $timeAgo'),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: isProcessing
                            ? null
                            : () async {
                                final confirmed = await _showConfirmationDialog(
                                  context,
                                  'Approve',
                                  request['user_name'] ?? 'this request',
                                );
                                if (confirmed) {
                                  await _approveRequest(request);
                                  if (context.mounted) Navigator.pop(context);
                                }
                              },
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.close, color: Colors.white),
                        label: const Text('Deny'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: isProcessing
                            ? null
                            : () async {
                                final confirmed = await _showConfirmationDialog(
                                  context,
                                  'Deny',
                                  request['user_name'] ?? 'this request',
                                );
                                if (confirmed) {
                                  await _denyRequest(request);
                                  if (context.mounted) Navigator.pop(context);
                                }
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
        child: Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: _buildAvatar(
                  request['profile_pic'], request['user_name'] ?? ''),
              title: Text(
                request['user_name'] ?? 'Unknown',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
              subtitle: Text('Requested $timeAgo'),
              trailing: isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryTwo),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle,
                              color: Colors.green),
                          onPressed: () async {
                            final confirmed = await _showConfirmationDialog(
                              context,
                              'Approve',
                              request['user_name'] ?? 'this request',
                            );
                            if (confirmed) await _approveRequest(request);
                          },
                          tooltip: 'Approve',
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () async {
                            final confirmed = await _showConfirmationDialog(
                              context,
                              'Deny',
                              request['user_name'] ?? 'this request',
                            );
                            if (confirmed) await _denyRequest(request);
                          },
                          tooltip: 'Deny',
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        'Building PendingRequestsScreen, pendingRequests: ${_pendingRequests.length}');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pending Requests • ${widget.groupName}',
          style: const TextStyle(color: white, fontSize: 18),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: primaryTwo,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: white),
          onPressed: () => Navigator.pop(context),
        ),
        iconTheme: const IconThemeData(color: white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryTwo))
          : _pendingRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'assets/animations/empty.json',
                        width: 200,
                        height: 200,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No pending requests',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchPendingRequests,
                  color: primaryTwo,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _pendingRequests.length,
                    itemBuilder: (context, index) {
                     
                      return _buildRequestItem(_pendingRequests[index]);
                    },
                  ),
                ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  void dispose() {
    // No need to dispose ChatWebSocketService  as it's a singleton
    super.dispose();
  }
}