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

    final savedAmount =
        (goalData['net_contribution'] as num?)?.toDouble() ?? 0.0;
    final pct = (progress * 100).clamp(0, 100).round();

    Widget goalThumb() {
      const radius = BorderRadius.all(Radius.circular(14));
      if (goalPicture != null) {
        return ClipRRect(
          borderRadius: radius,
          child: Image.network(
            goalPicture,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/images/goal.png',
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
        );
      }
      return ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          'assets/images/goal.png',
          width: 64,
          height: 64,
          fit: BoxFit.cover,
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: primaryTwo.withOpacity(0.06),
            highlightColor: primaryTwo.withOpacity(0.03),
            child: Ink(
              decoration: BoxDecoration(
                color: surfaceMuted,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: surfaceMutedBorder.withOpacity(0.55),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryTwo.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 4,
                        decoration: const BoxDecoration(
                          color: primaryColor,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: goalThumb(),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                goalData['goal_name']
                                                        as String? ??
                                                    'Unnamed Goal',
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w700,
                                                  color: primaryTwo,
                                                  letterSpacing: -0.3,
                                                  height: 1.2,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Icon(
                                              Platform.isIOS
                                                  ? CupertinoIcons.chevron_right
                                                  : Icons.chevron_right_rounded,
                                              size: 22,
                                              color: primaryTwo.withOpacity(0.45),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          numberFormat.format(savedAmount),
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: primaryTwo,
                                            letterSpacing: -0.6,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Target ${numberFormat.format(goalAmount)}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 6,
                                        backgroundColor:
                                            primaryTwo.withOpacity(0.08),
                                        valueColor:
                                            const AlwaysStoppedAnimation<
                                                Color>(primaryTwo),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '$pct%',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: primaryTwo,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: Platform.isIOS
                                        ? CupertinoButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: () =>
                                                _showDepositBottomSheet(
                                                    context),
                                            child: Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: primaryTwo,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    CupertinoIcons
                                                        .plus_circle_fill,
                                                    size: 18,
                                                    color: primaryColor,
                                                  ),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    'Add money',
                                                    style: TextStyle(
                                                      color: white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        : FilledButton.icon(
                                            onPressed: () =>
                                                _showDepositBottomSheet(
                                                    context),
                                            icon: const Icon(
                                              Icons.add_rounded,
                                              size: 20,
                                            ),
                                            label: const Text('Add money'),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: primaryTwo,
                                              foregroundColor: white,
                                              padding: const EdgeInsets.symmetric(
                                                vertical: 12,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 10),
                                  Material(
                                    color: primaryTwo.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      onTap: () async {
                                        await _setReminder(context);
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                        width: 48,
                                        height: 48,
                                        child: Icon(
                                          reminderSet
                                              ? (Platform.isIOS
                                                  ? CupertinoIcons.bell_fill
                                                  : Icons.notifications_active_rounded)
                                              : (Platform.isIOS
                                                  ? CupertinoIcons.bell
                                                  : Icons.notifications_outlined),
                                          color: reminderSet
                                              ? primaryTwo
                                              : Colors.grey.shade600,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
