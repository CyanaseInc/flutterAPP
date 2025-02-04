import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'group_loan.dart';

class LoanButton extends StatelessWidget {
  const LoanButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Example: Fetch data from a provider or state management
    double loanBalance = 0; // Replace with actual data source
    int daysLeft = 30; // Replace with actual data source
    double totalBalance = 12000.0; // Replace with actual data source

    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoanSection(
              loanBalance: loanBalance,
              daysLeft: daysLeft,
              totalBalance: totalBalance,
            ),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: const Text(
        'Get Loan',
        style:
            TextStyle(color: white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
