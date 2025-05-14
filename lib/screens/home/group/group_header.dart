import 'package:cyanase/helpers/loader.dart';
import 'package:flutter/material.dart';
import 'get_group_loan.dart';
import 'group_deposit_info_button.dart';
import 'group_withdraw.dart';
import 'package:cyanase/theme/theme.dart';
import 'dart:io';
import 'change_group_name.dart';
import 'package:image_picker/image_picker.dart';
import 'add_member.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GroupHeader extends StatefulWidget {
  final String groupName;
  final String profilePic;
  final int groupId;
  final String description;
  final String totalBalance;
  final String myContributions;
  final Map<String, dynamic> initialLoanSettings;

  const GroupHeader({
    Key? key,
    required this.groupName,
    required this.description,
    required this.profilePic,
    required this.groupId,
    required this.totalBalance,
    required this.myContributions,
    required this.initialLoanSettings,
  }) : super(key: key);

  @override
  _GroupHeaderState createState() => _GroupHeaderState();
}

class _GroupHeaderState extends State<GroupHeader> {
  File? _profilePicFile;
  bool _isLoading = false;
  String? _currentProfilePicUrl;
  bool _allowLoan = false;

  @override
  void initState() {
    super.initState();
    _currentProfilePicUrl = widget.profilePic;

    // Access allow_loans (note the plural)
    try {
      _allowLoan = widget.initialLoanSettings['allow_loans'] ?? false;
    } catch (e) {
      debugPrint('Error accessing initialLoanSettings: $e');
      _allowLoan = false;
    }
  }

  void _updateProfilePic(File image) {
    setState(() {
      _profilePicFile = image;
    });
  }

  void _showProfilePicOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _editProfilePic();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Remove Image'),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfilePic();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editProfilePic() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final dbHelper = DatabaseHelper();
        final db = await dbHelper.database;
        final userProfile = await db.query('profile', limit: 1);

        if (userProfile.isEmpty) {
          throw Exception('User profile not found');
        }

        final token = userProfile.first['token'] as String;

        final response = await ApiService.updateGroupProfilePic(
          token: token,
          groupId: widget.groupId,
          imageFile: File(image.path),
        );

        if (response['success'] == true) {
          setState(() {
            _currentProfilePicUrl = response['newProfilePicUrl'];
            _profilePicFile = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Profile picture updated successfully')),
          );
        } else {
          throw Exception(
              response['message'] ?? 'Failed to update profile picture');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile picture: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeProfilePic() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);

      if (userProfile.isEmpty) {
        throw Exception('User profile not found');
      }

      final token = userProfile.first['token'] as String;

      final response = await ApiService.deleteGroupProfilePic(
        token: token,
        groupId: widget.groupId,
      );

      if (response['success'] == true) {
        setState(() {
          _currentProfilePicUrl = null;
          _profilePicFile = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture removed successfully')),
        );
      } else {
        throw Exception(
            response['message'] ?? 'Failed to remove profile picture');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove profile picture: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showBalanceOptionsMenu(BuildContext context) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
      items: [
        const PopupMenuItem(
          value: 'Withdraw',
          child: Text('Withdraw'),
        ),
        const PopupMenuItem(
          value: 'Add Interest',
          child: Text('Add Interest'),
        ),
      ],
    ).then((value) {
      if (value != null) {
        if (value == 'Withdraw') {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Withdraw Funds'),
                content: SingleChildScrollView(
                  child: WithdrawButton(),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Close'),
                  ),
                ],
              );
            },
          );
        } else if (value == 'Add Interest') {
          // Handle add interest action here
        }
      }
    });
  }

  void _showLoansNotAllowedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Loans Not Allowed'),
          content: const Text('Loans are not allowed in this group.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Loader(),
      );
    }

    return Container(
      width: double.infinity,
      color: white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.groupName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: _showProfilePicOptions,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: _profilePicFile != null
                          ? FileImage(_profilePicFile!)
                          : (_currentProfilePicUrl != null &&
                                  _currentProfilePicUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(
                                  _currentProfilePicUrl!)
                              : const AssetImage('assets/avatar.png')
                                  as ImageProvider),
                      onBackgroundImageError: (exception, stackTrace) {
                        debugPrint(
                            "Failed to load profile picture: $exception");
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'Add Members') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddGroupMembersScreen(
                              groupId: widget.groupId,
                            ),
                          ),
                        );
                      } else if (value == 'Change Group Name') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChangeGroupNameScreen(
                              groupId: widget.groupId,
                            ),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'Add Members',
                        child: Text('Add Members'),
                      ),
                      const PopupMenuItem(
                        value: 'Change Group Name',
                        child: Text('Change Group Name'),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          'TOTAL BALANCE',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showBalanceOptionsMenu(context),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.totalBalance,
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'MY CONTRIBUTIONS',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  widget.myContributions,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryTwo,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.description,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              DepositButton(
                groupName: widget.groupName,
                profilePic: widget.profilePic,
                groupId: widget.groupId,
              ),
              _allowLoan
                  ? LoanButton(
                      groupId: widget.groupId,
                      loansettings: widget.initialLoanSettings)
                  : Opacity(
                      opacity: 0.5,
                      child: GestureDetector(
                        onTap: _showLoansNotAllowedDialog,
                        child: AbsorbPointer(
                          child: LoanButton(
                              groupId: widget.groupId,
                              loansettings: widget.initialLoanSettings),
                        ),
                      ),
                    ),
              WithdrawButton(),
            ],
          ),
        ],
      ),
    );
  }
}
