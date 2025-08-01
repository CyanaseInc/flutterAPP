import 'package:cyanase/helpers/endpoints.dart';
import 'package:cyanase/screens/home/goal/add_goal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cyanase/theme/theme.dart';
import 'goal_header.dart'; // Ensure this file is available
import 'package:cyanase/helpers/deposit.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:vibration/vibration.dart';
import 'goal_details.dart'; // Import the new GoalDetailsScreen
import 'package:intl/intl.dart'; // Import the intl package
import 'package:cyanase/helpers/get_currency.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'dart:io';

class GoalScreen extends StatefulWidget {
  final List<Map<String, dynamic>> goals;
  final bool isLoading;
  final double totalDeposit;

  const GoalScreen({
    Key? key,
    required this.goals,
    required this.isLoading,
    required this.totalDeposit,
  }) : super(key: key);

  @override
  _GoalScreenState createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  late List<Map<String, dynamic>> _goals; // Local mutable copy of goals
  String currency = '';

  @override
  void initState() {
    super.initState();
    _goals = List.from(widget.goals); // Initialize with widget.goals
    _initializeNotifications();
    _fetchUserCurrency();

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

  Future<void> _fetchUserCurrency() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);

      if (userProfile.isNotEmpty) {
        final userCountry = userProfile.first['country'] as String;
        final currencyCode = CurrencyHelper.getCurrencyCode(userCountry);
        setState(() {
         
          currency = currencyCode;
        });
      }
    } catch (e) {
      
    }
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Loader(),
            const SizedBox(height: 16),
            Text(
              'Loading your goals...',
              style: TextStyle(
                fontSize: 16,
                color: primaryTwo,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
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
              'Set goals and start investing to achieve them.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Platform.isIOS
                ? CupertinoButton.filled(
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
                  )
                : ElevatedButton(
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
      double saved = (goal['net_contribution'] as num?)?.toDouble() ?? 0.0;
      double goalAmount = (goal['goal_amount'] as num?)?.toDouble() ?? 0.0;
      totalSaved += saved;
      totalGoal += goalAmount;
    }

    return Platform.isIOS
        ? CupertinoPageScaffold(
            backgroundColor: white,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      GoalHeader(
                        saved: widget.totalDeposit,
                        goal: totalGoal,
                      ),
                      ..._goals.asMap().entries.map((entry) {
                        final index = entry.key;
                        final goal = entry.value;
                        return GoalCard(
                          goalData: goal,
                          currency: currency,
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
          )
        : Scaffold(
            backgroundColor: white,
            body: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      GoalHeader(
                        saved: widget.totalDeposit,
                        goal: totalGoal,
                      ),
                      ..._goals.asMap().entries.map((entry) {
                        final index = entry.key;
                        final goal = entry.value;
                        return GoalCard(
                          goalData: goal,
                          currency: currency,
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

// ... (other imports remain the same)
class GoalCard extends StatelessWidget {
  final Map<String, dynamic> goalData;
  final VoidCallback? onTap;
  final String currency;

  const GoalCard({
    Key? key,
    required this.goalData,
    required this.currency,
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
                Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
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
                              depositCategory: "personal_goals",
                              selectedFundClass: "default_class",
                              selectedOption: "default_option",
                              selectedFundManager: "default_manager",
                              selectedOptionId: 0,
                              detailText: "Deposit to ${goalData['goal_name'] ?? 'Goal'}",
                              groupId: 0,
                              goalId: goalData['id'] ?? goalData['goal_id'] ?? 0, // Pass goalId
                              
                              
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
            : "${ApiEndpoints.server}/${goalData['goal_picture']}")
        : null;

    final NumberFormat numberFormat = NumberFormat.currency(
      symbol: '$currency ',
      decimalDigits: 0,
      locale: 'en_NG',
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: onTap,
          child: Card(
            margin: const EdgeInsets.only(bottom: 20.0),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryTwo.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            image: DecorationImage(
                              image: goalPicture != null
                                  ? NetworkImage(goalPicture)
                                  : const AssetImage('assets/images/goal.png')
                                      as ImageProvider,
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) =>
                                  const AssetImage('assets/images/goal.png'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      goalData['goal_name'] as String? ??
                                          'Unnamed Goal',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Platform.isIOS
                                        ? CupertinoIcons.chevron_right
                                        : Icons.arrow_forward_ios,
                                    size: 14,
                                    color: primaryTwo.withOpacity(0.7),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                numberFormat.format((goalData['net_contribution'] as num?)?.toDouble() ?? 0.0),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: primaryTwo,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(primaryTwo),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Platform.isIOS
                                ? CupertinoButton.filled(
                                    onPressed: () =>
                                        _showDepositBottomSheet(context),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 13, vertical: 9),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(CupertinoIcons.money_dollar_circle,
                                            size: 18),
                                        const SizedBox(width: 4),
                                        const Text('Deposit'),
                                      ],
                                    ),
                                  )
                                : ElevatedButton.icon(
                                    onPressed: () =>
                                        _showDepositBottomSheet(context),
                                    icon: const Icon(
                                        Icons.account_balance_wallet,
                                        size: 18),
                                    label: const Text('Deposit'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryTwo,
                                      foregroundColor: white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 13, vertical: 9),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                            const SizedBox(width: 8),
                            Platform.isIOS
                                ? CupertinoButton(
                                    onPressed: () async {
                                      await _setReminder(context);
                                    },
                                    padding: const EdgeInsets.all(5),
                                    color: Colors.grey[100],
                                    child: Icon(
                                      reminderSet
                                          ? CupertinoIcons.bell_fill
                                          : CupertinoIcons.bell,
                                      color: reminderSet
                                          ? primaryTwo
                                          : Colors.grey[400],
                                      size: 20,
                                    ),
                                  )
                                : IconButton(
                                    onPressed: () async {
                                      await _setReminder(context);
                                    },
                                    icon: Icon(
                                      reminderSet
                                          ? Icons.notifications_active
                                          : Icons.notifications,
                                      color: reminderSet
                                          ? primaryTwo
                                          : Colors.grey[400],
                                      size: 20,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.grey[100],
                                      padding: const EdgeInsets.all(5),
                                    ),
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
