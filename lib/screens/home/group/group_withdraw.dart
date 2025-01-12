// File 3: withdraw_button.dart
import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';

class WithdrawButton extends StatelessWidget {
  const WithdrawButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        // Implement action for withdrawing
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: primaryTwo),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: const Text(
        'Withdraw',
        style: TextStyle(
            color: primaryTwo, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
