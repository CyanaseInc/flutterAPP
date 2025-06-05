import 'package:cyanase/theme/theme.dart';
import 'package:flutter/material.dart';
import 'dart:io'; // Make sure you import this for File usage
import 'package:cyanase/helpers/deposit.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
        backgroundColor: primaryTwo,
        title: Text(
          widget.groupName,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Centered Profile Picture visible on all steps
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: widget.profilePic.isNotEmpty
                    ? CachedNetworkImageProvider(widget.profilePic)
                    : const AssetImage('assets/images/avatar.png') as ImageProvider,
                onBackgroundImageError: widget.profilePic.isNotEmpty
                    ? (exception, stackTrace) {}
                    : null,
              ),
            ),

            // PageView for different steps
            SizedBox(
              height: 500,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(
                        16.0), // Adjust the padding as needed
                    child: DepositHelper(
                      groupId: widget.groupId,
                      depositCategory: 'group_deposit',
                      detailText:
                          'Contribute to the saving group by depositing here',
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
