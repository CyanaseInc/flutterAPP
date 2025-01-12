import 'package:flutter/material.dart';
import 'group_header.dart';
import 'group_settings.dart';
import 'group_members.dart';
import 'group_media.dart';
import 'danger_zone.dart';
import 'group_stat.dart';
import 'group_saving_goal.dart'; // Import the file

class GroupInfoPage extends StatelessWidget {
  final String groupName;
  final String profilePic;

  // Example list of goals
  final List<GroupSavingGoal> groupGoals = [
    GroupSavingGoal(goalName: 'Build a New School', goalAmount: 5000000),
    GroupSavingGoal(goalName: 'Community Health Fund', goalAmount: 3000000),
  ];

  GroupInfoPage({Key? key, required this.groupName, required this.profilePic})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: ListView(
        children: [
          GroupHeader(
            groupName: groupName,
            profilePic: profilePic,
          ),
          TotalDepositsCard(),
          NetworthCard(),
          LoanCard(),
          // Pass groupName here
          GroupSavingGoalsSection(groupGoals: groupGoals),
          const GroupMedia(),
          const GroupSettings(),

          const GroupMembers(),
          const DangerZone(),
          // Add the saving goals section
        ],
      ),
    );
  }
}
