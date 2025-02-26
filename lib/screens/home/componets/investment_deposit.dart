import 'package:cyanase/helpers/loader.dart';
import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import 'package:cyanase/screens/settings/riskprofiler.dart';
import 'package:cyanase/helpers/database_helper.dart'; // Import the database helper
import 'package:cyanase/helpers/api_helper.dart'; // Import the API helper
import 'package:cyanase/helpers/get_currency.dart'; // For making the API call
import 'package:cyanase/helpers/deposit.dart';

class Deposit extends StatefulWidget {
  @override
  _DepositState createState() => _DepositState();
}

class _DepositState extends State<Deposit> {
  PageController _pageController = PageController();
  int currentStep = 0;

  // Data storage
  List<Map<String, dynamic>> _investmentData = []; // Raw API response
  List<String> _fundClasses = []; // List of classes
  List<Map<String, dynamic>> _options =
      []; // Store option details as a Map // List of options under the selected class
  List<String> _fundManagers =
      []; // List of fund managers under the selected option

  // User selections
  String? selectedFundClass;
  Map<String, dynamic>? selectedOption;
  String? selectedFundManager;
  String? depositMethod;
  double? depositAmount;
  String? phoneNumber;

  bool _isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    _fetchInvestmentData(); // Fetch data when the widget initializes
  }

  // Fetch investment data from the API
  Future<void> _fetchInvestmentData() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      final token = userProfile.first['token'] as String;

      // Fetch investment data from the API
      final response = await ApiService.getClasses(token);

      // Ensure the response is a List<Map<String, dynamic>>
      List<Map<String, dynamic>> investmentData;
      investmentData = List<Map<String, dynamic>>.from(response);

      // Update the state with the fetched data
      setState(() {
        _investmentData = investmentData;
        _fundClasses = investmentData
            .map((item) => item['investment_class'] as String)
            .toList();
        _isLoading = false; // Set loading to false after data is fetched
      });
    } catch (e) {
      print('Error fetching investment data: $e');
      setState(() {
        _isLoading = false; // Stop loading even if there's an error
      });
    }
  }

  // Extract options under the selected class
  void _extractOptions(String fundClass) {
    final selectedClassData = _investmentData.firstWhere(
      (item) => item['investment_class'] == fundClass,
      orElse: () => {},
    );

    if (selectedClassData.isNotEmpty) {
      setState(() {
        _options = (selectedClassData['investment_options'] as List)
            .map((option) => {
                  'id': option['investment_option_id'], // Keep it as an int
                  'name': option['investment_option'], // Store option name
                })
            .toList();
      });
    }
  }

  // Extract fund managers under the selected option
  void _extractFundManagers(String option) {
    for (var classData in _investmentData) {
      final options = classData['investment_options'] as List;
      final selectedOptionData = options.firstWhere(
        (opt) => opt['investment_option'] == option,
        orElse: () => {},
      );

      if (selectedOptionData.isNotEmpty) {
        setState(() {
          _fundManagers = [selectedOptionData['handler'] as String];
        });
        break;
      }
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RiskProfilerForm(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryTwo, width: 2),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Edit Risk Profile',
                style: TextStyle(
                  fontSize: 16,
                  color: primaryTwo,
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: Loader()) // Show preloader
                  : PageView(
                      controller: _pageController,
                      onPageChanged: (page) {
                        setState(() {
                          currentStep = page;
                        });
                      },
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        buildFundClassStep(),
                        buildOptionStep(),
                        buildFundManagerStep(),
                        DepositHelper(
                          selectedFundClass: selectedFundClass,
                          selectedOption:
                              selectedOption?['name'], // Pass the option name
                          selectedOptionId:
                              selectedOption?['id'], // Pass the option ID
                          selectedFundManager: selectedFundManager,
                          depositCategory: 'personal_investment',
                        ), // for ID),
                      ],
                    ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                currentStep > 0
                    ? ElevatedButton(
                        onPressed: () {
                          _pageController.previousPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeIn);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTwo,
                          foregroundColor: primaryColor,
                        ),
                        child: Text('Back'),
                      )
                    : SizedBox(),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget buildFundClassStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Select Investment Class',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryTwo,
          ),
        ),
        Text(
          'Choose the type of investment you want to make',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
          softWrap: true,
        ),
        DropdownButton<String>(
          value: selectedFundClass,
          hint: Text('Choose an investment class'),
          items: _fundClasses.map((fundClass) {
            return DropdownMenuItem<String>(
              value: fundClass,
              child: Text(fundClass),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedFundClass = value;
              selectedOption = null;
              selectedFundManager = null;
            });
            _extractOptions(value!); // Extract options for the selected class
            _pageController.nextPage(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeIn,
            );
          },
        ),
      ],
    );
  }

  Widget buildOptionStep() {
    if (selectedFundClass == null) return SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Select Option',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryTwo,
          ),
        ),
        Text(
          'Choose a specific option within the selected investment class',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
          softWrap: true,
        ),
        DropdownButton<Map<String, dynamic>>(
          value: selectedOption,
          hint: Text('Choose an option'),
          items: _options.map((option) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: option, // Store the entire option Map
              child: Text(option['name']), // Display the option name
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedOption = value; // Store the selected option Map
              selectedFundManager = null;
            });
            _extractFundManagers(value!['name']); // Pass the option name
            _pageController.nextPage(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeIn,
            );
          },
        ),
      ],
    );
  }

  Widget buildFundManagerStep() {
    if (selectedOption == null) return SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Select Fund Manager',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryTwo,
          ),
        ),
        Text(
          'Choose a fund manager for your selected option',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
          softWrap: true,
        ),
        DropdownButton<String>(
          value: selectedFundManager,
          hint: Text('Choose a fund manager'),
          items: _fundManagers.map((manager) {
            return DropdownMenuItem<String>(
              value: manager,
              child: Text(manager),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedFundManager = value;
            });
            _pageController.nextPage(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeIn,
            );
          },
        ),
      ],
    );
  }
}
