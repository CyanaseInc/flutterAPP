import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';

class GroupMembers extends StatefulWidget {
  final bool isGroup;
  final int? groupId;
  final String name;
  final String? profilePic;
  final List<Map<String, dynamic>> members;
  final String currencySymbol;

  const GroupMembers({
    Key? key,
    required this.isGroup,
    this.groupId,
    required this.name,
    this.profilePic,
    required this.members,
    this.currencySymbol = '',
  }) : super(key: key);

  @override
  _GroupMembersState createState() => _GroupMembersState();
}

class _GroupMembersState extends State<GroupMembers> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isNotEmpty) {
        final userId = userProfile.first['user_id'] as String?;
        final group = await db.query(
          'groups',
          where: 'id = ?',
          whereArgs: [widget.groupId],
          limit: 1,
        );
        if (group.isNotEmpty && group.first['amAdmin'] == 1) {
          setState(() {
            _isAdmin = true;
          });
        } else {
          final userParticipant = widget.members.firstWhere(
            (member) => member['user_id'] == userId,
            orElse: () => {'role': 'member'},
          );
          setState(() {
            _isAdmin = userParticipant['role'] == 'admin';
          });
        }
      }
    } catch (e) {
      print("Error checking admin status: $e");
    }
  }

  Future<void> _updateMemberRole(String userId, String newRole) async {
    try {
      // Verify user exists in members
      final member = widget.members.firstWhere(
        (m) => m['user_id'] == userId,
        orElse: () => throw Exception(
            'User $userId is not a member of group ${widget.groupId}'),
      );

      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isEmpty) {
        throw Exception('User not logged in');
      }
      final token = userProfile.first['token'] as String;

      final response = await ApiService.updateMemberRole(
        token: token,
        groupId: widget.groupId!,
        userId: userId,
        role: newRole,
      );

      if (response['success'] == true) {
        setState(() {
          final memberIndex =
              widget.members.indexWhere((m) => m['user_id'] == userId);
          if (memberIndex != -1) {
            widget.members[memberIndex]['role'] = newRole;
          }
        });
        // Update role in participants table
        await db.update(
          'participants',
          {'role': newRole},
          where: 'group_id = ? AND user_id = ?',
          whereArgs: [widget.groupId, userId],
        );

        print('Updated role for user $userId to $newRole');
      } else {
        throw Exception(response['message'] ?? 'Failed to update role');
      }
    } catch (e) {
      print("Error updating member role: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update role: $e')),
      );
    }
  }

  Future<void> _removeMember(String userId) async {
    try {
      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isEmpty) {
        throw Exception('User not logged in');
      }
      final token = userProfile.first['token'] as String;

      final response = await ApiService.removeMember(
        token: token,
        groupId: widget.groupId!,
        userId: userId,
      );

      if (response['success'] == true) {
        setState(() {
          widget.members.removeWhere((member) => member['user_id'] == userId);
        });
        await db.update(
          'participants',
          {'is_removed': 1},
          where: 'group_id = ? AND user_id = ?',
          whereArgs: [widget.groupId, userId],
        );
        print('Removed user $userId from group ${widget.groupId}');
      } else {
        throw Exception(response['message'] ?? 'Failed to remove member');
      }
    } catch (e) {
      print("Error removing member: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove member: $e')),
      );
    }
  }

  void _showRemoveMemberForm(BuildContext context, String userId) {
    final _reasonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: white,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Remove Member',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason for removal',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final reason = _reasonController.text;
                      if (reason.isNotEmpty) {
                        await _removeMember(userId);
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please provide a reason')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Remove',
                      style: TextStyle(color: white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMemberOptionsModal(
      BuildContext context, Map<String, dynamic> member) {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admins can modify member roles')),
      );
      return;
    }

    final userId = member['user_id'] as String;
    final currentRole = (member['role'] as String).toLowerCase();
    final memberName = member['full_name'] ?? 'Member';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$memberName',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildOptionTile(
                  context: context,
                  icon: Icons.admin_panel_settings,
                  color: currentRole != 'admin' ? Colors.blue : Colors.red,
                  label: currentRole != 'admin' ? 'Make Admin' : 'Remove Admin',
                  onTap: () {
                    _updateMemberRole(
                        userId, currentRole != 'admin' ? 'admin' : 'member');
                    Navigator.pop(context);
                  },
                ),
                _buildOptionTile(
                  context: context,
                  icon: Icons.security,
                  color: currentRole != 'secretary' ? Colors.green : Colors.red,
                  label: currentRole != 'secretary'
                      ? 'Make Secretary'
                      : 'Remove Secretary',
                  onTap: () {
                    _updateMemberRole(userId,
                        currentRole != 'secretary' ? 'secretary' : 'member');
                    Navigator.pop(context);
                  },
                ),
                _buildOptionTile(
                  context: context,
                  icon: Icons.delete,
                  color: Colors.red,
                  label: 'report and Remove from Group',
                  onTap: () {
                    Navigator.pop(context);
                    _showRemoveMemberForm(context, userId);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: ListTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        hoverColor: Colors.grey[200],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: white,
      margin: const EdgeInsets.only(top: 8.0),
      child: ExpansionTile(
        title: Text(
          'Members (${widget.members.length})',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: widget.members.map((member) {
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: (widget.profilePic?.isNotEmpty == true)
                  ? NetworkImage(widget.profilePic!)
                  : const AssetImage('assets/images/avatar.png')
                      as ImageProvider,
              radius: 20,
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['full_name'] ?? 'Unknown',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Rank: ${member['savings_rank'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    _buildFinancialInfo(member),
                  ],
                ),
                _buildRoleBreadcrumb(member['role'] ?? 'member'),
              ],
            ),
            onTap: () {
              _showMemberOptionsModal(context, member);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRoleBreadcrumb(String role) {
    role = role.trim().toLowerCase();
    Color? backgroundColor;

    switch (role) {
      case 'admin':
        backgroundColor = primaryColor;
        break;
      case 'secretary':
        backgroundColor = Colors.grey;
        break;
      case 'member':
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role[0].toUpperCase() + role.substring(1),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: white,
        ),
      ),
    );
  }

  Widget _buildFinancialInfo(Map<String, dynamic> member) {
    final deposits = (member['total_deposits'] as num?)?.toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          deposits != null && deposits > 0
              ? 'Savings: ${widget.currencySymbol}${deposits.toStringAsFixed(2)}'
              : 'Savings: None',
          style: const TextStyle(fontSize: 14, color: Colors.green),
        ),
      ],
    );
  }
}
