import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../componets/investment_deposit.dart'; // Import the Deposit widget
import '../componets/investment_withdraw.dart'; // Import the Withdraw widget

class DepositWithdrawButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () {
            // Show the bottom sheet when Deposit button is clicked
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return Deposit(); // Show the Deposit widget in the bottom sheet
              },
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: primaryTwo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add,
                size: 18,
                color: primaryTwo,
              ),
              SizedBox(width: 5),
              Text('Deposit'),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () {
            // Show the bottom sheet when Withdraw button is clicked
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return Withdraw(); // Show the Withdraw widget in the bottom sheet
              },
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: primaryTwo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.remove,
                size: 18,
                color: primaryTwo,
              ),
              SizedBox(width: 5),
              Text('Withdraw'),
            ],
          ),
        ),
      ],
    );
  }
}
