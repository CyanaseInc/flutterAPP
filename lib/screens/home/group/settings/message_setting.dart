import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'dart:convert';

class SendMessagesSetting extends StatelessWidget {
  final bool allowMessageSending;
  final int groupId;
  final ValueChanged<bool> onChanged;

  const SendMessagesSetting({
    Key? key,
    required this.allowMessageSending,
    required this.groupId,
    required this.onChanged,
  }) : super(key: key);

  Future<void> _updateMessageSetting(BuildContext context, bool value) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to update settings')),
        );
        return;
      }

      final token = userProfile.first['token'] as String;
      final data = {
        'groupId': groupId.toString(),
        'setting': jsonEncode({
          'action': 'update_loan_settings',
          'loan_settings': {
            'restrict_messages_to_admins': value
          }, // Map to model
        }),
      };

      final response = await ApiService.groupSettings(token, data);

      if (response['success'] == true) {
        onChanged(value);
      } else {
        throw Exception(
            response['message'] ?? 'Failed to update message setting');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update setting: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.message, color: primaryTwo),
      title: const Text(
        'Send Messages',
        style: TextStyle(color: Colors.black87),
      ),
      subtitle: const Text(
        'Allow or restrict members from sending messages',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: Switch(
        value: allowMessageSending,
        onChanged: (value) => _updateMessageSetting(context, value),
      ),
    );
  }
}
