import 'package:cyanase/helpers/loader.dart';
import 'package:cyanase/helpers/web_db.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cyanase/theme/theme.dart';
import 'dart:io';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/get_currency.dart';
import 'package:intl/intl.dart'; // For number formatting
import 'package:awesome_notifications/awesome_notifications.dart'; // For notifications

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({Key? key}) : super(key: key);

  @override
  _AddGoalScreenState createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? goalName;
  String? savingFrequency = 'Weekly';
  double? goalAmount;
  File? goalImage;
  String? reminderDay;
  TimeOfDay reminderTime = TimeOfDay.now();
  final TextEditingController _customGoalController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _goalPeriodController = TextEditingController();
  bool _isSubmitting = false;
  String? currency; // Dynamic currency

  final List<String> _defaultGoals = [
    'Retirement',
    'Buy a House',
    'Buy Land',
    'Emergency Fund',
  ];

  @override
  void initState() {
    super.initState();
    reminderDay = savingFrequency == 'Weekly' ? 'Monday' : '1';
    _customGoalController.addListener(() => setState(() {}));
    _amountController.addListener(() => setState(() {}));
    _goalPeriodController.addListener(() => setState(() {}));
    _fetchCurrency(); // Fetch currency dynamically
    _initializeNotifications(); // Initialize notifications
  }

  @override
  void dispose() {
    _customGoalController.dispose();
    _amountController.dispose();
    _goalPeriodController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Fetch currency from the user's profile
  Future<void> _fetchCurrency() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);

      if (userProfile.isNotEmpty) {
        final userCountry = userProfile.first['country'] as String;
        setState(() {
          currency = CurrencyHelper.getCurrencyCode(userCountry);
        });
      }
    } catch (e) {
      print('Error fetching currency: $e');
    }
  }

  // Initialize notifications
  Future<void> _initializeNotifications() async {
    await AwesomeNotifications().initialize(
      null, // Use default app icon
      [
        NotificationChannel(
          channelKey: 'scheduled_notifications',
          channelName: 'Scheduled Notifications',
          channelDescription: 'Notifications for saving goal reminders',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: white,
          importance: NotificationImportance.High,
          soundSource:
              'resource://raw/notification_sound', // Optional: Add a custom sound
        ),
      ],
    );

    await AwesomeNotifications().requestPermissionToSendNotifications();

    // Set up notification listeners
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: (ReceivedAction receivedAction) async {
        // Handle when the user taps the notification
        print('Notification tapped: ${receivedAction.payload}');
      },
      onNotificationDisplayedMethod:
          (ReceivedNotification receivedNotification) async {
        // Handle when the notification is displayed
        print('Notification displayed: ${receivedNotification.id}');
      },
    );
  }

  // Schedule a notification
  Future<void> _scheduleNotification() async {
    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      reminderTime.hour,
      reminderTime.minute,
    );

    // If the scheduled time is in the past, add a day
    if (scheduledTime.isBefore(now)) {
      scheduledTime.add(const Duration(days: 1));
    }

    final goalName = this.goalName ?? _customGoalController.text;
    final goalAmount = double.tryParse(_amountController.text) ?? 0;
    final savedAmount =
        0.0; // Replace with actual saved amount from the database
    final balanceLeft = goalAmount - savedAmount;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _getUniqueID(),
        channelKey: 'scheduled_notifications',
        title: 'Savings Goal Reminder',
        body:
            'Hey Vianney, it\'s time to save for $goalName! You have ${NumberFormat.currency(symbol: currency ?? '\$').format(balanceLeft)} left. Let\'s gooo! 🚀',
      ),
      schedule: NotificationCalendar.fromDate(date: scheduledTime),
    );
  }

  // Generate a unique ID for notifications
  int _getUniqueID() {
    return DateTime.now().microsecondsSinceEpoch.remainder(100000);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryTwo,
        elevation: 0,
        title: const Text(
          'New Savings Goal',
          style: TextStyle(color: white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              LinearProgressIndicator(
                value: (_currentPage + 1) / 5,
                backgroundColor: primaryColor,
                color: primaryTwo,
                minHeight: 4,
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                    _buildStep4(),
                    _buildStep5(),
                  ],
                ),
              ),
              _buildNavigationButtons(),
            ],
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Loader(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBubbleCard({required String title, required Widget content}) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryTwo,
                ),
              ),
              const SizedBox(height: 12),
              content,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return _buildBubbleCard(
      title: 'What’s your savings goal?',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._defaultGoals.map((goal) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton(
                onPressed: () {
                  setState(() => goalName = goal);
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      goalName == goal ? primaryTwo : Colors.grey[200],
                  foregroundColor: goalName == goal ? white : Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(goal),
              ),
            );
          }),
          const SizedBox(height: 16),
          const Text(
            'Not listed? Enter your own goal',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _customGoalController,
            decoration: InputDecoration(
              hintText: 'Enter goal',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: primaryTwo),
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return _buildBubbleCard(
      title: 'How often will you save?',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...['Weekly', 'Monthly'].map((freq) {
            return RadioListTile<String>(
              value: freq,
              groupValue: savingFrequency,
              onChanged: (value) {
                setState(() {
                  savingFrequency = value;
                  reminderDay = value == 'Weekly' ? 'Monday' : '1';
                });
              },
              title: Text(freq, style: const TextStyle(fontSize: 16)),
              activeColor: primaryTwo,
            );
          }),
          const SizedBox(height: 16),
          const Text(
            'How long do you want to save? (in months)',
            style: TextStyle(
              fontSize: 16,
              color: primaryTwo,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _goalPeriodController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter months (e.g., 12)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: primaryTwo),
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onSubmitted: (value) {
              if (savingFrequency != null && value.isNotEmpty) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (savingFrequency != null &&
                  _goalPeriodController.text.isNotEmpty) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTwo,
              foregroundColor: white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return _buildBubbleCard(
      title: 'Set your goal details',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter amount (e.g., 10000)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: primaryTwo),
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Add a photo to personalize your goal!',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[400]!, width: 1),
              ),
              child: goalImage == null
                  ? const Center(
                      child:
                          Icon(Icons.add_a_photo, color: primaryTwo, size: 40),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(goalImage!, fit: BoxFit.cover),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    final reminderOptions = savingFrequency == 'Weekly'
        ? [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday'
          ]
        : List.generate(28, (i) => (i + 1).toString());

    return _buildBubbleCard(
      title: 'When should we remind you?',
      content: Column(
        children: [
          DropdownButtonFormField<String>(
            value: reminderDay,
            onChanged: (value) => setState(() => reminderDay = value),
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              labelText:
                  savingFrequency == 'Weekly' ? 'Day of Week' : 'Day of Month',
            ),
            items: reminderOptions
                .map((value) =>
                    DropdownMenuItem(value: value, child: Text(value)))
                .toList(),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _pickTime,
            icon: const Icon(Icons.access_time),
            label: Text('Set Time: ${reminderTime.format(context)}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTwo,
              foregroundColor: white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep5() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final period = double.tryParse(_goalPeriodController.text) ?? 1;
    final savingsPerPeriod = savingFrequency == 'Weekly'
        ? amount / (period * 4.33)
        : amount / period;

    // Format the amount with commas and dynamic currency
    final NumberFormat currencyFormat = NumberFormat.currency(
      symbol: currency ?? '\$', // Use dynamic currency or fallback to '$'
      decimalDigits: 2,
    );

    return _buildBubbleCard(
      title: 'Review Your Goal',
      content: Column(
        children: [
          if (goalImage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(
                    goalImage!,
                    height: 150,
                    width: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          _buildReviewItem('Goal', goalName ?? _customGoalController.text),
          _buildReviewItem('Amount', currencyFormat.format(amount)),
          _buildReviewItem('Frequency', savingFrequency!),
          _buildReviewItem('Period', '$period months'),
          _buildReviewItem(
              'Reminder', '$reminderDay at ${reminderTime.format(context)}'),
          const SizedBox(height: 16),
          Text(
            savingFrequency == 'Weekly'
                ? 'Save ${currencyFormat.format(savingsPerPeriod)} weekly'
                : 'Save ${currencyFormat.format(savingsPerPeriod)} monthly',
            style: const TextStyle(color: Colors.green, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final isNextActive = _validateStep();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              child: const Text('Back', style: TextStyle(color: primaryTwo)),
            ),
          ElevatedButton(
            onPressed: isNextActive
                ? () {
                    if (_currentPage == 4) {
                      _submitGoal();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isNextActive ? primaryTwo : Colors.grey[400],
              foregroundColor: white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              minimumSize: const Size(120, 50),
            ),
            child: Text(_currentPage == 4 ? 'Save Goal' : 'Next'),
          ),
        ],
      ),
    );
  }

  bool _validateStep() {
    switch (_currentPage) {
      case 0:
        return goalName != null || _customGoalController.text.isNotEmpty;
      case 1:
        return savingFrequency != null && _goalPeriodController.text.isNotEmpty;
      case 2:
        return _amountController.text.isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => goalImage = File(pickedFile.path));
    }
  }

  Future<void> _pickTime() async {
    final time =
        await showTimePicker(context: context, initialTime: reminderTime);
    if (time != null) {
      setState(() => reminderTime = time);
    }
  }

  Future<void> _submitGoal() async {
    final finalGoalName = goalName ?? _customGoalController.text;
    final goalAmountText = _amountController.text;
    final depositType = savingFrequency == 'Weekly' ? 'manual' : 'auto';
    final goalPeriodText = _goalPeriodController.text;

    if (finalGoalName.isEmpty ||
        goalAmountText.isEmpty ||
        goalPeriodText.isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // final dbHelper = DatabaseHelper();
      // final db = await dbHelper.database;
      // final userProfile = await db.query('profile', limit: 1);
      await WebSharedStorage.init();
      var existingProfile = WebSharedStorage();

      final token = existingProfile.getCommon('token');

      // if (userProfile.isEmpty) {
      //   throw Exception('No user profile found');
      // }

      // final token = userProfile.first['token'] as String;

      // Save reminder data
      final data = {
        'goal_name': finalGoalName,
        'goal_period': goalPeriodText,
        'goal_amount': goalAmountText,
        'deposit_type': depositType,
        'reminder_day': reminderDay,
        'reminder_time': '${reminderTime.hour}:${reminderTime.minute}',
      };

      final response = await ApiService.CreateGoal(token, data, goalImage);

      if (response['success'] == true) {
        // Schedule the notification
        await _scheduleNotification();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error in _submitGoal: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}
