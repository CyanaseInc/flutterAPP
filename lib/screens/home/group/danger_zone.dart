import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';

class DangerZone extends StatelessWidget {
  final int groupId;
  final String groupName;
  const DangerZone({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: white,
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
