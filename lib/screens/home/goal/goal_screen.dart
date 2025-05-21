import 'package:cyanase/helpers/endpoints.dart';
import 'package:cyanase/screens/home/goal/add_goal.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'goal_header.dart'; // Ensure this file is available
import 'package:cyanase/helpers/deposit.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:vibration/vibration.dart';
import 'goal_details.dart'; // Import the new GoalDetailsScreen
import 'package:intl/intl.dart'; // Import the intl package

class GoalScreen extends StatefulWidget {
  final List<Map<String, dynamic>> goals;
  final bool isLoading;

  const GoalScreen({
    Key? key,
    required this.goals,
    required this.isLoading,
  }) : super(key: key);

  @override
  _GoalScreenState createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  late List<Map<String, dynamic>> _goals; // Local mutable copy of goals

  @override
  void initState() {
    super.initState();
    _goals = List.from(widget.goals); // Initialize with widget.goals
    _initializeNotifications();

    AwesomeNotifications().setListeners(
      onActionReceivedMethod: (ReceivedAction receivedAction) async {
        return Future.value();
      },
      onNotificationCreatedMethod:
          (ReceivedNotification receivedNotification) async {
        return Future.value();
      },
      onNotificationDisplayedMethod:
          (ReceivedNotification receivedNotification) async {
        return Future.value();
      },
    );
  }

  @override
  void didUpdateWidget(GoalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.goals != oldWidget.goals) {
      setState(() {
        _goals = List.from(widget.goals);
      });
    }
  }

  Future<void> _initializeNotifications() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'scheduled_notifications',
          channelName: 'Scheduled Notifications',
          channelDescription: 'Notifications for saving goal reminders',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: white,
          importance: NotificationImportance.High,
          soundSource: null, // Do not specify a custom sound
        ),
      ],
    );

    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  void _handleGoalUpdate(Map<String, dynamic>? result, int index) {
    if (result != null) {
      setState(() {
        if (result.containsKey('deleted') && result['deleted'] == true) {
          _goals.removeAt(index); // Delete the goal
        } else {
          _goals[index] = Map<String, dynamic>.from(result); // Update the goal
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: Loader());
    }

    if (_goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(
              image: AssetImage('assets/images/goal.png'),
              width: 100,
              height: 100,
            ),
            SizedBox(height: 10),
            Text(
              'Set goal and start investing to archive them',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddGoalScreen()),
                ).then((newGoal) {
                  if (newGoal != null && newGoal is Map<String, dynamic>) {
                    setState(() {
                      _goals.add(newGoal);
                    });
                  }
                });
              },
              child: Text(
                'Get Started',
                style: TextStyle(
                  fontSize: 16,
                  color: primaryColor,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTwo,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      );
    }

    double totalSaved = 0.0;
    double totalGoal = 0.0;
    for (var goal in _goals) {
      double deposits = 0.0;
      if (goal['deposit'] != null && (goal['deposit'] as List).isNotEmpty) {
        deposits = (goal['deposit'] as List)
            .map((d) => double.tryParse(d.toString()) ?? 0.0)
            .reduce((a, b) => a + b);
      }
      totalSaved += deposits;
      totalGoal += (goal['goal_amount'] as num? ?? 0).toDouble();
    }

    return Scaffold(
      backgroundColor: white,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                GoalHeader(
                  saved: totalSaved,
                  goal: totalGoal,
                ),
                ..._goals.asMap().entries.map((entry) {
                  final index = entry.key;
                  final goal = entry.value;
                  return GoalCard(
                    goalData: goal,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              GoalDetailsScreen(goalData: goal),
                        ),
                      );
                      _handleGoalUpdate(result, index);
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GoalCard extends StatelessWidget {
  final Map<String, dynamic> goalData;
  final VoidCallback? onTap;

  const GoalCard({
    Key? key,
    required this.goalData,
    this.onTap,
  }) : super(key: key);

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
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      if (pickedDateTime.isBefore(now)) {
        pickedDateTime = pickedDateTime.add(const Duration(days: 1));
      }

      final scheduledTime = pickedDateTime;

      await _scheduleNotification(
        'Reminder: ${goalData['goal_name'] ?? 'Goal'}',
        'Time to save for your goal "${goalData['goal_name'] ?? 'Goal'}"',
        scheduledTime,
      );

      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 500);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder set for ${pickedTime.format(context)}'),
        ),
      );
    }
  }

  void _showDepositBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: EdgeInsets.only(
              top: 12,
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Scrollable content with constrained height
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        controller: scrollController,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: DepositHelper(
                              depositCategory: "goals",
                              selectedFundClass: "default_class",
                              selectedOption: "default_option",
                              selectedFundManager: "default_manager",
                              selectedOptionId: 0,
                              detailText: "Default detail text",
                              groupId: 0,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalDeposits = 0.0;
    if (goalData['deposit'] != null &&
        (goalData['deposit'] as List).isNotEmpty) {
      totalDeposits = (goalData['deposit'] as List)
          .map((d) => double.tryParse(d.toString()) ?? 0.0)
          .reduce((a, b) => a + b);
    }
    final goalAmount = (goalData['goal_amount'] as num? ?? 0).toDouble();
    final progress =
        goalAmount > 0 ? (totalDeposits / goalAmount).clamp(0.0, 1.0) : 0.0;
    final reminderSet = goalData['reminder_set'] as bool? ?? false;

    final goalPicture = goalData['goal_picture'] != null
        ? (goalData['goal_picture'].toString().startsWith('http')
            ? goalData['goal_picture']
            : ApiEndpoints.server + goalData['goal_picture'])
        : null;
    final hasImage = goalPicture != null && goalPicture.isNotEmpty;

    // Create a NumberFormat instance for formatting numbers with commas
    final NumberFormat numberFormat = NumberFormat.decimalPattern();

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16.0),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: hasImage
                            ? NetworkImage(goalPicture)
                            : AssetImage('assets/images/goal.png')
                                as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      goalData['goal_name'] as String? ?? 'Unnamed Goal',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                color: primaryTwo,
                backgroundColor: Colors.grey[200],
              ),
              const SizedBox(height: 8),
              // Display "% completed out of amount" with commas
              Text(
                '${(progress * 100).toStringAsFixed(1)}% completed (${numberFormat.format(totalDeposits)} / ${numberFormat.format(goalAmount)})',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showDepositBottomSheet(context),
                    icon: const Icon(Icons.account_balance_wallet),
                    label: const Text('Deposit'),
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
      ),
    );
  }
}
