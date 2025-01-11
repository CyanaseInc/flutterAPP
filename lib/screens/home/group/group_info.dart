import 'package:flutter/material.dart';
import 'group_header.dart';
import 'group_settings.dart';
import 'group_members.dart';
import 'group_media.dart';
import 'danger_zone.dart';
import 'group_stat.dart';
import 'group_saving_goal.dart';

class GroupInfoPage extends StatelessWidget {
  final String groupName;
  final String profilePic;
  const GroupInfoPage(
      {Key? key, required this.groupName, required this.profilePic})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    GroupSavingGoal groupGoal = GroupSavingGoal(
      goalName: 'Buy land for gand mum',
      goalAmount: 500000.0,
      currentAmount: 120000.0,
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, // Remove shadow
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
          GroupSavingGoalsCard(groupGoal: groupGoal), // Pass groupName here
          const GroupSettings(),
          const GroupMedia(),
          const GroupMembers(),
          const DangerZone(),
        ],
      ),
    );
  }
}
