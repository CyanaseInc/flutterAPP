import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import 'group_info.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String name;
  final String profilePic;
  final VoidCallback onDepositPressed;

  const ChatAppBar({
    Key? key,
    required this.name,
    required this.profilePic,
    required this.onDepositPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String firstName = name.split(' ')[0];

    return AppBar(
      backgroundColor: primaryColor,
      title: Row(
        children: [
          CircleAvatar(
            backgroundImage: AssetImage(profilePic),
            radius: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Your code to handle the tap event
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        GroupInfoPage(groupName: name, profilePic: profilePic),
                  ),
                );
              },
              child: Text(
                firstName,
                style: const TextStyle(color: Colors.white),
                // Ensure the text is always on one line with ellipsis for overflow
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: onDepositPressed,
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    backgroundColor: Colors.white,
                    foregroundColor: primaryTwo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: primaryTwo, width: 1),
                    ),
                  ),
                  icon: Icon(Icons.wallet, size: 18, color: primaryTwo),
                  label: const Text('Deposit'),
                ),
                const SizedBox(width: 5), // Space before the vertical dots
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      color: Colors.white), // Vertical three dots
                  onSelected: (value) {
                    if (value == 'info') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupInfoPage(
                            groupName: name,
                            profilePic: profilePic, // Pass the group name here
                          ),
                        ),
                      );
                    }
                    // Add other actions for different menu items here
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'add',
                      child: Text('Invite members'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'withdraw',
                      child: Text('Withdraw'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'info',
                      child: Text('Group info'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
