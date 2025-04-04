import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'add_group_goal.dart';
import 'edit_group_goal_screen.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:vibration/vibration.dart';

class Contributor {
  final String name;
  final double amount;
  final DateTime date;

  Contributor({
    required this.name,
    required this.amount,
    required this.date,
  });
}

class GroupSavingGoal {
  final int? goalId;
  String goalName;
  final double goalAmount;
  double currentAmount;
  final String? startDate;
  final String? endDate;
  final String? status;
  final List<Contributor> contributors;

  GroupSavingGoal({
    this.goalId,
    required this.goalName,
    required this.goalAmount,
    this.currentAmount = 0.0,
    this.startDate,
    this.endDate,
    this.status,
    this.contributors = const [],
  });

  factory GroupSavingGoal.fromJson(Map<String, dynamic> json) {
    List<Contributor> contributors = [];
    if (json['deposits'] != null && json['deposits'] is List) {
      contributors = (json['deposits'] as List).map((deposit) {
        return Contributor(
          name: deposit['member_name'] ?? 'Anonymous',
          amount: (deposit['amount'] as num).toDouble(),
          date: DateTime.parse(deposit['deposit_date']),
        );
      }).toList();
    }

    return GroupSavingGoal(
      goalId: json['goal_id'],
      goalName: json['goal_name'],
      goalAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num).toDouble(),
      startDate: json['start_date'],
      endDate: json['end_date'],
      status: json['status'],
      contributors: contributors,
    );
  }

  double get progressPercentage => (currentAmount / goalAmount) * 100;

  void addContribution(double amount, String contributorName) {
    contributors.add(Contributor(
      name: contributorName,
      amount: amount,
      date: DateTime.now(),
    ));
    currentAmount += amount;
  }

  void updateGoalName(String newName) {
    goalName = newName;
  }

  void withdrawAmount(double amount) {
    if (amount <= currentAmount) {
      currentAmount -= amount;
    }
  }

  GroupSavingGoal copyWith({
    int? goalId,
    String? goalName,
    double? goalAmount,
    double? currentAmount,
    String? startDate,
    String? endDate,
    String? status,
    List<Contributor>? contributors,
  }) {
    return GroupSavingGoal(
      goalId: goalId ?? this.goalId,
      goalName: goalName ?? this.goalName,
      goalAmount: goalAmount ?? this.goalAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      contributors: contributors ?? this.contributors,
    );
  }
}

class GroupSavingGoalsSection extends StatefulWidget {
  final int groupId;
  final List<GroupSavingGoal> groupGoals;
  final Function()? onGoalAdded;
  final Function(GroupSavingGoal)? onGoalUpdated;
  final Function(int)? onGoalDeleted;
  final String totalBalance;
  final String myContributions;
  final bool showAllGoals;

  const GroupSavingGoalsSection({
    Key? key,
    required this.groupGoals,
    required this.groupId,
    this.onGoalAdded,
    this.onGoalUpdated,
    this.onGoalDeleted,
    required this.totalBalance,
    required this.myContributions,
    this.showAllGoals = false,
  }) : super(key: key);

  @override
  State<GroupSavingGoalsSection> createState() =>
      _GroupSavingGoalsSectionState();
}

class _GroupSavingGoalsSectionState extends State<GroupSavingGoalsSection> {
  late List<GroupSavingGoal> _groupGoals;

  @override
  void initState() {
    super.initState();
    _groupGoals = List.from(widget.groupGoals);
    _initializeNotifications();
  }

  @override
  void didUpdateWidget(GroupSavingGoalsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.groupGoals != oldWidget.groupGoals) {
      setState(() {
        _groupGoals = List.from(widget.groupGoals);
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
          channelDescription: 'Notifications for group saving goal reminders',
          defaultColor: primaryTwo,
          ledColor: Colors.white,
          importance: NotificationImportance.High,
        ),
      ],
    );
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  void _handleGoalAddedResult(dynamic result) {
    if (result is GroupSavingGoal) {
      setState(() {
        _groupGoals.insert(0, result);
      });
      widget.onGoalAdded?.call();
    } else if (result == true) {
      widget.onGoalAdded?.call();
    }
  }

  void _handleGoalEditedOrDeleted(dynamic result) {
    if (result is Map<String, dynamic>) {
      setState(() {
        final index =
            _groupGoals.indexWhere((goal) => goal.goalId == result['goalId']);
        if (index != -1) {
          if (result['deleted'] == true) {
            _groupGoals.removeAt(index);
            widget.onGoalDeleted?.call(result['goalId']);
          } else {
            GroupSavingGoal updatedGoal = _groupGoals[index];
            if (result['goalName'] != null) {
              updatedGoal = updatedGoal.copyWith(goalName: result['goalName']);
            }
            if (result['withdrawAmount'] != null) {
              updatedGoal = updatedGoal.copyWith(
                  currentAmount:
                      updatedGoal.currentAmount - result['withdrawAmount']);
            }
            _groupGoals[index] = updatedGoal;
            widget.onGoalUpdated?.call(updatedGoal);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayTotalBalance =
        widget.totalBalance.isEmpty ? "0" : widget.totalBalance;
    final displayMyContributions =
        widget.myContributions.isEmpty ? "0" : widget.myContributions;
    final displayedGoals =
        widget.showAllGoals ? _groupGoals : _groupGoals.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[100]!, Colors.grey[50]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(),
          const SizedBox(height: 16),
          _buildBalanceSummary(displayTotalBalance, displayMyContributions),
          const SizedBox(height: 16),
          _buildGoalsList(displayedGoals),
          if (!widget.showAllGoals && _groupGoals.length > 3)
            _buildSeeAllButton(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Group Saving Goals',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AddGroupGoalScreen(groupId: widget.groupId),
              ),
            );
            _handleGoalAddedResult(result);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryTwo,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+ Add Goal',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceSummary(String totalBalance, String myContributions) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                'Group Total',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                totalBalance,
                style: TextStyle(
                  color: primaryTwo,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.grey[300],
          ),
          Column(
            children: [
              Text(
                'My Contributions',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                myContributions,
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList(List<GroupSavingGoal> goals) {
    if (goals.isEmpty) {
      return const Center(
        child: Text(
          'No goals yet. Add one to get started!',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        return GroupSavingGoalsCard(
          key: ValueKey(goals[index].goalId ?? goals[index].goalName),
          groupGoal: goals[index],
          groupId: widget.groupId,
          onContributionAdded: widget.onGoalAdded,
          onGoalUpdated: widget.onGoalUpdated,
          onGoalDeleted: widget.onGoalDeleted,
          onEditResult: _handleGoalEditedOrDeleted,
        );
      },
    );
  }

  Widget _buildSeeAllButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Center(
        child: TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: const Text('All Group Goals'),
                  ),
                  body: GroupSavingGoalsSection(
                    groupGoals: _groupGoals,
                    groupId: widget.groupId,
                    totalBalance: widget.totalBalance,
                    myContributions: widget.myContributions,
                    showAllGoals: true,
                    onGoalAdded: widget.onGoalAdded,
                    onGoalUpdated: widget.onGoalUpdated,
                    onGoalDeleted: widget.onGoalDeleted,
                  ),
                ),
              ),
            );
          },
          child: Text(
            'See All (${_groupGoals.length})',
            style: TextStyle(
              color: primaryTwo,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class GroupSavingGoalsCard extends StatefulWidget {
  final GroupSavingGoal groupGoal;
  final int groupId;
  final Function()? onContributionAdded;
  final Function(GroupSavingGoal)? onGoalUpdated;
  final Function(int)? onGoalDeleted;
  final Function(dynamic)? onEditResult;

  const GroupSavingGoalsCard({
    Key? key,
    required this.groupGoal,
    required this.groupId,
    this.onContributionAdded,
    this.onGoalUpdated,
    this.onGoalDeleted,
    this.onEditResult,
  }) : super(key: key);

  @override
  State<GroupSavingGoalsCard> createState() => _GroupSavingGoalsCardState();
}

class _GroupSavingGoalsCardState extends State<GroupSavingGoalsCard> {
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
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: primaryTwo,
            colorScheme: ColorScheme.light(primary: primaryTwo),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      final now = DateTime.now();
      var pickedDateTime = DateTime(
          now.year, now.month, now.day, pickedTime.hour, pickedTime.minute);
      if (pickedDateTime.isBefore(now)) {
        pickedDateTime = pickedDateTime.add(const Duration(days: 1));
      }

      await _scheduleNotification(
        'Reminder: ${widget.groupGoal.goalName}',
        'Time to save for your goal "${widget.groupGoal.goalName}"',
        pickedDateTime,
      );

      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [0, 200, 100, 200]);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder set for ${pickedTime.format(context)}'),
          backgroundColor: primaryTwo,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showContributors(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Contributors to "${widget.groupGoal.goalName}"',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryTwo,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildContributorsList(),
              if (widget.groupGoal.contributors.isNotEmpty) _buildCloseButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContributorsList() {
    if (widget.groupGoal.contributors.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'No contributions yet.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: widget.groupGoal.contributors.length,
        itemBuilder: (context, index) {
          final contributor = widget.groupGoal.contributors[index];
          return Card(
            elevation: 1,
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            color: Colors.grey[50],
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: primaryColor,
                child: Text(
                  contributor.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                contributor.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                contributor.date.toLocal().toString().split(' ')[0],
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              trailing: Text(
                'UGX ${contributor.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: primaryTwo,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCloseButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTwo,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: const Text('Close'),
      ),
    );
  }

  void _showContributionDialog() {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Contribution',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryTwo,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (UGX)',
                  border: const OutlineInputBorder(),
                  prefixText: 'UGX ',
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final amount = double.tryParse(amountController.text);
                      if (amount != null && amount > 0) {
                        final updatedGoal = widget.groupGoal.copyWith(
                          currentAmount:
                              widget.groupGoal.currentAmount + amount,
                          contributors: [
                            ...widget.groupGoal.contributors,
                            Contributor(
                              name: 'You',
                              amount: amount,
                              date: DateTime.now(),
                            ),
                          ],
                        );

                        widget.onGoalUpdated?.call(updatedGoal);
                        widget.onContributionAdded?.call();

                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Contribution added successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid amount'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTwo,
                    ),
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editGoal() async {
    if (widget.groupGoal.goalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot edit goal: wait 24 hours'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditGroupGoalScreen(
          goalId: widget.groupGoal.goalId!,
          goalName: widget.groupGoal.goalName,
          currentAmount: widget.groupGoal.currentAmount,
        ),
      ),
    );

    if (result != null) {
      widget.onEditResult?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Improved soft pastel gradient background
    final backgroundGradient = LinearGradient(
      colors: [
        Colors.white,
        primaryTwo.withOpacity(0.1),
        primaryColor.withOpacity(0.05),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0.0, 0.7, 1.0],
    );

    return GestureDetector(
      onTap: () => _showContributors(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: backgroundGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: primaryTwo.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGoalHeader(),
              if (widget.groupGoal.status != null) _buildStatusIndicator(),
              const SizedBox(height: 12),
              _buildProgressBar(),
              const SizedBox(height: 12),
              _buildAmountInfo(),
              if (widget.groupGoal.startDate != null &&
                  widget.groupGoal.endDate != null)
                _buildDateRange(),
              const SizedBox(height: 12),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            widget.groupGoal.goalName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Row(
          children: [
            if (widget.groupGoal.status == 'active')
              IconButton(
                onPressed: () => _setReminder(context),
                icon: Icon(Icons.alarm, color: primaryTwo, size: 24),
                splashRadius: 20,
              ),
            IconButton(
              onPressed: _editGoal,
              icon: Icon(Icons.edit, color: primaryTwo, size: 24),
              splashRadius: 20,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        'Status: ${widget.groupGoal.status!.toUpperCase()}',
        style: TextStyle(
          color: widget.groupGoal.status == 'active'
              ? Colors.green
              : Colors.orange,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Stack(
      children: [
        LinearProgressIndicator(
          value: widget.groupGoal.progressPercentage / 100,
          backgroundColor: Colors.grey[200],
          color: primaryTwo.withOpacity(0.3),
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
        LinearProgressIndicator(
          value: widget.groupGoal.progressPercentage / 100,
          backgroundColor: Colors.transparent,
          color: primaryTwo,
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
      ],
    );
  }

  Widget _buildAmountInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "${widget.groupGoal.progressPercentage.toStringAsFixed(1)}%",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: primaryTwo,
          ),
        ),
        Text(
          "UGX ${widget.groupGoal.currentAmount.toStringAsFixed(0)} / ${widget.groupGoal.goalAmount.toStringAsFixed(0)}",
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDateRange() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        '${DateTime.parse(widget.groupGoal.startDate!).toLocal().toString().split(' ')[0]} - '
        '${DateTime.parse(widget.groupGoal.endDate!).toLocal().toString().split(' ')[0]}',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (widget.groupGoal.status == 'active')
          ElevatedButton(
            onPressed: _showContributionDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Contribute'),
          ),
        GestureDetector(
          onTap: () => _showContributors(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'View Contributors (${widget.groupGoal.contributors.length})',
              style: TextStyle(
                color: primaryTwo,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
