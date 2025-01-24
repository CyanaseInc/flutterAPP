import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart'; // Import your theme file

class RiskProfilerForm extends StatefulWidget {
  @override
  _RiskProfilerFormState createState() => _RiskProfilerFormState();
}

class _RiskProfilerFormState extends State<RiskProfilerForm> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<int?> selectedOptions =
      List.filled(11, null); // Track selected options for each question

  final List<Map<String, dynamic>> questions = [
    {
      "question": "What are your objectives for investing?",
      "options": [
        "Saving",
        "Retirement",
        "Capital Preservation",
        "Profit Generation"
      ],
      "points": [2, 3, 5, 7],
    },
    {
      "question": "What is your investment time horizon?",
      "options": ["< 1 year", "1 – 2 years", "2 – 5 years", "> 5 years"],
      "points": [1, 2, 3, 5],
    },
    {
      "question": "Where have you invested in the past?",
      "options": ["Treasuries", "Credit", "Alternatives", "Listed Equities"],
      "points": [1, 2, 3, 5],
    },
    {
      "question": "What would you hold as a maximum loss to your portfolio?",
      "options": ["< 10%", "10-15%", "15-20%", "Up to 25%"],
      "points": [2, 3, 5, 7],
    },
    {
      "question": "How much capital are you considering to invest?",
      "options": ["\$1k - \$2k", "\$2k - \$5k", "\$5k - \$10k", "> \$10k"],
      "points": [2, 3, 5, 7],
    },
    {
      "question": "What is your source of funds?",
      "options": [
        "Employment",
        "Inheritance / Gift",
        "Savings / Superannuation",
        "Other"
      ],
      "points": [1, 2, 3, 5],
    },
    {
      "question": "Which of the following best describes your investment goal?",
      "options": [
        "Preferably guaranteed returns, before tax savings",
        "Stable, reliable returns, minimal tax savings",
        "Moderate variability in returns, reasonable tax savings",
        "Unstable but potentially higher returns, maximize tax savings"
      ],
      "points": [2, 3, 5, 7],
    },
    {
      "question":
          "Are you appropriately covered against personal and/or business risks?",
      "options": ["Yes", "No"],
      "points": [2, 3],
    },
    {
      "question":
          "Would you consider borrowing money to make a future investment?",
      "options": ["Yes", "No"],
      "points": [2, 3],
    },
    {
      "question": "Which option best resonates with you regarding inflation?",
      "options": [
        "I am comfortable with the arrangement to beat inflation",
        "I know the risks associated with inflation, but I would prefer middle ground",
        "It could reduce my savings but I have no tolerance for loss"
      ],
      "points": [5, 3, 2],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Risk Profiler"),
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(
          color: white, // Change the back arrow color to white
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemCount: questions.length + 1, // +1 for the result screen
              itemBuilder: (context, index) {
                if (index < questions.length) {
                  return QuestionSlide(
                    question: questions[index]["question"],
                    options: questions[index]["options"],
                    selectedOption: selectedOptions[index],
                    onOptionSelected: (int selectedIndex) {
                      setState(() {
                        selectedOptions[index] = selectedIndex;
                      });
                      // Auto-slide to the next question
                      if (index < questions.length - 1) {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  );
                } else {
                  // Result Screen
                  return ResultScreen(
                    selectedOptions: selectedOptions,
                    questions: questions,
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  ElevatedButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTwo,
                      foregroundColor: white,
                    ),
                    child: Text("Previous"),
                  ),
                if (_currentPage < questions.length)
                  ElevatedButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTwo,
                      foregroundColor: white,
                    ),
                    child: Text("Next"),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QuestionSlide extends StatelessWidget {
  final String question;
  final List<String> options;
  final int? selectedOption;
  final Function(int) onOptionSelected;

  const QuestionSlide({
    Key? key,
    required this.question,
    required this.options,
    required this.selectedOption,
    required this.onOptionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          SizedBox(height: 20),
          ...options.map((option) {
            int index = options.indexOf(option);
            return RadioListTile<int>(
              title: Text(option),
              value: index,
              groupValue: selectedOption,
              onChanged: (int? value) {
                onOptionSelected(value!);
              },
            );
          }).toList(),
        ],
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final List<int?> selectedOptions;
  final List<Map<String, dynamic>> questions;

  const ResultScreen({
    Key? key,
    required this.selectedOptions,
    required this.questions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate the total score
    int totalScore = 0;
    for (int i = 0; i < questions.length; i++) {
      if (selectedOptions[i] != null) {
        totalScore += (questions[i]["points"][selectedOptions[i]!]
            as int); // Explicitly cast to int
      }
    }

    // Determine the investor profile based on the total score
    String investorProfile;
    if (totalScore <= 28) {
      investorProfile = "Low/Conservative";
    } else if (totalScore <= 40) {
      investorProfile = "Moderate";
    } else if (totalScore <= 50) {
      investorProfile = "Assertive (Growth)";
    } else {
      investorProfile = "Aggressive";
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "You have successfully completed your risk profile and from our analysis you are:",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 5),
            Text(
              ' $investorProfile investor',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),

            SizedBox(height: 10), // Add some spacing
            ElevatedButton(
              onPressed: () {
                // Action to perform when the submit button is pressed
                _onSubmit(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTwo, // Use your theme color
                foregroundColor: white,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Submit",
                style: TextStyle(fontSize: 18, color: primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to handle the submit action
  void _onSubmit(BuildContext context) {
    // For now, just close the form or navigate back
    Navigator.pop(context); // Close the form and go back to the previous screen

    // Optionally, you can show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Your risk profile has been submitted!"),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
