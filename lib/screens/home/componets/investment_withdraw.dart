import 'package:cyanase/helpers/get_currency.dart';
import 'package:cyanase/helpers/loader.dart';
import 'package:cyanase/helpers/web_db.dart';
import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import 'package:cyanase/helpers/api_helper.dart'; // Import the API helper

class Withdraw extends StatefulWidget {
  @override
  _WithdrawState createState() => _WithdrawState();
}

class _WithdrawState extends State<Withdraw> {
  PageController _pageController = PageController();
  int currentStep = 0;

  // Sample portfolios data
  List<Map<String, dynamic>> portfoliosData = [];

  String? selectedPortfolio;
  String? withdrawMethod;
  String? phoneNumber;
  String? bankDetails;
  double? withdrawAmount;

  bool isLoading = false; // Flag to track if the withdrawal is in progress

  @override
  void initState() {
    super.initState();
    _userTrack(); // Fetch data when the widget initializes
  }

  Future<void> _userTrack() async {
    try {
      // final dbHelper = DatabaseHelper();
      // final db = await dbHelper.database;
      // final userProfile = await db.query('profile', limit: 1);
      // final token = userProfile.first['token'] as String;

      await WebSharedStorage.init();
      var existingProfile = WebSharedStorage();

      final token = existingProfile.getCommon('token');

      // Fetch investment data from the API
      final response = await ApiService.userTrack(token);

      if (response['success'] == true) {
        // Update the state with the fetched data
        for (var data in response['data']) {
          portfoliosData.add(data);
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching investment data: $e');
      setState(() {
        isLoading = true;
      });
    }
  }

  void _withdraw() async {
    if (withdrawAmount == null || withdrawAmount! <= 0 || phoneNumber == null) {
      print('i might be ignored');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid amount and phone number')),
      );
    }
    try {
      // final dbHelper = DatabaseHelper();
      // final db = await dbHelper.database;
      // final userProfile = await db.query('profile', limit: 1);
      // final token = userProfile.first['token'] as String;

      await WebSharedStorage.init();
      var existingProfile = WebSharedStorage();

      final token = existingProfile.getCommon('token');
      final name = existingProfile.getCommon('name');
      final userCountry = existingProfile.getCommon('country');

      final currency = CurrencyHelper.getCurrencyCode(userCountry);

      final requestData = {
        "withdraw_channel": withdrawMethod == 'Online' ? 'online' : 'online',
        "currency": currency,
        "withdraw_amount": withdrawAmount ?? "",
        "investment_id": selectedPortfolio ?? "",
        "account_type": "basic",
        "phone_number": phoneNumber,
        "account_bank": 'MPS',
        "beneficiary_name": name,
      };

      // Fetch investment data from the API
      final response = await ApiService.withdraw(token, requestData);
      print(response);

      if (response['success'] == true) {
        // If successful, navigate to the success screen
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('your resquest has been initiated successfully')),
        );
      } else {
        String message = response["message"];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $message')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error making withdraw request, try agin')),
      );
      setState(() {
        isLoading = true;
      });
    }
  }

  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  currentStep = page;
                });
              },
              children: [
                buildPortfolioStep(),
                buildWithdrawMethodStep(),
                _buildOption(withdrawMethod),
                _buildSuccessScreen(),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              currentStep > 0
                  ? ElevatedButton(
                      onPressed: () {
                        _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTwo,
                        foregroundColor: white,
                      ),
                      child: const Text('Back'),
                    )
                  : const SizedBox(),
              ElevatedButton(
                onPressed: isLoading ? null : _withdraw,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTwo,
                  foregroundColor: white,
                ),
                child: isLoading
                    ? const Loader() // Show loader while processing
                    : Text(currentStep == 2 ? 'Confirm Withdraw' : 'Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/web.png',
            width: 120,
            height: 100,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          const Text(
            'Withdraw Request Successful!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }

  Widget buildPortfolioStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Select Portfolio',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryTwo,
          ),
        ),
        const SizedBox(height: 20),
        // ListView to show the portfolios as scrollable cards
        Expanded(
          // Use Expanded to make sure the list fills the available space
          child: ListView(
            children: portfoliosData.map((portfolio) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedPortfolio = portfolio['investment_option'];
                  });
                  _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn);
                },
                child: Card(
                  color: primaryTwo, // Applying primaryTwo color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                  elevation: 5, // Adding elevation for a more stylish look
                  margin: const EdgeInsets.symmetric(
                      vertical: 8), // Vertical spacing
                  child: Padding(
                    padding: const EdgeInsets.all(
                        16), // Internal padding for the card
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          portfolio['investment_option'], // Portfolio name
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Deposit Amount: \$${portfolio['deposit_amount'].toStringAsFixed(2)}', // Dynamic deposit amount
                          style: const TextStyle(
                            fontSize: 16,
                            color: white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Net Worth: \$${portfolio['closing_balance'].toStringAsFixed(2)}', // Dynamic net worth
                          style: const TextStyle(
                            fontSize: 16,
                            color: white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildOption(String? method) {
    print(method);
    if (method == 'mobile money') {
      return buildMobileMoneyStep();
    } else {
      return buildBankDetailsStep();
    }
  }

  Widget buildWithdrawMethodStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Display Withdraw from as a heading
        if (selectedPortfolio != null)
          Text(
            'Withdraw from $selectedPortfolio',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryTwo,
            ),
          ),
        const SizedBox(height: 20),
        const Text(
          'Select Withdraw Method',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: primaryTwo),
        ),
        DropdownButton<String>(
          value: withdrawMethod,
          hint: const Text('Choose a method'),
          items: const [
            DropdownMenuItem(
              value: 'mobile money',
              child: Text('Mobile Money'),
            ),
            DropdownMenuItem(
              value: 'bank',
              child: Text('Bank'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              withdrawMethod = value;
            });
            _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn);
          },
        ),
      ],
    );
  }

  Widget buildMobileMoneyStep() {
    if (withdrawMethod != 'mobile money') return const SizedBox.shrink();

    return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display Withdraw from as a heading
            if (selectedPortfolio != null)
              Text(
                'Withdraw from: $selectedPortfolio',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryTwo,
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'Mobile Money Details',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: primaryTwo),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                // Use UnderlineInputBorder for only a bottom border
                border: UnderlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                phoneNumber = value;
              },
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Amount',
                // Use UnderlineInputBorder for only a bottom border
                border: UnderlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                withdrawAmount = double.tryParse(value);
              },
            ),
          ],
        ));
  }

  Widget buildBankDetailsStep() {
    if (withdrawMethod != 'bank') return const SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Display Withdraw from as a heading
        if (selectedPortfolio != null)
          Text(
            'Withdraw from: $selectedPortfolio',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryTwo,
            ),
          ),
        const SizedBox(height: 20),
        const Text(
          'Bank Details',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: primaryTwo),
        ),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Bank Details',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.text,
          onChanged: (value) {
            bankDetails = value;
          },
        ),
        const SizedBox(height: 10),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Amount',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            withdrawAmount = double.tryParse(value);
          },
        ),
      ],
    );
  }
}
