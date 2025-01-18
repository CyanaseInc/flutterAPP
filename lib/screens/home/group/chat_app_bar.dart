// message_app_bar.dart
import 'package:flutter/material.dart';
import 'package:cyanase/screens/home/group/group_info.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/screens/home/group/group_deposit.dart';
import 'dart:io';

class MessageAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String name; // Group name
  final String profilePic; // Group profile picture path
  final List<String> memberNames; // List of group member names
  final VoidCallback onDepositPressed; // Callback for deposit button
  final VoidCallback onBackPressed; // Callback for back button

  const MessageAppBar({
    Key? key,
    required this.name,
    required this.profilePic,
    required this.memberNames,
    required this.onDepositPressed,
    required this.onBackPressed,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  // Helper function to truncate long text
  String _truncateText(String text, {int maxLength = 9}) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  // Helper function to format member names
  String _formatMemberNames(List<String> members, {int maxNames = 2}) {
    if (members.isEmpty) {
      return "No members";
    }

    // Join the first `maxNames` members with a comma
    String formattedNames = members.take(maxNames).join(", ");

    // If there are more members, add "and X others..."
    if (members.length > maxNames) {
      formattedNames += " and ${members.length - maxNames} others...";
    }

    return formattedNames;
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 0, // Remove default spacing around the title
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.black),
        onPressed: onBackPressed, // Handle back button press
      ),
      title: GestureDetector(
        onTap: () {
          // Navigate to the group info page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupInfoPage(
                groupName: name,
                profilePic: profilePic,
              ),
            ),
          );
        },
        child: Row(
          children: [
            // Group profile picture
            CircleAvatar(
              backgroundImage: profilePic.isNotEmpty
                  ? FileImage(File(profilePic)) // Load from file
                  : AssetImage('assets/avat.png') as ImageProvider, // Fallback
              radius: 20,
            ),
            SizedBox(width: 10), // Spacing between avatar and text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group name (truncated if too long)
                Text(
                  _truncateText(name),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4), // Spacing between group name and members
                // Group member names (truncated if too many)
                Text(
                  _formatMemberNames(memberNames),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        // Deposit button
        OutlinedButton(
          onPressed: onDepositPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: primaryTwo),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text(
            'Deposit',
            style: TextStyle(
              color: primaryTwo,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // More options menu
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.black),
          onSelected: (String value) {
            switch (value) {
              case 'group_info':
                // Navigate to group info page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupInfoPage(
                      groupName: name,
                      profilePic: profilePic,
                    ),
                  ),
                );
                break;
              case 'edit_group':
                print('Edit Group Selected');
                break;
              case 'leave_group':
                print('Leave Group Selected');
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'group_info',
              child: Text('Group Info'),
            ),
            const PopupMenuItem<String>(
              value: 'edit_group',
              child: Text('Edit Group'),
            ),
            const PopupMenuItem<String>(
              value: 'leave_group',
              child: Text('Leave Group'),
            ),
          ],
        ),
      ],
    );
  }
}
