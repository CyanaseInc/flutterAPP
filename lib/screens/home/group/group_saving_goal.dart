import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';

class GroupSavingGoal {
  final String goalName;
  final double goalAmount;
  double currentAmount;

  GroupSavingGoal({
    required this.goalName,
    required this.goalAmount,
    this.currentAmount = 0.0,
  });

  double get progressPercentage => (currentAmount / goalAmount) * 100;

  void addContribution(double amount) {
    currentAmount += amount;
    if (currentAmount > goalAmount) {
      currentAmount = goalAmount;
    }
  }
}

class GroupSavingGoalsCard extends StatelessWidget {
  final GroupSavingGoal groupGoal;

  const GroupSavingGoalsCard({Key? key, required this.groupGoal})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    groupGoal.goalName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                CircleAvatar(
                  backgroundColor: primaryTwo.withOpacity(0.1),
                  radius: 18,
                  child: Icon(Icons.savings, color: primaryTwo, size: 18),
                ),
              ],
            ),
            SizedBox(height: 12),
            Divider(color: Colors.grey.shade300, thickness: 1),
            SizedBox(height: 12),
            Row(
              children: [
                Text(
                  "Saved:",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  "UGX ${groupGoal.currentAmount.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Spacer(),
                Text(
                  "Goal:",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  "UGX ${groupGoal.goalAmount.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: groupGoal.progressPercentage / 100,
                backgroundColor: Colors.grey[200],
                color: primaryTwo,
                minHeight: 8,
              ),
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "${groupGoal.progressPercentage.toStringAsFixed(1)}% Complete",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: primaryTwo,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
