import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/database_helper.dart';

class GroupMembers extends StatefulWidget {
  final bool isGroup;
  final int? groupId;
  final String name;
  final String? profilePic;

  const GroupMembers({
    Key? key,
    required this.isGroup,
    this.groupId,
    required this.name,
    this.profilePic,
  }) : super(key: key);

  @override
  _GroupMembersState createState() => _GroupMembersState();
}

class _GroupMembersState extends State<GroupMembers> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, String>> _members = []; // List of members with names & roles

  @override
  void initState() {
    super.initState();
    _loadGroupMembers();
  }

  Future<void> _loadGroupMembers() async {
    if (widget.isGroup && widget.groupId != null) {
      try {
        final members = await _dbHelper.getGroupMemberNames(widget.groupId!);
        // Ensure the function returns List<Map<String, String>> containing "name" and "role"
        setState(() {
          _members = members;
        });
      } catch (e) {
        print("Error loading group members: $e");
      }
    } else {
      setState(() {
        _members = [
          {"name": widget.name, "role": "Member"}
        ];
      });
    }
  }

  void _updateMemberRole(int memberIndex, String newRole) async {
    try {
      // Update the role in the database
      await _dbHelper.updateMemberRole(
          widget.groupId!, _members[memberIndex]['name']!, newRole);

      // Update the UI
      setState(() {
        _members[memberIndex]['role'] = newRole;
      });
    } catch (e) {
      print("Error updating member role: $e");
    }
  }

  void _showRemoveMemberForm(BuildContext context, int memberIndex) {
    final _reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Member'),
          content: TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason for removal',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('Remove'),
              onPressed: () async {
                final reason = _reasonController.text;
                if (reason.isNotEmpty) {
                  try {
                    // Remove the member from the database
                    await _dbHelper.removeMember(widget.groupId!);

                    // Update the UI
                    setState(() {
                      _members.removeAt(memberIndex);
                    });

                    Navigator.pop(context);
                  } catch (e) {
                    print("Error removing member: $e");
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showMemberOptionsModal(BuildContext context, int memberIndex) {
    final currentRole = _members[memberIndex]['role']; // Get the current role

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Rounded corners
          ),
          elevation: 4, // Add slight shadow
          child: Container(
            padding: const EdgeInsets.all(16.0),
            width: 300, // Control the width of the modal
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Title
                const Text(
                  'Member Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16), // Space between title and content

                // Option 1: Make Admin or Remove Admin
                GestureDetector(
                  onTap: () {
                    if (currentRole != 'Admin') {
                      _updateMemberRole(memberIndex, 'Admin');
                    } else {
                      _showRemoveMemberForm(context, memberIndex);
                    }
                    Navigator.pop(context);
                  },
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.admin_panel_settings,
                        color:
                            currentRole != 'Admin' ? Colors.blue : Colors.red,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        currentRole != 'Admin'
                            ? 'Make Member Admin'
                            : 'Remove Admin',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12), // Space between options

                // Option 2: Make Secretary or Remove Secretary
                GestureDetector(
                  onTap: () {
                    if (currentRole != 'Secretary') {
                      _updateMemberRole(memberIndex, 'Secretary');
                    } else {
                      _showRemoveMemberForm(context, memberIndex);
                    }
                    Navigator.pop(context);
                  },
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.security,
                        color: currentRole != 'Secretary'
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        currentRole != 'Secretary'
                            ? 'Make Member Secretary'
                            : 'Remove Secretary',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12), // Space between options

                // Option 3: Remove from Group (always present)
                GestureDetector(
                  onTap: () {
                    _showRemoveMemberForm(context, memberIndex);
                    Navigator.pop(context);
                  },
                  child: Row(
                    children: const <Widget>[
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 10),
                      Text(
                        'Remove from Group',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// Helper widget to create modern looking option tiles

  @override
  Widget build(BuildContext context) {
    return Container(
      color: white,
      margin: const EdgeInsets.only(top: 8.0),
      child: ExpansionTile(
        title: const Text(
          'Members',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: _members.map((member) {
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: (widget.profilePic?.isNotEmpty == true)
                  ? NetworkImage(widget.profilePic!)
                  : const AssetImage('assets/images/avatar.png')
                      as ImageProvider,
              radius: 30,
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['name']!,
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Saving rank: ${_members.indexOf(member) + 1}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    _buildFinancialInfo(_members.indexOf(member)),
                  ],
                ),
                _buildRoleBreadcrumb(member['role'] ?? 'Member'),
              ],
            ),
            onTap: () {
              // Handle member tap to show options
              _showMemberOptionsModal(context, _members.indexOf(member));
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRoleBreadcrumb(String role) {
    role = role.trim();
    Color? backgroundColor;

    switch (role) {
      case 'Admin':
        backgroundColor = primaryColor;
        break;
      case 'Secretary':
        backgroundColor = Colors.grey;
        break;
      case 'Member':
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
        role,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: white,
        ),
      ),
    );
  }

  Widget _buildFinancialInfo(int index) {
    double loan = (index + 1) * 1000.0;
    double savings = (index + 1) * 2000.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (loan > 0)
          Text(
            'Loan: UGX ${loan.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 14, color: Colors.red),
          ),
        Text(
          'Savings: UGX ${savings.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 14, color: Colors.green),
        ),
      ],
    );
  }
}
