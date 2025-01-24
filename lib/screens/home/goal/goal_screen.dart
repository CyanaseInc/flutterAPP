import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'goal_header.dart'; // Ensure this file is available
import 'package:cyanase/screens/home/deposit.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:vibration/vibration.dart';

class GoalScreen extends StatefulWidget {
  @override
  _GoalScreenState createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  @override
  void initState() {
    super.initState();
    _initializeNotifications();

    // Set up notification listeners
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: (ReceivedAction receivedAction) async {
        print('Notification action received: ${receivedAction.body}');
        // Handle notification actions here
        return Future.value(); // Return a Future<void>
      },
      onNotificationCreatedMethod:
          (ReceivedNotification receivedNotification) async {
        print('Notification created: ${receivedNotification.body}');
        // Handle notification creation here
        return Future.value(); // Return a Future<void>
      },
      onNotificationDisplayedMethod:
          (ReceivedNotification receivedNotification) async {
        print('Notification displayed: ${receivedNotification.body}');
        // Handle notification display here
        return Future.value(); // Return a Future<void>
      },
    );
  }

  Future<void> _initializeNotifications() async {
    await AwesomeNotifications().initialize(
      null, // Use null for default app icon
      [
        NotificationChannel(
          channelKey: 'scheduled_notifications',
          channelName: 'Scheduled Notifications',
          channelDescription: 'Notifications for saving goal reminders',
          defaultColor: Color(0xFF9D50DD),
          ledColor: white,
          importance: NotificationImportance.High,
        ),
      ],
    );

    // Request notification permissions
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
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

  int _getUniqueID() {
    return DateTime.now().microsecondsSinceEpoch.remainder(100000);
  }

  Future<void> _scheduleNotification(
      String title, String body, DateTime scheduledTime) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _getUniqueID(),
        channelKey: 'scheduled_notifications',
        title: title,
        body: body,
      ),
      schedule: NotificationCalendar.fromDate(
        date: scheduledTime, // Use the scheduled time
      ),
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
      var pickedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      // If the selected time is in the past, schedule it for the next day
      if (pickedDateTime.isBefore(now)) {
        pickedDateTime = pickedDateTime.add(Duration(days: 1));
      }

      final scheduledTime = pickedDateTime;

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
