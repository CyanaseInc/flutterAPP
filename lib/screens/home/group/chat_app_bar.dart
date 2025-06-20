import 'package:flutter/material.dart';
import 'package:cyanase/screens/home/group/group_info.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MessageAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String name; // Group name
  final String profilePic; // Group profile picture path
  final List<String> memberNames; // List of group member names
  final VoidCallback onDepositPressed; // Callback for deposit button
  final VoidCallback onBackPressed; // Callback for back button
  final int? groupId;
  final String description;
  final Function(String)? onProfilePicChanged;

  const MessageAppBar({
    Key? key,
    required this.name,
    required this.groupId,
    required this.profilePic,
    required this.memberNames,
    required this.onDepositPressed,
    required this.onBackPressed,
    required this.description,
    this.onProfilePicChanged,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  // Helper function to truncate long text to a maximum length
  String _truncateText(String text, {int maxLength = 10}) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  String _truncateMemberText(String text, {int maxLength = 3}) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  // Helper function to format member names (separate from group name)
  String _formatMemberNames(List<String> members, {int maxNames = 3}) {
    if (members.isEmpty) {
      return "No members";
    }

    // Truncate each member's name to a maximum of 15 characters
    final truncatedMembers =
        members.map((name) => _truncateMemberText(name)).toList();

    // Join the first `maxNames` members with a comma
    String formattedNames = truncatedMembers.take(maxNames).join(", ");

    // If there are more members, add "and X others..."
    if (members.length > maxNames) {
      formattedNames;
    }

    return formattedNames;
  }

  // Helper function to format member names (separate from group name)

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      backgroundColor: white, // Remove default spacing around the title
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Colors.black),
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
                  groupId: groupId ?? 0,
                  description: description),
            ),
          );
        },
        child: Row(
          children: [
            // Group profile picture

            CircleAvatar(
              radius: 20,
              backgroundImage: profilePic != null && profilePic.isNotEmpty
                  ? CachedNetworkImageProvider(profilePic)
                  : const AssetImage('assets/avat.png') as ImageProvider,
              onBackgroundImageError:
                  profilePic != null && profilePic.isNotEmpty
                      ? (exception, stackTrace) {
                          print(
                              "Failed to load profilePic: $profilePic, error: $exception");
                        }
                      : null,
            ),
            SizedBox(width: 10), // Spacing between avatar and text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Group name (truncated if too long)
                Text(
                  _truncateText(name), // Truncate group name
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis, // Truncate with ellipsis
                  maxLines: 1, // Ensure text stays on one line
                ),
                SizedBox(height: 4), // Spacing between group name and members
                // Group member names (truncated if too many)
                Text(
                  _formatMemberNames(memberNames), // Format member names
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                  overflow: TextOverflow.ellipsis, // Truncate with ellipsis
                  maxLines: 1, // Ensure text stays on one line
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
                      groupId: groupId ?? 0,
                      description: description,
                    ),
                  ),
                );
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'group_info',
              child: Text('Group Info'),
            ),
          ],
        ),
      ],
    );
  }
}