import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

class Withdraw extends StatefulWidget {
  @override
  _WithdrawState createState() => _WithdrawState();
}

class _WithdrawState extends State<Withdraw> {
  PageController _pageController = PageController();
  int currentStep = 0;

  // Sample portfolios data
  final Map<String, Map<String, double>> portfoliosData = {
    'Portfolio A': {'deposit': 1234.56, 'netWorth': 5000.00},
    'Portfolio B': {'deposit': 4567.89, 'netWorth': 7500.00},
    'Portfolio C': {'deposit': 7890.12, 'netWorth': 9500.00},
  };

  String? selectedPortfolio;
  String? withdrawMethod;
  String? phoneNumber;
  String? bankDetails;
  double? withdrawAmount;

  @override
  bool isLoading = false; // Flag to track if the withdrawal is in progress

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
                buildMobileMoneyStep(),
                buildBankDetailsStep(),
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
                        foregroundColor: white,
                      ),
                      child: Text('Back'),
                    )
                  : SizedBox(),
              ElevatedButton(
                onPressed: () async {
                  if (currentStep == 2) {
                    // Show circular loader and trigger withdrawal
                    setState(() {
                      isLoading = true;
                    });

                    // Simulate the withdrawal process (you can replace this with your actual logic)
                    await Future.delayed(Duration(seconds: 2));

                    // After withdrawal is done, close the bottom sheet
                    Navigator.pop(context);

                    setState(() {
                      isLoading = false;
                    });
                  } else {
                    _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeIn);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTwo,
                  foregroundColor: white,
                ),
                child: isLoading
                    ? CircularProgressIndicator(
                        color: white,
                      ) // Show loader while processing
                    : Text(currentStep == 2 ? 'Confirm Withdraw' : 'Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildPortfolioStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Select Portfolio',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryTwo,
          ),
        ),
        SizedBox(height: 20),
        // ListView to show the portfolios as scrollable cards
        Expanded(
          // Use Expanded to make sure the list fills the available space
          child: ListView(
            children: portfoliosData.keys.map((portfolio) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedPortfolio = portfolio;
                  });
                  _pageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeIn);
                },
                child: Card(
                  color: primaryTwo, // Applying primaryTwo color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                  elevation: 5, // Adding elevation for a more stylish look
                  margin: EdgeInsets.symmetric(vertical: 8), // Vertical spacing
                  child: Padding(
                    padding:
                        EdgeInsets.all(16), // Internal padding for the card
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          portfolio, // Portfolio name
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Deposit Amount: \$${portfoliosData[portfolio]!['deposit']!.toStringAsFixed(2)}', // Dynamic deposit amount
                          style: TextStyle(
                            fontSize: 16,
                            color: white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Net Worth: \$${portfoliosData[portfolio]!['netWorth']!.toStringAsFixed(2)}', // Dynamic net worth
                          style: TextStyle(
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

  Widget buildWithdrawMethodStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Select Withdraw Method',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: primaryTwo),
        ),
        DropdownButton<String>(
          value: withdrawMethod,
          hint: Text('Choose a method'),
          items: [
            DropdownMenuItem(
              value: 'Mobile Money',
              child: Text('Mobile Money'),
            ),
            DropdownMenuItem(
              value: 'Bank',
              child: Text('Bank'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              withdrawMethod = value;
            });
            _pageController.nextPage(
                duration: Duration(milliseconds: 300), curve: Curves.easeIn);
          },
        ),
      ],
    );
  }

  Widget buildMobileMoneyStep() {
    if (withdrawMethod != 'Mobile Money') return SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Mobile Money Details',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: primaryTwo),
        ),
        SizedBox(height: 10),
        TextField(
          decoration: InputDecoration(
            labelText: 'Phone Number',
            // Use UnderlineInputBorder for only a bottom border
            border: UnderlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          onChanged: (value) {
            phoneNumber = value;
          },
        ),
        SizedBox(height: 10),
        TextField(
          decoration: InputDecoration(
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
    );
  }

  Widget buildBankDetailsStep() {
    if (withdrawMethod != 'Bank') return SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Bank Details',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: primaryTwo),
        ),
        TextField(
          decoration: InputDecoration(
            labelText: 'Bank Details',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.text,
          onChanged: (value) {
            bankDetails = value;
          },
        ),
        SizedBox(height: 10),
        TextField(
          decoration: InputDecoration(
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
