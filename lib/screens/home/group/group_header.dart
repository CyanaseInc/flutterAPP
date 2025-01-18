import 'package:flutter/material.dart';
import 'get_group_loan.dart';
import 'group_deposit_info_button.dart';
import 'group_withdraw.dart';
import 'package:cyanase/theme/theme.dart'; // Assuming this is where your colors are defined
import 'dart:io';
import 'package:image_picker/image_picker.dart'; // For image picking functionality

class GroupHeader extends StatefulWidget {
  final String groupName;
  final String profilePic;

  const GroupHeader({
    Key? key,
    required this.groupName,
    required this.profilePic,
  }) : super(key: key);

  @override
  _GroupHeaderState createState() => _GroupHeaderState();
}

class _GroupHeaderState extends State<GroupHeader> {
  File? _profilePicFile;

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
      _updateProfilePic(File(image.path));
    }
  }

  void _removeProfilePic() {
    setState(() {
      _profilePicFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Column(
        children: [
          // Top Row with Group Name, Profile Pic, and Menu Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Group Name on the left
              Text(
                widget.groupName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Profile Picture and Menu Icon on the right
              Row(
                children: [
                  // Profile Picture
                  GestureDetector(
                    onTap: _showProfilePicOptions,
                    child: CircleAvatar(
                      backgroundImage: _profilePicFile != null
                          ? FileImage(_profilePicFile!)
                          : widget.profilePic.isNotEmpty
                              ? FileImage(File(widget.profilePic))
                              : AssetImage('assets/avat.png') as ImageProvider,
                      radius: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Vertical Bars (Menu)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'Add Members') {
                        // Handle "Add Members" action
                      } else if (value == 'Change Group Name') {
                        // Handle "Change Group Name" action
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

          // Total Savings and Contributions
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Use a Row with Expanded to center the text and push the menu icon to the right
                Row(
                  children: [
                    // Expanded widget to center the text
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
                    // Menu icon on the right
                    GestureDetector(
                      onTap: () {
                        // Show dropdown menu
                        _showBalanceOptionsMenu(context);
                      },
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
                  '\$12,900,345.67',
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: primaryColor, // Using your primaryColor
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
                  '\$1,234.56',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryTwo, // Using your primaryTwo
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Group Description
          const Text(
            'This is a family saving group for us all',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Action Buttons
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              DepositButton(),
              LoanButton(),
              WithdrawButton(),
            ],
          ),
        ],
      ),
    );
  }

  void _showBalanceOptionsMenu(BuildContext context) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(
          100, 100, 0, 0), // Adjust position as needed
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
          // Handle "Withdraw" action
        } else if (value == 'Add Interest') {
          // Handle "Add Interest" action
        }
      }
    });
  }
}
