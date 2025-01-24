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
  TextEditingController durationController = TextEditingController();
  TimeOfDay reminderTime = TimeOfDay.now();
  String selectedDay = 'Monday';
  double progress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: white,
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
                      progress = (page + 1) / 4; // 5 steps in total
                    });
                  },
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                    _buildStep4(),
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
                        _showConfirmationDialog();
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
      title: "Enter your goal details:",
      subtitle: "Provide a name, target amount, and duration for your goal.",
      child: Column(
        children: [
          TextField(
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
          SizedBox(height: 16),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Target Amount",
              border: UnderlineInputBorder(),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: primaryTwo),
              ),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: durationController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Duration (in months)",
              border: UnderlineInputBorder(),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: primaryTwo),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return _buildCard(
      title: "Set a reminder to save:",
      subtitle: "Choose a day and time to stay consistent with your savings.",
      child: Column(
        children: [
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

  Widget _buildStep4() {
    double targetAmount = double.tryParse(amountController.text) ?? 0.0;
    int durationMonths = int.tryParse(durationController.text) ?? 1;
    double weeklySavings = targetAmount / (durationMonths * 4.33);
    double monthlySavings = targetAmount / durationMonths;
    double interestRate = 0.05; // Example interest rate of 5%
    double projectedSavings = targetAmount * (1 + interestRate);

    return _buildCard(
      title: "Review and Calculate Savings:",
      subtitle:
          "Ensure all details are correct and see your savings breakdown.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Goal Name: ${goalNameController.text}",
            style: TextStyle(fontSize: 16),
          ),
          Text(
            "Target Amount: ${amountController.text}",
            style: TextStyle(fontSize: 16),
          ),
          Text(
            "Duration: $durationMonths months",
            style: TextStyle(fontSize: 16),
          ),
          Text(
            "Saving Frequency: $savingFrequency",
            style: TextStyle(fontSize: 16),
          ),
          Text(
            "Reminder: $selectedDay at ${reminderTime.format(context)}",
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          Divider(),
          SizedBox(height: 16),
          Text(
            "Savings Breakdown:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          SizedBox(height: 8),
          if (savingFrequency == 'Weekly')
            Text(
              "You need to save approximately ${weeklySavings.toStringAsFixed(2)} per week.",
              style: TextStyle(fontSize: 16, color: Colors.green),
            ),
          if (savingFrequency == 'Monthly')
            Text(
              "You need to save approximately ${monthlySavings.toStringAsFixed(2)} per month.",
              style: TextStyle(fontSize: 16, color: Colors.green),
            ),
          SizedBox(height: 8),
          Text(
            "With our interest rate of ${interestRate * 100}%, you will save approximately ${projectedSavings.toStringAsFixed(2)} by the end of your goal.",
            style: TextStyle(fontSize: 16, color: Colors.blueAccent),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Start Depositing Now?"),
          content: Text("Do you want to start depositing now?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _submitGoal();
              },
              child: Text("No"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _submitGoal();
                Navigator.of(context).pushNamed('/depositScreen');
              },
              child: Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  void _submitGoal() {
    // Implement the logic to submit the goal
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
}
