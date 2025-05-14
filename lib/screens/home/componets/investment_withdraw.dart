import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/get_currency.dart';
import 'package:cyanase/helpers/loader.dart';
import 'package:cyanase/helpers/web_db.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/withdraw_helper.dart';

class Withdraw extends StatefulWidget {
  @override
  _WithdrawState createState() => _WithdrawState();
}

class _WithdrawState extends State<Withdraw> {
  PageController _pageController = PageController();
  int currentStep = 0;

  List<Map<String, dynamic>> portfoliosData = [];
  String? selectedPortfolio;
  String? withdrawMethod;
  String? phoneNumber;
  String? bankDetails;
  double? withdrawAmount;
  String phonenumber = '';
  String currency = '';
  bool isLoading = false;

  // List of colors for portfolio cards
  final List<Color> cardColors = [primaryColor, primaryTwo];

  @override
  void initState() {
    super.initState();
    _userTrack();
    _getNumber();
  }

  Future<void> _getNumber() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);

      final userCountry = userProfile.first['country'] as String;
      final Mycurrency = CurrencyHelper.getCurrencyCode(userCountry);
      final userPhone = userProfile.first['phone_number'] as String;

      setState(() {
        phonenumber = userPhone;
        currency = Mycurrency;
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _userTrack() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      final token = userProfile.first['token'] as String;

      final response = await ApiService.userTrack(token);

      if (response['success'] == true) {
        for (var data in response['data']) {
          portfoliosData.add(data);
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching investment data: $e');
      setState(() {
        isLoading = true;
      });
    }
  }

  void _withdraw() async {
    if (withdrawAmount == null || withdrawAmount! <= 0 || phoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid amount and phone number')),
      );
      return;
    }
    try {
      await WebSharedStorage.init();
      var existingProfile = WebSharedStorage();
      final token = existingProfile.getCommon('token');
      final name = existingProfile.getCommon('name');
      final userCountry = existingProfile.getCommon('country');

      final currency = CurrencyHelper.getCurrencyCode(userCountry);

      final requestData = {
        "withdraw_channel":
            withdrawMethod == 'mobile money' ? 'online' : 'online',
        "currency": currency,
        "withdraw_amount": withdrawAmount ?? "",
        "investment_id": selectedPortfolio ?? "",
        "account_type": "basic",
        "phone_number": phoneNumber,
        "account_bank": 'MPS',
        "beneficiary_name": name,
      };

      final response = await ApiService.withdraw(token, requestData);

      if (response['success'] == true) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Your request has been initiated successfully')),
        );
      } else {
        String message = response["message"];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $message')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error making withdraw request, try again')),
      );
      setState(() {
        isLoading = true;
      });
    }
  }

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
                WithdrawHelper(
                  withdrawType: 'portfolio',
                  withdrawId: selectedPortfolio ?? '',
                  phonenumber: phonenumber,
                  onMethodSelected: (method) {
                    setState(() {
                      withdrawMethod = method;
                    });
                  },
                ),
                _buildSuccessScreen(),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/web.png',
            width: 120,
            height: 100,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          const Text(
            'Withdraw Request Successful!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }

  Widget buildPortfolioStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Select Portfolio',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryTwo,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: portfoliosData.length,
            itemBuilder: (context, index) {
              final portfolio = portfoliosData[index];
              final cardColor = cardColors[index % cardColors.length];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedPortfolio = portfolio['investment_option'];
                  });
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeIn,
                  );
                },
                child: Card(
                  color: cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          portfolio['investment_option'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Deposit Amount: $currency ${portfolio['deposit_amount'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Net Worth: $currency ${portfolio['closing_balance'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
