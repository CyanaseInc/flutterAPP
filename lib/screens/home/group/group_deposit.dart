import 'package:cyanase/theme/theme.dart';
import 'package:flutter/material.dart';
import 'dart:io'; // Make sure you import this for File usage

class DepositScreen extends StatefulWidget {
  final String groupName;
  final String profilePic;
  final int groupId;

  DepositScreen({
    required this.groupName,
    required this.profilePic,
    required this.groupId,
  });

  @override
  _DepositScreenState createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final PageController _pageController = PageController();

  int _currentStep = 0;
  String? _selectedMethod;

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Centered Profile Picture visible on all steps
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: CircleAvatar(
                backgroundImage: widget.profilePic.isNotEmpty
                    ? FileImage(File(widget.profilePic))
                    : AssetImage('assets/avat.png') as ImageProvider,
                radius: 60,
              ),
            ),

            // PageView for different steps
            SizedBox(
              height: MediaQuery.of(context).size.height -
                  200, // Adjust height as needed
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildChooseDepositMethod(),
                  _buildEnterAmount(),
                  _buildSuccessScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChooseDepositMethod() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Choose Deposit Method',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: primaryTwo),
          ),
          SizedBox(height: 10),
          const Text(
            'Contribute to the group total fund by depositing here',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey),
          ),
          SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedMethod = 'Mobile Money';
              });
              _nextStep(); // Automatically proceed to the next step
            },
            child: SizedBox(
              width: 320,
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  child: Row(
                    children: [
                      Icon(Icons.phone_android, size: 30),
                      SizedBox(width: 10),
                      Text(
                        'Mobile Money',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedMethod = 'Bank Transfer';
              });
              _nextStep(); // Automatically proceed to the next step
            },
            child: SizedBox(
              width: 320,
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance, size: 30),
                      SizedBox(width: 10),
                      Text(
                        'Bank Transfer',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnterAmount() {
    return Center(
      child: SizedBox(
        width: 320,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter Details to continue',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: primaryTwo),
            ),
            SizedBox(height: 10),
            const Text(
              'Enter how much you want to deposit',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter Phone number',
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: primaryColor),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: primaryLight),
                ),
              ),
            ),
            SizedBox(height: 20),
            const SizedBox(height: 20),
            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter Amount',
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: primaryColor),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: primaryLight),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _previousStep,
                  child: Text('Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTwo,
                    foregroundColor: white,
                  ),
                ),
                ElevatedButton(
                  onPressed: _nextStep,
                  child: Text('Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTwo,
                    foregroundColor: white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 100),
          SizedBox(height: 20),
          Text(
            'Deposit Successful!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Finish'),
          ),
        ],
      ),
    );
  }
}
