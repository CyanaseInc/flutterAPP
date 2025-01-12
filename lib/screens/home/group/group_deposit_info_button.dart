// File 2: deposit_button.dart
import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'test.dart'; // Replace with actual page

class DepositButton extends StatelessWidget {
  const DepositButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Testa(), // Replace with actual page
          ),
        );
        // Add Deposit functionality here
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryTwo,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: const Text(
        'Deposit',
        style: TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
