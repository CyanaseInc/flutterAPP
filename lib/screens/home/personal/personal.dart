import 'package:flutter/material.dart';
import '../../../theme/theme.dart'; // Your custom theme file
import './sample_goals.dart'; // Importing the SampleGoals widget
import './portifolio.dart'; // Portfolio screen or logic
import './card.dart'; // Assuming this includes TotalDepositsCard and NetworthCard widgets
import './deposit_withdraw_buttons.dart'; // DepositWithdrawButtons widget
import './fund_manager.dart'; // FundManagerSlider widget

class PersonalTab extends StatelessWidget {
  final TabController tabController;

  PersonalTab({required this.tabController});

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
                      builder: (context) => Portfolio(),
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
            TotalDepositsCard(),
            const SizedBox(height: 10),
            // Deposit and Withdraw Buttons
            DepositWithdrawButtons(),
            const SizedBox(height: 10),
            // Net Worth Card
            NetworthCard(),
            const SizedBox(height: 10),
            // Fund Manager Slider
            FundManagerSlider(),
            const SizedBox(height: 10),
            // Goals Section
            SizedBox(
              height: 500, // Adjust height if necessary
              child: SampleGoals(
                onGoalTap: () {
                  // Navigate to the "Goals" tab
                  tabController.animateTo(2); // Index 2 is the "Goals" tab
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
