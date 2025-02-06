import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'add_group_goal.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:vibration/vibration.dart';

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

class GroupSavingGoalsSection extends StatefulWidget {
  final List<GroupSavingGoal> groupGoals;

  const GroupSavingGoalsSection({Key? key, required this.groupGoals})
      : super(key: key);

  @override
  _GroupSavingGoalsSectionState createState() =>
      _GroupSavingGoalsSectionState();
}

class _GroupSavingGoalsSectionState extends State<GroupSavingGoalsSection> {
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'scheduled_notifications',
          channelName: 'Scheduled Notifications',
          channelDescription: 'Notifications for group saving goal reminders',
          defaultColor: primaryTwo,
          ledColor: Colors.white,
          importance: NotificationImportance.High,
        ),
      ],
    );
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: white,
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AddGroupGoalScreen()),
                  );
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
          ...widget.groupGoals
              .map((goal) => GroupSavingGoalsCard(groupGoal: goal))
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
      schedule: NotificationCalendar.fromDate(date: scheduledTime),
    );
  }

  Future<void> _setReminder(BuildContext context) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      final now = DateTime.now();
      var pickedDateTime = DateTime(
          now.year, now.month, now.day, pickedTime.hour, pickedTime.minute);
      if (pickedDateTime.isBefore(now)) {
        pickedDateTime = pickedDateTime.add(Duration(days: 1));
      }

      await _scheduleNotification('Reminder: ${groupGoal.goalName}',
          'Time to save for your goal "${groupGoal.goalName}"', pickedDateTime);

      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 500);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Reminder set for ${pickedTime.format(context)}')),
      );
    }
  }

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
                        color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await _setReminder(context);
                  },
                  icon: Icon(Icons.notifications, color: primaryTwo),
                ),
              ],
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: groupGoal.progressPercentage / 100,
              backgroundColor: Colors.grey[200],
              color: primaryTwo,
              minHeight: 8,
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${groupGoal.progressPercentage.toStringAsFixed(1)}%",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: primaryTwo,
                  ),
                ),
                Text(
                  "UGX ${groupGoal.currentAmount.toStringAsFixed(0)} / UGX ${groupGoal.goalAmount.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {},
              child: Text('Deposit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTwo,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
