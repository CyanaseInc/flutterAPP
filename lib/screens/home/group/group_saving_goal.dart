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

class GroupSavingGoalsSection extends StatelessWidget {
  final List<GroupSavingGoal> groupGoals;

  const GroupSavingGoalsSection({Key? key, required this.groupGoals})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: white, // White background for the section
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Group Goals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Handle Add Goal button action
                },
                child: Text('Add Goal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTwo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...groupGoals
              .map((groupGoal) => GroupSavingGoalsCard(groupGoal: groupGoal))
              .toList(),
        ],
      ),
    );
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
      margin: const EdgeInsets.symmetric(vertical: 8),
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

            Divider(color: Colors.grey.shade300, thickness: 1),
            SizedBox(height: 6),
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
            SizedBox(height: 4),
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
            SizedBox(height: 8),
            // Deposit Button
            ElevatedButton(
              onPressed: () {
                // Handle deposit logic here
                showDialog(
                  context: context,
                  builder: (context) {
                    final TextEditingController _controller =
                        TextEditingController();

                    return AlertDialog(
                      backgroundColor: white, // White background for the modal
                      title: Text(
                        'Enter Amount',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                        ), // Customize title text color
                      ),
                      content: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          labelStyle: TextStyle(
                              color: Colors.black54), // Label text color
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.black54), // Border color
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: primaryTwo), // Focused border color
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context), // Cancel action
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                                color: primaryTwo), // Button text color
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Handle the submit action
                            double depositAmount =
                                double.tryParse(_controller.text) ?? 0;
                            if (depositAmount > 0) {
                              groupGoal.addContribution(depositAmount);
                            }
                            Navigator.pop(
                                context); // Close the dialog after submission
                          },
                          child: Text('Submit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                primaryTwo, // Customize the button color
                            // Text color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('Deposit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTwo, // Customize the button color
                // Text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
