import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';
import './group_saving_goal.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:intl/intl.dart';

class AddGroupGoalScreen extends StatefulWidget {
  final int groupId;
  const AddGroupGoalScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  State<AddGroupGoalScreen> createState() => _AddGroupGoalScreenState();
}

class _AddGroupGoalScreenState extends State<AddGroupGoalScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _goalNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  String? _selectedGoalType = 'Community Project';
  TimeOfDay _reminderTime = TimeOfDay.now();
  String _selectedDay = 'Monday';
  double _progress = 0.0;
  bool _isSubmitting = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _pageController.dispose();
    _goalNameController.dispose();
    _amountController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryTwo,
        elevation: 0,
        title: const Text(
          "New Group Goal",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(primaryTwo),
              minHeight: 8,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _progress = (page + 1) / 4);
                },
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_progress > 0)
            ElevatedButton(
              style: _navigationButtonStyle(Colors.grey[300]!, Colors.black87),
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text("Back"),
            )
          else
            const SizedBox(width: 0),
          ElevatedButton(
            style: _navigationButtonStyle(primaryTwo, Colors.white),
            onPressed: _isSubmitting ? null : _handleNextOrSubmit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(_progress == 1 ? "Finish" : "Next"),
          ),
        ],
      ),
    );
  }

  ButtonStyle _navigationButtonStyle(Color bgColor, Color textColor) {
    return ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      foregroundColor: textColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      elevation: _progress == 1 ? 2 : 0,
    );
  }

  Widget _buildStep1() {
    return _buildCard(
      title: "Goal Type",
      subtitle: "Choose a common group goal or customize your own",
      content: Column(
        children: [
          RadioListTile<String>(
            value: 'Community Project',
            groupValue: _selectedGoalType,
            onChanged: (value) => setState(() => _selectedGoalType = value),
            title: const Text("Community Project (e.g., School Fund)"),
            activeColor: primaryTwo,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<String>(
            value: 'Group Event',
            groupValue: _selectedGoalType,
            onChanged: (value) => setState(() => _selectedGoalType = value),
            title: const Text("Group Event (e.g., Party)"),
            activeColor: primaryTwo,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<String>(
            value: 'Shared Purchase',
            groupValue: _selectedGoalType,
            onChanged: (value) => setState(() => _selectedGoalType = value),
            title: const Text("Shared Purchase (e.g., Equipment)"),
            activeColor: primaryTwo,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<String>(
            value: 'Custom',
            groupValue: _selectedGoalType,
            onChanged: (value) => setState(() => _selectedGoalType = value),
            title: const Text("Custom Goal"),
            activeColor: primaryTwo,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return _buildCard(
      title: "Goal Details",
      subtitle: "Name your group goal and set a target",
      content: Column(
        children: [
          TextField(
            controller: _goalNameController,
            decoration: _inputDecoration(
              hintText: _selectedGoalType == 'Custom'
                  ? "Goal Name (e.g., Village Well)"
                  : "Goal Name",
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(
              hintText: "Target Amount (e.g., 10,000,000)",
              prefixText: "UGX ",
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(
              hintText: "Duration (months)",
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                final months = int.tryParse(value) ?? 1;
                setState(() {
                  _startDate = DateTime.now();
                  _endDate = _startDate!.add(Duration(days: months * 30));
                });
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Start Date:",
                style: TextStyle(color: Colors.grey[600]),
              ),
              Text(
                _startDate != null
                    ? DateFormat('MMM d, y').format(_startDate!)
                    : "Not set",
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "End Date:",
                style: TextStyle(color: Colors.grey[600]),
              ),
              Text(
                _endDate != null
                    ? DateFormat('MMM d, y').format(_endDate!)
                    : "Not set",
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return _buildCard(
      title: "Set a Reminder",
      subtitle: "Keep the group on track with a reminder",
      content: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _selectedDay,
            onChanged: (String? newValue) =>
                setState(() => _selectedDay = newValue!),
            decoration: _inputDecoration(
              labelText: "Day of the Week",
              filled: true,
            ),
            items: <String>[
              'Monday',
              'Tuesday',
              'Wednesday',
              'Thursday',
              'Friday',
              'Saturday',
              'Sunday'
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final TimeOfDay? time = await showTimePicker(
                context: context,
                initialTime: _reminderTime,
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.light().copyWith(
                      primaryColor: primaryTwo,
                      colorScheme: ColorScheme.light(primary: primaryTwo),
                      buttonTheme: const ButtonThemeData(
                        textTheme: ButtonTextTheme.primary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (time != null && time != _reminderTime) {
                setState(() => _reminderTime = time);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTwo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Text("Pick Time: ${_reminderTime.format(context)}"),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    final targetAmount = double.tryParse(_amountController.text) ?? 0.0;
    final durationMonths = int.tryParse(_durationController.text) ?? 1;
    final monthlySavings = targetAmount / durationMonths;
    final interestRate = 0.05;
    final projectedSavings = targetAmount * (1 + interestRate);

    return _buildCard(
      title: "Review Your Group Goal",
      subtitle: "Check the details and projected savings",
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReviewRow("Goal Type", _selectedGoalType ?? "Custom"),
          _buildReviewRow("Goal Name", _goalNameController.text),
          _buildReviewRow("Target Amount", "UGX ${_amountController.text}"),
          _buildReviewRow("Duration", "$durationMonths months"),
          if (_startDate != null && _endDate != null)
            _buildReviewRow(
              "Timeframe",
              "${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d, y').format(_endDate!)}",
            ),
          _buildReviewRow(
            "Reminder",
            "$_selectedDay at ${_reminderTime.format(context)}",
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            "Group Contribution Breakdown:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          if (_selectedGoalType != 'Custom')
            Text(
              "This is a default group goal type: $_selectedGoalType",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            "The group needs to save ~UGX ${monthlySavings.toStringAsFixed(2)} per month.",
            style: TextStyle(
              fontSize: 16,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "With a ${interestRate * 100}% interest rate, the group could reach ~UGX ${projectedSavings.toStringAsFixed(2)}.",
            style: const TextStyle(
              fontSize: 16,
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          content,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hintText,
    String? labelText,
    String? prefixText,
    bool filled = true,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      prefixText: prefixText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryTwo, width: 2),
      ),
      filled: filled,
      fillColor: filled ? Colors.grey[50] : null,
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value.isEmpty ? "Not Set" : value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNextOrSubmit() {
    if (_progress < 1) {
      if (_validateCurrentStep()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _showConfirmationDialog();
    }
  }

  bool _validateCurrentStep() {
    if (_progress == 0.25) {
      if (_selectedGoalType == null) {
        _showError("Please select a goal type");
        return false;
      }
    } else if (_progress == 0.5) {
      if (_goalNameController.text.isEmpty ||
          _amountController.text.isEmpty ||
          _durationController.text.isEmpty) {
        _showError("Please fill all required fields");
        return false;
      }
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Start Group Contributions?",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryTwo,
            ),
          ),
          content:
              const Text("Would you like to invite members to contribute now?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _submitGoal();
              },
              child: Text(
                "Not Now",
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _submitGoal().then((_) {
                  if (!_isSubmitting) {
                    Navigator.pushNamed(context, '/groupInviteScreen');
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTwo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitGoal() async {
    if (!_validateCurrentStep()) return;

    setState(() => _isSubmitting = true);

    // Create optimistic goal object
    final goalName = _selectedGoalType == 'Custom'
        ? _goalNameController.text
        : _goalNameController.text.isEmpty
            ? _selectedGoalType!
            : _goalNameController.text;

    final optimisticGoal = GroupSavingGoal(
      goalName: goalName,
      goalAmount: double.parse(_amountController.text),
      currentAmount: 0.0,
      startDate: _startDate?.toIso8601String(),
      endDate: _endDate?.toIso8601String(),
      status: 'active',
    );

    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);

      if (userProfile.isEmpty) throw Exception('No user profile found');

      final token = userProfile.first['token'] as String;
      final data = {
        'group_id': widget.groupId,
        'goal_name': goalName,
        'goal_period': _durationController.text,
        'goal_amount': _amountController.text,
        'deposit_type': _selectedGoalType == 'Weekly' ? 'manual' : 'auto',
        'reminder_day': _selectedDay,
        'reminder_time': '${_reminderTime.hour}:${_reminderTime.minute}',
        'goal_type': _selectedGoalType,
        'start_date': _startDate?.toIso8601String(),
        'end_date': _endDate?.toIso8601String(),
      };

      final response = await ApiService.CreateGroupGoal(token, data, null);

      if (response['success'] == true) {
        await _scheduleNotification();

        // Return the complete goal with ID from server if available
        final createdGoal = optimisticGoal.copyWith(
          goalId: response['goal_id'],
        );

        if (!mounted) return;
        Navigator.pop(context, createdGoal);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group goal saved successfully!'),
            backgroundColor: primaryTwo,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception('Failed to save group goal: ${response['message']}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save goal: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Return just true to trigger a refresh
      Navigator.pop(context, true);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _scheduleNotification() async {
    try {
      // Find next occurrence of selected day
      final now = DateTime.now();
      var notificationDate = DateTime(
        now.year,
        now.month,
        now.day,
        _reminderTime.hour,
        _reminderTime.minute,
      );

      // If time already passed today, schedule for next week
      if (notificationDate.isBefore(now)) {
        notificationDate = notificationDate.add(const Duration(days: 7));
      }

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _generateNotificationId(),
          channelKey: 'scheduled_notifications',
          title: 'Group Goal Reminder: ${_goalNameController.text}',
          body: 'Time to contribute to your group savings goal',
        ),
        schedule: NotificationCalendar.fromDate(date: notificationDate),
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  int _generateNotificationId() {
    return DateTime.now().millisecondsSinceEpoch.remainder(100000);
  }
}
