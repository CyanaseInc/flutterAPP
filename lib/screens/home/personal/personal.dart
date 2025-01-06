import 'package:flutter/material.dart';
import '../../../theme/theme.dart'; // Assuming your theme file has primaryTwo defined
import 'fund_manager.dart';
import 'deposit_withdraw_buttons.dart';
import 'card.dart';
import 'sample_goals.dart';
import './portifolio.dart';

class PersonalTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Portfolio(),
                    ),
                  ); // Navigate to portfolio screen or implement logic
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
            SizedBox(height: 20),
            TotalDepositsCard(),
            SizedBox(height: 10),
            DepositWithdrawButtons(),
            SizedBox(height: 10),
            NetworthCard(),
            SizedBox(height: 10),
            FundManagerSlider(),
            SizedBox(height: 10),
            SizedBox(
              height: 500, // Adjust height if needed
              child: SampleGoals(),
            ),
          ],
        ),
      ),
    );
  }
}
