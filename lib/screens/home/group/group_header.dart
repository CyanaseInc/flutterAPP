import 'package:cyanase/helpers/deposit.dart';
import 'package:cyanase/helpers/loader.dart';
import 'package:cyanase/helpers/withdraw_helper.dart';
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
import 'package:intl/intl.dart';
import 'package:cyanase/helpers/endpoints.dart';

class GroupHeader extends StatefulWidget {
  final String groupName;
  final String profilePic;
  final int groupId;
  final String description;
  final String totalBalance;
  final String myContributions;
  final Map<String, dynamic> initialLoanSettings;
  final bool isAdmin;
  final String groupLink;
  final bool allowWithdraw;
  final Function(String)? onProfilePicChanged;

  const GroupHeader(
      {Key? key,
      required this.groupName,
      required this.description,
      required this.profilePic,
      required this.groupId,
      required this.totalBalance,
      required this.myContributions,
      required this.initialLoanSettings,
      required this.isAdmin,
      required this.allowWithdraw,
      required this.groupLink,
      this.onProfilePicChanged})
      : super(key: key);

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
    try {
      _allowLoan = widget.initialLoanSettings['allow_loans'] ?? false;
    } catch (e) {
      debugPrint('Error accessing initialLoanSettings: $e');
      _allowLoan = false;
    }
  }

  void _updateProfilePic(File image) {
    debugPrint('Updating profile picture with new image: ${image.path}');
    setState(() {
      _profilePicFile = image;
      _currentProfilePicUrl = null; // Clear the URL to force using the new file
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
      debugPrint('Image selected: ${image.path}');
      // Show the local image immediately
      _updateProfilePic(File(image.path));
      
      // Start the upload in the background
      _uploadProfilePic(image.path);
    }
  }

  Future<void> _uploadProfilePic(String imagePath) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);

      if (userProfile.isEmpty) {
        throw Exception('User profile not found');
      }

      final token = userProfile.first['token'] as String;
      debugPrint('Uploading profile picture to server...');

      final response = await ApiService.updateGroupProfilePic(
        token: token,
        groupId: widget.groupId,
        imageFile: File(imagePath),
      );

      if (response['success'] == true) {
        final newUrl = '${ApiEndpoints.server}${response['newProfilePicUrl']}';
        debugPrint('Profile picture upload successful. New URL: $newUrl');
        
        if (newUrl.isNotEmpty) {
          // Update the groups table with new profile picture
          await db.update(
            'groups',
            {'profile_pic': newUrl},
            where: 'id = ?',
            whereArgs: [widget.groupId],
          );
          
          setState(() {
            _currentProfilePicUrl = newUrl;
            _profilePicFile = null;
          });

          // Notify parent widgets about the profile picture change
          if (widget.onProfilePicChanged != null) {
            widget.onProfilePicChanged!(newUrl);
          }
        }
      } else {
        debugPrint('Profile picture upload failed: ${response['message']}');
      }
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
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
        if (widget.allowWithdraw) // Show Withdraw option only if allowed
          const PopupMenuItem(
            value: 'Withdraw',
            child: Text('Withdraw'),
          ),
        const PopupMenuItem(
          value: 'Top_up',
          child: Text('Top-up'),
        ),
      ],
    ).then((value) {
      if (value != null) {
        if (!widget.isAdmin) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Only admins can perform this action'),
            ),
          );
          return;
        }
        if (value == 'Withdraw') {
          if (!widget.allowWithdraw) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Withdrawals are not allowed for this group'),
              ),
            );
            return;
          }
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content: SingleChildScrollView(
                  child: WithdrawHelper(
                    withdrawType: 'Group_deposit_withdraw',
                    withdrawDetails:
                        "Group withdraws are done by admins alone. Because deposits are auto invested on a unit trust, they might experience delays of up to 3 days or less",
                    groupId: widget.groupId,
                  ),
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
        } else if (value == 'Top_up') {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => AlertDialog(
              content: SizedBox(
                height: 350,
                child: DepositHelper(
                  depositCategory: 'group_top_up',
                  groupId: widget.groupId,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
              ],
            ),
          );
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
      return const Center(child: Loader());
    }

    debugPrint('Building GroupHeader with profile pic: ${_profilePicFile?.path ?? _currentProfilePicUrl}');

    return Container(
      width: double.infinity,
      color: white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  widget.groupName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
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
                              : const AssetImage('assets/images/avatar.png')
                                  as ImageProvider),
                      onBackgroundImageError: (exception, stackTrace) {
                        debugPrint(
                            "Failed to load profile picture: $exception");
                        debugPrint("Stack trace: $stackTrace");
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
                              isAdmin: widget.isAdmin,
                              groupLink: widget.groupLink,
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
                          'TOTAL GROUP BALANCE',
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
                  NumberFormat('#,###').format(double.parse(
                      widget.totalBalance.replaceAll(RegExp(r'[^0-9.]'), ''))),
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'MY BALANCE',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  NumberFormat('#,###').format(double.parse(widget
                      .myContributions
                      .replaceAll(RegExp(r'[^0-9.]'), ''))),
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
              widget.allowWithdraw
                  ? WithdrawButton(
                      groupId: widget.groupId,
                      withdrawType: 'group_user_withdraw',
                    )
                  : Opacity(
                      opacity: 0.5,
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Withdrawals are disabled for this group'),
                            ),
                          );
                        },
                        child: AbsorbPointer(
                            child: WithdrawButton(
                          groupId: widget.groupId,
                          withdrawType: 'group_user_withdraw',
                        )),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
