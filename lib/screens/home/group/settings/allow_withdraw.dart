import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'dart:convert';

class WithdrawSetting extends StatelessWidget {
  final bool allowWithdraw;
  final int groupId;
  final ValueChanged<bool> onChanged;

  const WithdrawSetting({
    Key? key,
    required this.allowWithdraw,
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
            'allow_withdraw': value,
          },
        }),
      };

      final response = await ApiService.groupSettings(token, data);

      if (response['success'] == true) {
        onChanged(value); // Notify parent (GroupInfoPage)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Withdrawals ${value ? 'enabled' : 'disabled'} successfully')),
        );
      } else {
        throw Exception(
            response['message'] ?? 'Failed to update withdrawal setting');
      }
    } catch (e) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update setting: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.arrow_downward, color: primaryTwo),
      title: const Text(
        'Withdraw',
        style: TextStyle(color: Colors.black87),
      ),
      subtitle: const Text(
        'Restrict members from withdrawing',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: Switch(
        value: allowWithdraw,
        activeColor: primaryTwo,
        onChanged: (value) => _updateMessageSetting(context, value),
      ),
    );
  }
}