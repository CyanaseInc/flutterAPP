import 'package:flutter/material.dart';

class DangerZone extends StatelessWidget {
  const DangerZone({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8.0),
      child: Column(
        children: [
          _buildDangerButton('Exit Group', () {}),
          const Divider(height: 0),
          _buildDangerButton('Delete Group', () {}),
        ],
      ),
    );
  }

  Widget _buildDangerButton(String text, VoidCallback onPressed) {
    return TextButton(
      child: Text(text, style: const TextStyle(color: Colors.red)),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
