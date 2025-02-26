import 'package:cyanase/theme/theme.dart';
import 'package:flutter/material.dart';
import 'dart:io'; // Make sure you import this for File usage
import 'package:cyanase/helpers/deposit.dart';

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
              height: 300, // Adjust height as needed
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  DepositHelper(
                      depositCategory: 'group_general',
                      detailText:
                          'Contribute to the  saving group by depositing here'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
