import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';

class AddGoalScreen extends StatefulWidget {
  @override
  _AddGoalScreenState createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  PageController _pageController = PageController();
  String? savingFrequency = 'Weekly';
  TextEditingController goalNameController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TimeOfDay reminderTime = TimeOfDay.now();
  String selectedDay = 'Monday';
  double progress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        title: Text(
          "Add Saving Goal",
          style: TextStyle(fontWeight: FontWeight.w600, color: primaryTwo),
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Slider Progress
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade300,
                  color: primaryTwo,
                ),
              ),
              SizedBox(height: 5),

              // PageView for step navigation
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      progress = (page + 1) / 6; // 6 steps in total
                    });
                  },
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                    _buildStep4(),
                    _buildStep5(),
                    _buildStep6(),
                  ],
                ),
              ),

              // Navigation buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (progress > 0)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTwo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        _pageController.previousPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text("Back"),
                    ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTwo,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      if (progress < 1) {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _submitGoal();
                      }
                    },
                    child: Text(progress == 1 ? "Submit" : "Next"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return _buildCard(
      title: "How often do you want to save?",
      subtitle: "Choose a frequency that suits your saving habits.",
      child: Column(
        children: [
          RadioListTile<String>(
            value: 'Weekly',
            groupValue: savingFrequency,
            onChanged: (value) {
              setState(() {
                savingFrequency = value;
              });
            },
            title: Text(
              "Weekly",
            ),
          ),
          RadioListTile<String>(
            value: 'Monthly',
            groupValue: savingFrequency,
            onChanged: (value) {
              setState(() {
                savingFrequency = value;
              });
            },
            title: Text(
              "Monthly",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return _buildCard(
      title: "Enter your goal name:",
      subtitle: "Give your goal a name to keep track of it easily.",
      child: TextField(
        controller: goalNameController,
        decoration: InputDecoration(
          hintText: "Goal Name",
          border: UnderlineInputBorder(), // Adds a bottom border
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
                color: Colors.grey), // Bottom border color when not focused
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
                color: primaryTwo), // Bottom border color when focused
          ),
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return _buildCard(
      title: "How much do you want to save?",
      subtitle: "Set a target amount to achieve your goal.",
      child: TextField(
        controller: amountController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: "Amount to Save",
          border: UnderlineInputBorder(), // Adds a bottom border
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
                color: Colors.grey), // Bottom border color when not focused
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
                color: primaryTwo), // Bottom border color when focused
          ),
        ),
      ),
    );
  }

  Widget _buildStep4() {
    return _buildCard(
      title: "When do you want to be reminded to save?",
      subtitle: "Set a reminder to stay consistent with your savings.",
      child: Column(
        children: [
          // Day Picker (Dropdown)
          DropdownButtonFormField<String>(
            value: selectedDay,
            onChanged: (String? newValue) {
              setState(() {
                selectedDay = newValue!;
              });
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              labelText: "Select Day",
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
          SizedBox(height: 16), // Add spacing between the two pickers

          // Time Picker (Button)
          ElevatedButton(
            onPressed: () async {
              final TimeOfDay? time = await showTimePicker(
                context: context,
                initialTime: reminderTime,
              );
              if (time != null && time != reminderTime) {
                setState(() {
                  reminderTime = time;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTwo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize:
                  Size(double.infinity, 50), // Make the button full width
            ),
            child: Text("Pick Time: ${reminderTime.format(context)}"),
          ),
        ],
      ),
    );
  }

  Widget _buildStep5() {
    return _buildCard(
      title: "Review your goal details:",
      subtitle: "Confirm all the details before saving your goal.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Goal Name: ${goalNameController.text}",
          ),
          Text(
            "Amount to Save: ${amountController.text}",
          ),
          Text(
            "Saving Frequency: $savingFrequency",
          ),
          Text(
            "Reminder: $selectedDay at ${reminderTime.format(context)}",
          ),
        ],
      ),
    );
  }

  Widget _buildStep6() {
    return _buildCard(
      title: "Would you like to start depositing now?",
      subtitle:
          "You can choose a payment method to make your first deposit immediately.",
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              _showPaymentMethods();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              "Deposit Now",
            ),
          ),
        ],
      ),
    );
  }

  void _submitGoal() {
    // Implement the logic to submit the goal
    // For example, save the goal details to a database or state management
    print("Goal Name: ${goalNameController.text}");
    print("Amount to Save: ${amountController.text}");
    print("Saving Frequency: $savingFrequency");
    print("Reminder: $selectedDay at ${reminderTime.format(context)}");

    // Show a success message or navigate to another screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Goal submitted successfully!",
        ),
      ),
    );
  }

  void _showPaymentMethods() {
    // Implement the logic to show payment methods
    // For example, show a dialog or navigate to a payment screen
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Choose Payment Method",
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  "Credit Card",
                ),
                onTap: () {
                  // Handle credit card payment
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(
                  "PayPal",
                ),
                onTap: () {
                  // Handle PayPal payment
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
