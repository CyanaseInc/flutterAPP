import '../../../theme/theme.dart';
import 'package:flutter/material.dart';
import '../componets/investment_deposit.dart'; // Import the Deposit widget

class FundManager {
  final String name;
  final String imagePath;
  FundManager({required this.name, required this.imagePath});
}

class FundManagerSlider extends StatefulWidget {
  @override
  _FundManagerSliderState createState() => _FundManagerSliderState();
}

class _FundManagerSliderState extends State<FundManagerSlider> {
  late PageController _pageController;
  int _currentIndex = 0;

  final List<FundManager> fundManagers = [
    FundManager(name: 'Manager 1', imagePath: 'assets/images/logo.png'),
    FundManager(name: 'Manager 2', imagePath: 'assets/manager_2.jpg'),
    FundManager(name: 'Manager 3', imagePath: 'assets/manager_3.png'),
    FundManager(name: 'Manager 4', imagePath: 'assets/manager_4.jpg'),
    FundManager(name: 'Manager 5', imagePath: 'assets/manager_5.jpg'),
    FundManager(name: 'Manager 6', imagePath: 'assets/manager_6.jpg'),
    FundManager(name: 'Manager 7', imagePath: 'assets/manager_7.jpg'),
    FundManager(name: 'Manager 8', imagePath: 'assets/manager_8.jpg'),
    FundManager(name: 'Manager 9', imagePath: 'assets/manager_9.jpg'),
    FundManager(name: 'Manager 10', imagePath: 'assets/manager_10.jpg'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
        viewportFraction: 0.4); // Reduce space by decreasing this value
    _autoSlide();
  }

  void _autoSlide() {
    Future.delayed(Duration(seconds: 3), () {
      if (_pageController.hasClients) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % fundManagers.length;
        });
        _pageController.animateToPage(
          _currentIndex,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _autoSlide();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      child: PageView.builder(
        controller: _pageController,
        itemCount: fundManagers.length,
        itemBuilder: (context, index) {
          final fundManager = fundManagers[index];
          return Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 4.0), // Reduce horizontal padding
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return Deposit(); // Show the Deposit widget in the bottom sheet
                  },
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 3,
                      ),
                      image: DecorationImage(
                        image: AssetImage(fundManager.imagePath),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: white,
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    fundManager.name,
                    style: TextStyle(
                      color: primaryTwo,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
