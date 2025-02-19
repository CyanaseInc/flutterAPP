import 'package:flutter/material.dart';
import 'package:cyanase/helpers/loader.dart'; // Import your loader widget
import 'package:cyanase/theme/theme.dart'; // Import your theme file
import 'package:cyanase/helpers/database_helper.dart'; // Import the database helper
import 'package:cyanase/helpers/api_helper.dart'; // Import the API helper
import 'package:flutter_svg/flutter_svg.dart';

class RiskProfilerForm extends StatefulWidget {
  @override
  _RiskProfilerFormState createState() => _RiskProfilerFormState();
}

class _RiskProfilerFormState extends State<RiskProfilerForm> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<int?> selectedOptions =
      List.filled(11, null); // Track selected options for each question
  bool _isLoading = false; // Track loading state

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
    {
      "question": "Which of the following best describes your Goal?",
      "options": [
        "Preferably guaranteed returns, Before Tax Savings",
        "Stable, reliable returns, Minimal Tax Savings",
        "Moderate Variability in returns, Reasonable Tax Savings",
        "Unstable but potentially high returns, Maximize Tax Savings"
      ],
      "points": [2, 3, 5, 7],
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
      body: Stack(
        children: [
          Column(
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
                        isLoading: _isLoading,
                        onSubmit: submitRiskProfile, // Pass the submit function
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
          // Show loading spinner and overlay if isLoading is true
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5), // Semi-transparent overlay
              child: Center(
                child: Loader(),
              ),
            ),
        ],
      ),
    );
  }

  // Function to submit the risk profile to the backend
  Future<void> submitRiskProfile(BuildContext context,
      List<int?> selectedOptions, List<Map<String, dynamic>> questions) async {
    try {
      setState(() {
        _isLoading = true; // Show loading spinner
      });

      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);

      if (userProfile.isNotEmpty) {
        final token = userProfile.first['token'] as String;

        // Calculate the total score
        int totalScore = calculateTotalScore(selectedOptions, questions);

        // Determine the investor profile based on the total score
        String investorProfile = determineInvestorProfile(totalScore);

        // Determine asset allocation based on the total score

        // Prepare the data to send to the backend
        final Map<String, dynamic> requestData = {
          "qn1": selectedOptions[0] != null
              ? questions[0]["points"][selectedOptions[0]!]
              : null,
          "qn2": selectedOptions[1] != null
              ? questions[1]["points"][selectedOptions[1]!]
              : null,
          "qn3": selectedOptions[2] != null
              ? questions[2]["points"][selectedOptions[2]!]
              : null,
          "qn4": selectedOptions[3] != null
              ? questions[3]["points"][selectedOptions[3]!]
              : null,
          "qn5": selectedOptions[4] != null
              ? questions[4]["points"][selectedOptions[4]!]
              : null,
          "qn6": selectedOptions[5] != null
              ? questions[5]["points"][selectedOptions[5]!]
              : null,
          "qn7": selectedOptions[6] != null
              ? questions[6]["points"][selectedOptions[6]!]
              : null,
          "qn8": selectedOptions[7] != null
              ? questions[7]["points"][selectedOptions[7]!]
              : null,
          "qn9": selectedOptions[8] != null
              ? questions[8]["points"][selectedOptions[8]!]
              : null,
          "qn10": selectedOptions[9] != null
              ? questions[9]["points"][selectedOptions[9]!]
              : null,
          "qn11": selectedOptions[10] != null
              ? questions[10]["points"][selectedOptions[10]!]
              : null,
          "score": totalScore, // Include the total score
          "risk_analysis": investorProfile, // Include the investor profile
          // Include the asset allocation
        };

        // Send the data to the backend
        final response = await ApiService.submitRiskProfile(token, requestData);

        if (response['success'] == true) {
          // Show a success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Risk profile submitted successfully!"),
              duration: Duration(seconds: 2), // Duration of the success message
            ),
          );

          // Wait for 1 second before navigating back to the previous screen
          Future.delayed(Duration(seconds: 2), () {
            Navigator.pop(context); // Navigate back to the previous screen
          });
        } else {
          // Show an error message
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text("Failed to submit risk profile: ${response['message']}"),
            duration: Duration(seconds: 2),
          ));
        }
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("An error occurred: $e"),
        duration: Duration(seconds: 2),
      ));
    } finally {
      setState(() {
        _isLoading = false; // Hide loading spinner
      });
    }
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
  final bool isLoading;
  final Function(BuildContext, List<int?>, List<Map<String, dynamic>>) onSubmit;

  const ResultScreen({
    Key? key,
    required this.selectedOptions,
    required this.questions,
    required this.isLoading,
    required this.onSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate the total score
    int totalScore = calculateTotalScore(selectedOptions, questions);

    // Determine the investor profile and asset allocation
    String investorProfile = determineInvestorProfile(totalScore);
    Map<String, double> assetAllocation = determineAssetAllocation(totalScore);

    return Scaffold(
      backgroundColor: Colors.white, // WhatsApp-like background
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Success Image
                Image.asset(
                  'assets/images/done.png',
                  width: 120,
                  height: 100,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),

                // Success Message
                Text(
                  " Based on our analysis, your investor type is:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Investor Profile
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green[50], // Light green background
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$investorProfile Investor',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800], // Dark green text
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Asset Allocation Section
                Text(
                  "Recommended Asset Allocation",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 10),

                // Asset Allocation Items
                _buildAssetAllocationCard("Cash", assetAllocation["cash"]),
                _buildAssetAllocationCard("Credit", assetAllocation["credit"]),
                _buildAssetAllocationCard(
                    "Venture", assetAllocation["venture"]),
                _buildAssetAllocationCard(
                    "Absolute Return", assetAllocation["absolute_return"]),
                const SizedBox(height: 12),

                // Submit Button
                ElevatedButton(
                  onPressed: () {
                    onSubmit(context, selectedOptions, questions);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTwo, // WhatsApp green
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    "Submit",
                    style: TextStyle(fontSize: 16, color: white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Helper method to build asset allocation cards
  Widget _buildAssetAllocationCard(String label, double? percentage) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            Text(
              "${(percentage ?? 0 * 100).toStringAsFixed(1)}%",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

// Helper function to create Asset Allocation Items
}

// Helper function to calculate the total score
int calculateTotalScore(
    List<int?> selectedOptions, List<Map<String, dynamic>> questions) {
  int totalScore = 0;
  for (int i = 0; i < questions.length; i++) {
    if (selectedOptions[i] != null) {
      totalScore += (questions[i]["points"][selectedOptions[i]!] as int);
    }
  }
  return totalScore;
}

// Helper function to determine the investor profile
String determineInvestorProfile(int totalScore) {
  if (totalScore <= 28) {
    return "Low/Conservative";
  } else if (totalScore <= 40) {
    return "Moderate";
  } else if (totalScore <= 50) {
    return "Assertive (Growth)";
  } else {
    return "Aggressive";
  }
}

// Helper function to determine asset allocation
Map<String, double> determineAssetAllocation(int totalScore) {
  if (totalScore >= 18 && totalScore <= 23) {
    return {
      "cash": 40.0,
      "credit": 45.0,
      "venture": 10.0,
      "absolute_return": 5.0,
    };
  } else if (totalScore >= 24 && totalScore <= 28) {
    return {
      "cash": 30.0,
      "credit": 50.0,
      "venture": 15.0,
      "absolute_return": 5.0,
    };
  } else if (totalScore >= 29 && totalScore <= 34) {
    return {
      "cash": 25.0,
      "credit": 50.0,
      "venture": 17.5,
      "absolute_return": 7.5,
    };
  } else if (totalScore >= 35 && totalScore <= 40) {
    return {
      "cash": 15.0,
      "credit": 55.0,
      "venture": 20.0,
      "absolute_return": 10.0,
    };
  } else if (totalScore >= 41 && totalScore <= 45) {
    return {
      "cash": 15.0,
      "credit": 40.0,
      "venture": 30.0,
      "absolute_return": 15.0,
    };
  } else if (totalScore >= 46 && totalScore <= 50) {
    return {
      "cash": 10.0,
      "credit": 35.0,
      "venture": 35.0,
      "absolute_return": 20.0,
    };
  } else if (totalScore >= 51 && totalScore <= 55) {
    return {
      "cash": 10.0,
      "credit": 20.0,
      "venture": 40.0,
      "absolute_return": 30.0,
    };
  } else if (totalScore >= 56 && totalScore <= 60) {
    return {
      "cash": 5.0,
      "credit": 15.0,
      "venture": 35.0,
      "absolute_return": 45.0,
    };
  } else {
    // Default allocation for scores outside the defined ranges
    return {
      "cash": 0.0,
      "credit": 0.0,
      "venture": 0.0,
      "absolute_return": 0.0,
    };
  }
}
