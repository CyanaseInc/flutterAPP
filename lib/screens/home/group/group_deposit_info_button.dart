// File 2: deposit_button.dart
import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'group_deposit.dart'; // Replace with actual page

class DepositButton extends StatelessWidget {
  final String groupName;
  final String profilePic;
  final int groupId;
  const DepositButton(
      {Key? key,
      required this.groupName,
      required this.profilePic,
      required this.groupId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DepositScreen(
              groupName: groupName,
              profilePic: profilePic,
              groupId: groupId,
            ), // Replace with actual page
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
        style:
            TextStyle(color: white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
