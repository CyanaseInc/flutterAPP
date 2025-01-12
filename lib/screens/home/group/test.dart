import 'package:flutter/material.dart';

class Testa extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saving Goals'),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          GoalCard(
            title: "Vacation Fund",
            progress: 0.6,
            reminderSet: true,
          ),
          GoalCard(
            title: "New Laptop",
            progress: 0.3,
            reminderSet: false,
          ),
          GoalCard(
            title: "Emergency Fund",
            progress: 0.8,
            reminderSet: true,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Add Goal screen
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
    );
  }
}

class GoalCard extends StatelessWidget {
  final String title;
  final double progress;
  final bool reminderSet;

  GoalCard({
    required this.title,
    required this.progress,
    required this.reminderSet,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              color: Colors.teal,
              backgroundColor: Colors.teal.shade100,
            ),
            SizedBox(height: 8),
            Text(
              '${(progress * 100).toInt()}% completed',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Deposit to this goal
                  },
                  icon: Icon(Icons.account_balance_wallet),
                  label: Text('Deposit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Set reminder for this goal
                  },
                  icon: Icon(
                    reminderSet
                        ? Icons.notifications_active
                        : Icons.notifications,
                    color: reminderSet ? Colors.teal : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
