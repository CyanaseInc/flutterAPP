import 'package:flutter/material.dart';

class Withdraw extends StatefulWidget {
  @override
  _WithdrawState createState() => _WithdrawState();
}

class _WithdrawState extends State<Withdraw> {
  PageController _pageController = PageController();
  int currentStep = 0;

  // Sample portfolios
  final List<String> portfolios = ['Portfolio A', 'Portfolio B', 'Portfolio C'];

  String? selectedPortfolio;
  String? withdrawMethod;
  String? phoneNumber;
  String? bankDetails;
  double? withdrawAmount;

  @override
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
                      child: Text('Back'),
                    )
                  : SizedBox(),
              ElevatedButton(
                onPressed: () {
                  if (currentStep == 3) {
                    // Confirm withdraw logic here
                    Navigator.pop(context); // Close bottom sheet
                  } else {
                    _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeIn);
                  }
                },
                child: Text(currentStep == 3 ? 'Confirm Withdraw' : 'Next'),
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
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        DropdownButton<String>(
          value: selectedPortfolio,
          hint: Text('Choose a portfolio'),
          items: portfolios.map((portfolio) {
            return DropdownMenuItem<String>(
              value: portfolio,
              child: Text(portfolio),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedPortfolio = value;
            });
            _pageController.nextPage(
                duration: Duration(milliseconds: 300), curve: Curves.easeIn);
          },
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
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
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
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        TextField(
          decoration: InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
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

  Widget buildBankDetailsStep() {
    if (withdrawMethod != 'Bank') return SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Bank Details',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
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
