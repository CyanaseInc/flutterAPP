import 'package:cyanase/helpers/loader.dart';
import 'package:cyanase/helpers/pay_subscriptions.dart';
import 'package:cyanase/screens/auth/login_with_phone.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/get_currency.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cyanase/helpers/endpoints.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';

class GroupInviteScreen extends StatefulWidget {
  final int groupId;
  final String? inviteCode;

  const GroupInviteScreen({
    super.key,
    required this.groupId,
    this.inviteCode,
  });

  @override
  _GroupInviteScreenState createState() => _GroupInviteScreenState();
}

class _GroupInviteScreenState extends State<GroupInviteScreen> {
  bool _isLoading = true;
  bool _isJoining = false;
  Map<String, dynamic> _groupDetails = {};
  String _currencySymbol = '\$';
  String _totalBalance = '0.00';
  String _groupInitials = '';
  String _groupName = 'Group Name';
  String _description = 'Group description goes here';
  String? _profilePic;
  int _memberCount = 0;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _hasPaid = false;

  @override
  void initState() {
    super.initState();
    _fetchGroupDetails();
  }

  Future<void> _fetchGroupDetails() async {
    setState(() => _isLoading = true);

    try {
      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);

      if (userProfile.isEmpty || userProfile.first['token'] == null) {
        throw Exception('User profile or token not found');
      }

      final token = userProfile.first['token'] as String;
      final userCountry = userProfile.first['country'] as String? ?? 'US';
      final currency = CurrencyHelper.getCurrencyCode(userCountry);

      final response = await ApiService.getGroupDetailsNonUser(
        token: token,
        groupId: widget.groupId,
      );

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>? ?? {};
        final createdBy = data['created_by'] as Map<String, dynamic>? ?? {};

        setState(() {
          _currencySymbol = currency;
          _groupDetails = Map<String, dynamic>.from(data);
          _groupName = data['group_name'] as String? ?? 'Group Name';
          _description = data['group_description'] as String? ??
              'Group description goes here';
          _profilePic = data['profile_pic'] as String?;
          final membersMap = _totalBalance = _formatCurrency(
              (createdBy['group_total'] as num?)?.toDouble() ?? 0.0);
          _memberCount = data['members']?['total_count'] ?? 0;

          _groupInitials = _getInitials(_groupName);
          _isLoading = false;
        });
      } else {
        throw Exception(
            response['message'] as String? ?? 'Failed to load group details');
      }
    } catch (e) {
      print('Error fetching group details: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load group details: $e')),
        );
      }
      setState(() {
        _isLoading = false;
        _groupDetails = {};
        _groupName = 'Group Name';
        _description = 'Group description goes here';
        _profilePic = null;
        _memberCount = 0;
        _totalBalance = _formatCurrency(0.0);
        _groupInitials = 'GN';
      });
    }
  }

  String _formatCurrency(double amount) {
    return '$_currencySymbol ${amount.toStringAsFixed(2)}';
  }

  static String _getInitials(String name) {
    return name
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0] : '')
        .take(2)
        .join()
        .toUpperCase();
  }

  Widget _getAvatar(String name, String? profilePic) {
    final avatarUrl = profilePic != null && profilePic.isNotEmpty
        ? '${ApiEndpoints.server}/media/$profilePic'
        : null;

    if (avatarUrl != null) {
      return CircleAvatar(
        radius: 30,
        backgroundImage: CachedNetworkImageProvider(avatarUrl),
        onBackgroundImageError: (exception, stackTrace) {},
      );
    }

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
  }

  @override
  Widget build(BuildContext context) {
    final double avatarRadius = MediaQuery.of(context).size.width * 0.15;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Group Invitation',
          style: TextStyle(fontSize: 20, color: white),
        ),
        backgroundColor: primaryTwo,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios, color: white), // White back icon
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: Loader())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        SizedBox(
                          width: avatarRadius * 2,
                          height: avatarRadius * 2,
                          child: _getAvatar(_groupName, _profilePic),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _groupName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$_totalBalance • $_memberCount members',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 16.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTwo,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: _isJoining || _isLoading
                          ? null
                          : () => _joinGroup(context, widget.groupId),
                      child: _isJoining
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Loader(),
                            )
                          : const Text(
                              'Join Group',
                              style: TextStyle(
                                fontSize: 15,
                                color: primaryColor,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _joinGroup(BuildContext context, int groupId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Group'),
        content: Text(
            'Request to join "$_groupName"? You will be added once approved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initiateJoinProcess(context, groupId);
            },
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  Future<void> _initiateJoinProcess(BuildContext context, int groupId) async {
    if (_isJoining) return;

    try {
      final canJoin = await _validatePayment(context, groupId);
      if (!canJoin) {
        return;
      }
      setState(() => _isJoining = true);
      await _requestToJoin(context, groupId);
    } catch (e) {
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join group: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  Future<bool> _validatePayment(BuildContext context, int groupId) async {
    final requiresPayment =
        _groupDetails['requirePaymentToJoin'] as bool? ?? false;
    final paymentAmount = _groupDetails['pay_amount'] as double? ?? 0.0;

    if (!requiresPayment || _hasPaid) {
      print('No payment needed');
      return true;
    }

    return await _showPaymentBottomSheet(
        context, groupId, paymentAmount > 0 ? paymentAmount : 0.01);
  }

  Future<bool> _showPaymentBottomSheet(
      BuildContext context, int groupId, double paymentAmount) async {
    bool paymentSuccessful = false;

    // Show initial confirmation bottom sheet
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Payment Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: primaryTwo,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Joining $_groupName requires a one-time payment of $_currencySymbol${paymentAmount.toStringAsFixed(2)}.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTwo,
                      foregroundColor: white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      elevation: 2,
                    ),
                    onPressed: () async {
                      Navigator.pop(context); // Close confirmation sheet
                      // Show PayHelper bottom sheet
                      paymentSuccessful = await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => DraggableScrollableSheet(
                          initialChildSize: 0.6,
                          minChildSize: 0.4,
                          maxChildSize: 0.9,
                          expand: false,
                          builder: (context, scrollController) =>
                              SingleChildScrollView(
                            controller: scrollController,
                            child: PayHelper(
                              amount: paymentAmount.toStringAsFixed(2),
                              groupId: groupId,
                              onBack: () => Navigator.pop(context),
                              paymentType: 'group_join_pay',
                              userId: 'self', // Fetch dynamically if needed
                              onPaymentSuccess: () async {
                                setState(() => _hasPaid = true);
                                Navigator.pop(
                                    context); // Close payment bottom sheet
                                await _initiateJoinProcess(
                                    context, groupId); // Auto-join
                              },
                            ),
                          ),
                        ),
                      ).then((value) => value ?? false);
                    },
                    child: const Text(
                      'Pay and Join',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    return paymentSuccessful;
  }

  Future<void> _requestToJoin(BuildContext context, int groupId) async {
    try {
      if (!context.mounted) {
        throw Exception('Context not mounted');
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: Loader()),
      );

      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);

      if (userProfile.isEmpty || userProfile.first['token'] == null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(),
          ),
        );
      }
      final token = userProfile.first['token'] as String;
      final userId = userProfile.first['user_id'] as String? ?? 'self';
      final userName = userProfile.first['name'] as String? ?? 'User';

      final joinData = {
        'groupid': widget.groupId.toString(),
        'participants': [
          {
            'user_id': userId,
            'role': 'member',
            'invite_code': widget.inviteCode ?? '',
          }
        ]
      };

      final response = await ApiService.addMembers(token, joinData)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Join request timed out');
      });

      if (!response['success']) {
        throw Exception(
            response['message'] as String? ?? 'Failed to request join');
      }

      await db.insert(
          'groups',
          {
            'id': widget.groupId,
            'name': _groupName,
            'description': _description,
            'profile_pic': _profilePic ?? '',
            'type': 'group',
            'created_at': DateTime.now().toIso8601String(),
            'created_by': 'unknown',
            'last_activity': DateTime.now().toIso8601String(),
            'settings': '',
          },
          conflictAlgorithm: ConflictAlgorithm.replace);

      await db.insert(
          'participants',
          {
            'group_id': widget.groupId,
            'user_id': userId,
            'role': 'member',
            'joined_at': DateTime.now().toIso8601String(),
            'muted': 0,
            'is_approved': 0,
            'is_denied': 0,
            'user_name': userName,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);

      await _dbHelper.insertNotification(
        groupId: widget.groupId,
        message: "$userName has joined the group",
        senderId: 'system',
      );

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Request to join $_groupName sent. Awaiting admin approval.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join group: $e')),
        );
      }
    }
  }
}
