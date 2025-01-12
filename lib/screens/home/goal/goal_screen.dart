import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'goal_header.dart'; // Ensure this file is available
import 'package:cyanase/screens/home/deposit.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:vibration/vibration.dart';

class GoalScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16.0),
              children: [
                GoalHeader(
                  saved: 600.0,
                  goal: 1000.0,
                ),
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
          ),
        ],
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

  Future<void> _scheduleNotification(
      String title, String body, DateTime scheduledTime) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1, // Unique ID for the notification
        channelKey: 'scheduled_notifications', // Channel key
        title: title,
        body: body,
      ),
      schedule: NotificationCalendar.fromDate(
          date: scheduledTime), // Schedule the notification
    );
  }

  Future<void> _setReminder(BuildContext context) async {
    // Show a time picker to set the reminder time
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      final now = DateTime.now();
      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      // Schedule the notification
      await _scheduleNotification(
        'Reminder: $title',
        'Time to save for your goal "$title"',
        scheduledTime,
      );

      // Trigger vibration
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 500); // Vibrate for 500ms
      }

      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder set for ${pickedTime.format(context)}'),
        ),
      );
    }
  }

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
              color: primaryTwo,
              backgroundColor: Colors.grey[200],
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DepositScreen(),
                      ),
                    );
                  },
                  icon: Icon(Icons.account_balance_wallet),
                  label: Text('Deposit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTwo,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await _setReminder(context);
                  },
                  icon: Icon(
                    reminderSet
                        ? Icons.notifications_active
                        : Icons.notifications,
                    color: reminderSet ? primaryTwo : Colors.grey,
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
