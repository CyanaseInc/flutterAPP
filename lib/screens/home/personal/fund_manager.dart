import 'package:cyanase/helpers/loader.dart';
import 'package:cyanase/helpers/web_db.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';

import '../../../theme/theme.dart';
import '../componets/investment_deposit.dart';

class FundManagerSlider extends StatefulWidget {
  @override
  _FundManagerSliderState createState() => _FundManagerSliderState();
}

class _FundManagerSliderState extends State<FundManagerSlider> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _investmentData = [];
  List<Map<String, dynamic>> _investmentOptions = [];

  @override
  void initState() {
    super.initState();
    _pageController =
        PageController(viewportFraction: 0.75); // Increased for wider cards
    _fetchInvestmentData();
    _autoSlide();
  }

  Future<void> _fetchInvestmentData() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isEmpty) {
        throw Exception('No user profile found');
      }
      final token = userProfile.first['token'] as String;

      await WebSharedStorage.init();
      // var existingProfile = WebSharedStorage();

      // final token = existingProfile.getCommon('token');

      final List<Map<String, dynamic>> investmentData =
          await ApiService.getClasses(token);

      List<Map<String, dynamic>> options = [];
      for (var classData in investmentData) {
        final className = classData['investment_class'] as String;
        final classLogo = classData['logo'] as String?;
        final optionsList =
            classData['investment_options'] as List<dynamic>? ?? [];
        for (var option in optionsList) {
          options.add({
            'investment_option': option['investment_option'] as String,
            'class_name': className,
            'fund_manager': option['handler'] as String,
            'logo': classLogo,
            'minimum_deposit': option['minimum_deposit'] as int,
            'interest': option['interest'] as num,
          });
        }
      }

      setState(() {
        _investmentData = investmentData;
        _investmentOptions = options;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching investment data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _autoSlide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (_pageController.hasClients && mounted) {
        setState(() {
          _currentIndex = _investmentOptions.isEmpty
              ? 0
              : (_currentIndex + 1) % _investmentOptions.length;
        });
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 500),
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
    if (_isLoading) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: Loader(),
        ),
      );
    }

    if (_investmentOptions.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(
            child: Text('No investment options available',
                style: TextStyle(color: Colors.grey))),
      );
    }

    return SizedBox(
      height: 140,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _investmentOptions.length,
        itemBuilder: (context, index) {
          final option = _investmentOptions[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) => Deposit(),
                );
              },
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Container(
                  width: 350, // Increased width for more text visibility
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: option['logo'] != null
                              ? DecorationImage(
                                  image: NetworkImage(option['logo']),
                                  fit: BoxFit.cover,
                                  onError: (_, __) => const AssetImage(
                                      'assets/images/logo.png'),
                                )
                              : const DecorationImage(
                                  image: AssetImage('assets/images/logo.png'),
                                  fit: BoxFit.cover,
                                ),
                          border: Border.all(color: primaryColor, width: 1),
                        ),
                      ),
                      Text(
                        option['investment_option'],
                        style: const TextStyle(
                          color: primaryTwo,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        option['fund_manager'],
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),

                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          option['class_name'],
                          style: const TextStyle(
                            color: primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
