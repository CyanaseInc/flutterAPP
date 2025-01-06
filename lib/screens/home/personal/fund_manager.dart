import 'package:flutter/material.dart';

class FundManagerSlider extends StatefulWidget {
  @override
  _FundManagerSliderState createState() => _FundManagerSliderState();
}

class _FundManagerSliderState extends State<FundManagerSlider> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.7);
    _autoSlide();
  }

  void _autoSlide() {
    Future.delayed(Duration(seconds: 3), () {
      if (_pageController.hasClients) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % 10;
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
      height: 80,
      child: PageView.builder(
        controller: _pageController,
        itemCount: 10,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: GestureDetector(
              onTap: () {
                // Handle fund manager selection logic
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    'Manager ${index + 1}',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
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
