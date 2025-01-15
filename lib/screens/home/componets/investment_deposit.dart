import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import 'package:cyanase/screens/settings/riskprofiler.dart';

class Deposit extends StatefulWidget {
  @override
  _DepositState createState() => _DepositState();
}

class _DepositState extends State<Deposit> {
  PageController _pageController = PageController();
  int currentStep = 0;

  final List<String> fundManagers = [
    'Fund Manager A',
    'Fund Manager B',
    'Fund Manager C',
    'Fund Manager D',
    'Fund Manager E',
  ];

  final Map<String, List<String>> fundClasses = {
    'Fund Manager A': ['Stocks', 'Bonds', 'Commodities'],
    'Fund Manager B': ['Stocks', 'Real Estate', 'Mutual Funds'],
    'Fund Manager C': ['Bonds', 'Commodities', 'Cryptocurrencies'],
    'Fund Manager D': ['Stocks', 'Real Estate', 'Hedge Funds'],
    'Fund Manager E': ['Mutual Funds', 'Stocks', 'Bonds', 'Commodities'],
  };

  final Map<String, List<String>> stockOptions = {
    'Stocks': ['Apple', 'Tesla', 'Microsoft', 'Amazon', 'Google', 'Meta'],
    'Bonds': [
      'Bond A',
      'Bond B',
      'Bond C',
      'Government Bond X',
      'Corporate Bond Y'
    ],
    'Real Estate': [
      'Property A',
      'Property B',
      'Property C',
      'Commercial Property X',
      'Residential Property Y'
    ],
    'Commodities': ['Gold', 'Silver', 'Oil', 'Natural Gas', 'Copper'],
    'Mutual Funds': [
      'Mutual Fund A',
      'Mutual Fund B',
      'Equity Fund X',
      'Balanced Fund Y'
    ],
    'Cryptocurrencies': [
      'Bitcoin',
      'Ethereum',
      'Ripple',
      'Litecoin',
      'Cardano'
    ],
    'Hedge Funds': [
      'Hedge Fund A',
      'Hedge Fund B',
      'Growth Fund X',
      'Income Fund Y'
    ],
  };

  String? selectedFundManager;
  String? selectedFundClass;
  String? selectedOption;
  String? depositMethod;
  double? depositAmount;

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
                side: BorderSide(
                    color: primaryTwo, width: 2), // Border color and width
                padding: EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10), // Button padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Rounded corners
                ),
              ),
              child: Text(
                'Edit Risk Profile',
                style: TextStyle(
                  fontSize: 16,
                  color: primaryTwo, // Text color
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    currentStep = page;
                  });
                },
                physics: NeverScrollableScrollPhysics(),
                children: [
                  buildFundManagerStep(),
                  buildFundClassStep(),
                  buildOptionStep(),
                  buildInvestmentDetailsStep(),
                  buildDepositMethodStep(),
                  buildOnlineDepositStep(),
                  buildOfflineDepositStep(),
                  buildConfirmStep(),
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
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Back'),
                      )
                    : SizedBox(),
                ElevatedButton(
                  onPressed: () {
                    if (currentStep == 6) {
                      Navigator.pop(context);
                    } else {
                      _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeIn);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTwo,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(currentStep == 6 ? 'Confirm Deposit' : 'Next'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget buildFundManagerStep() {
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
          'There should be someone to look after your money, choose  who',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
          textAlign:
              TextAlign.center, // This centers the text within its container
          softWrap:
              true, // Ensures the text wraps if it exceeds the line length
        ),
        DropdownButton<String>(
          value: selectedFundManager,
          hint: Text('Choose a fund manager'),
          items: fundManagers.map((manager) {
            return DropdownMenuItem<String>(
              value: manager,
              child: Text(manager),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedFundManager = value;
              selectedFundClass = null;
              selectedOption = null;
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

  Widget buildFundClassStep() {
    if (selectedFundManager == null) return SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Select an Investment Class',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryTwo,
          ),
        ),
        Text(
          'Where do you want to invest your money?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
          textAlign:
              TextAlign.center, // This centers the text within its container
          softWrap:
              true, // Ensures the text wraps if it exceeds the line length
        ),
        DropdownButton<String>(
          value: selectedFundClass,
          hint: const Text('Choose investment  class'),
          items: fundClasses[selectedFundManager!]!.map((fundClass) {
            return DropdownMenuItem<String>(
              value: fundClass,
              child: Text(fundClass),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedFundClass = value;
              selectedOption = null;
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
          'Let\'s get into the details of your investment',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
          textAlign:
              TextAlign.center, // This centers the text within its container
          softWrap:
              true, // Ensures the text wraps if it exceeds the line length
        ),
        DropdownButton<String>(
          value: selectedOption,
          hint: Text('Choose an option'),
          items: stockOptions[selectedFundClass!]!.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedOption = value;
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

  Widget buildInvestmentDetailsStep() {
    if (selectedOption == null) return SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Investment Details',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: primaryTwo)),
        SizedBox(height: 10),
        Text('Option: $selectedOption'),
        OutlinedButton(
          onPressed: () {
            _pageController.nextPage(
                duration: Duration(milliseconds: 300), curve: Curves.easeIn);
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: primaryTwo),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'Invest with this Option',
            style: TextStyle(
              color: primaryTwo,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildDepositMethodStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Select Deposit Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryTwo,
            )),
        RadioListTile<String>(
          title: Text('Online Deposit'),
          value: 'Online',
          groupValue: depositMethod,
          onChanged: (value) {
            setState(() {
              depositMethod = value;
            });
            _pageController.nextPage(
                duration: Duration(milliseconds: 300), curve: Curves.easeIn);
          },
        ),
        RadioListTile<String>(
          title: Text('Offline Deposit'),
          value: 'Offline',
          groupValue: depositMethod,
          onChanged: (value) {
            setState(() {
              depositMethod = value;
            });
            _pageController.nextPage(
                duration: Duration(milliseconds: 300), curve: Curves.easeIn);
          },
        ),
      ],
    );
  }

  Widget buildOfflineDepositStep() {
    if (depositMethod != 'Offline') return SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Enter Deposit Amount',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryTwo,
            )),
        Text('Bank Details:\nBank Name: ABC Bank\nAccount Number: 123456789',
            style: TextStyle(fontSize: 16)),
        TextField(
          keyboardType: TextInputType.number,
          onChanged: (value) {
            depositAmount = double.tryParse(value);
          },
          decoration: InputDecoration(
            hintText: 'Enter amount',
          ),
        ),
      ],
    );
  }

  Widget buildOnlineDepositStep() {
    if (depositMethod != 'Online') return SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Enter Deposit Amount',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryTwo,
            )),
        TextField(
          keyboardType: TextInputType.number,
          onChanged: (value) {
            depositAmount = double.tryParse(value);
          },
          decoration: InputDecoration(
            hintText: 'Enter amount',
          ),
        ),
      ],
    );
  }

  Widget buildConfirmStep() {
    if (depositAmount == null || depositAmount! <= 0) return SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Confirm Deposit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryTwo,
            )),
        Text('Amount: \$${depositAmount!.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 16)),
        Text('Method: $depositMethod', style: TextStyle(fontSize: 16)),
        ElevatedButton(
          onPressed: () {
            // Add confirmation logic here
            Navigator.pop(context);
          },
          child: Text('Confirm'),
        ),
      ],
    );
  }
}
