import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import the intl package
import '../../../theme/theme.dart'; // Your custom theme file
import './sample_goals.dart'; // Importing the SampleGoals widget
import './portifolio.dart'; // Portfolio screen or logic
import './card.dart'; // Import the updated cards.dart file
import './deposit_withdraw_buttons.dart'; // DepositWithdrawButtons widget
import './fund_manager.dart'; // FundManagerSlider widget
import 'package:cyanase/helpers/database_helper.dart'; // Import the database helper
import 'package:cyanase/helpers/api_helper.dart'; // Import the API helper
import 'package:cyanase/helpers/get_currency.dart'; // Import the currency helper

class PersonalTab extends StatefulWidget {
  final TabController tabController;

  const PersonalTab({Key? key, required this.tabController}) : super(key: key);

  @override
  _PersonalTabState createState() => _PersonalTabState();
}

class _PersonalTabState extends State<PersonalTab> {
  double _totalDepositUGX = 0.0;
  double _totalDepositUSD = 0.0;
  double _totalNetworthy = 0.0;
  String currency = ''; // Default currency

  @override
  void initState() {
    super.initState();
    _getDepositNetworth(); // Fetch data when the widget is initialized
  }

  // Helper function to format numbers with commas
  String formatNumberWithCommas(double number) {
    final formatter = NumberFormat('#,###');
    return formatter.format(number);
  }

  Future<void> _getDepositNetworth() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);

      if (userProfile.isNotEmpty) {
        final token = userProfile.first['token'] as String;
        final userCountry = userProfile.first['country'] as String;
        final currencyCode = CurrencyHelper.getCurrencyCode(userCountry);
        final response = await ApiService.depositNetworth(token);
        final data = response['data'] ?? {};

        // Safely extract the required fields with null checks
        final totalDeposit =
            (data['total_deposits'] as num?)?.toDouble() ?? 0.0;
        final totalNetWorthy = (data['net_worth'] as num?)?.toDouble() ?? 0.0;

        // Update the state
        setState(() {
          _totalDepositUGX = totalDeposit;
          _totalDepositUSD = totalDeposit;
          _totalNetworthy = totalNetWorthy;
          currency = currencyCode;
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // My Portfolio Button
            Align(
              alignment: Alignment.topRight,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Portfolio(currency: currency),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryTwo),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'My Portfolio',
                  style: TextStyle(
                    color: primaryTwo,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Total Deposits Card
            TotalDepositsCard(
              depositLocal: formatNumberWithCommas(_totalDepositUGX),
              depositForeign: formatNumberWithCommas(_totalDepositUSD),
              currency: currency,
            ),
            const SizedBox(height: 10),
            // Deposit and Withdraw Buttons
            DepositWithdrawButtons(),
            const SizedBox(height: 10),
            // Net Worth Card
            NetworthCard(
              NetworthLocal: formatNumberWithCommas(_totalNetworthy),
              currency: currency,
              NetworthForeign: formatNumberWithCommas(_totalDepositUSD),
            ),
            const SizedBox(height: 20),
            // Fund Manager Slider
            Text('Investment options',
                style: TextStyle(
                  color: primaryTwo,
                  fontSize: 20,
                )),
            const SizedBox(height: 12),
            FundManagerSlider(),
            const SizedBox(height: 10),
            // Goals Section
            SizedBox(
              height: 500, // Adjust height if necessary
              child: SampleGoals(
                onGoalTap: () {
                  // Navigate to the "Goals" tab
                  widget.tabController
                      .animateTo(2); // Index 2 is the "Goals" tab
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
