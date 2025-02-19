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
    FundManager(name: 'Manager 2', imagePath: 'assets/images/logo.png'),
    FundManager(name: 'Manager 3', imagePath: 'assets/images/logo.png'),
    FundManager(name: 'Manager 4', imagePath: 'assets/images/logo.png'),
    FundManager(name: 'Manager 5', imagePath: 'assets/images/logo.png'),
    FundManager(name: 'Manager 6', imagePath: 'assets/images/logo.png'),
    FundManager(name: 'Manager 7', imagePath: 'assets/images/logo.png'),
    FundManager(name: 'Manager 8', imagePath: 'assets/images/logo.png'),
    FundManager(name: 'Manager 9', imagePath: 'assets/images/logo.png'),
    FundManager(name: 'Manager 10', imagePath: 'assets/images/logo.png'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.4);
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
      height: 120, // Increased height for the rectangular card
      child: PageView.builder(
        controller: _pageController,
        itemCount: fundManagers.length,
        itemBuilder: (context, index) {
          final fundManager = fundManagers[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return Deposit(); // Show the Deposit widget in the bottom sheet
                  },
                );
              },
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  width: 100,
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Small image in the top-left corner
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: AssetImage(fundManager.imagePath),
                            fit: BoxFit.cover,
                          ),
                          border: Border.all(
                            color: Theme.of(context).primaryColor,
                            width: 1,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      // Manager name
                      Text(
                        fundManager.name,
                        style: TextStyle(
                          color: primaryTwo,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      // Additional creative design (e.g., a tag or badge)
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Top Performer',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
