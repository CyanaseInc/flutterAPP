import 'package:flutter/material.dart';
import 'group_header.dart';
import 'group_settings.dart';
import 'group_members.dart';
import 'group_media.dart';
import 'danger_zone.dart';
import 'group_stat.dart';
import 'group_saving_goal.dart'; // Import the file
import 'package:cyanase/theme/theme.dart';

class GroupInfoPage extends StatelessWidget {
  final String groupName;
  final String profilePic;
  final int groupId;

  // Example list of goals
  final List<GroupSavingGoal> groupGoals = [
    GroupSavingGoal(goalName: 'Build a New School', goalAmount: 5000000),
    GroupSavingGoal(goalName: 'Community Health Fund', goalAmount: 3000000),
  ];

  GroupInfoPage({
    Key? key,
    required this.groupName,
    required this.profilePic,
    required this.groupId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: ListView(
        children: [
          GroupHeader(
            groupName: groupName,
            profilePic: profilePic,
            groupId: groupId,
          ),
          Container(
            color: white,
            margin: const EdgeInsets.only(top: 8.0),
            child: ListTile(
              title: const Text(
                'Group finance info',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupFinancePage(groupId: groupId),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 10),
          GroupSavingGoalsSection(groupGoals: groupGoals),
          const GroupMedia(),
          const GroupSettings(),
          const GroupMembers(),
          const DangerZone(),
        ],
      ),
    );
  }
}
