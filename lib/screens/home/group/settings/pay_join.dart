import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/get_currency.dart';
import 'package:cyanase/helpers/loader.dart';

class PaymentSetting extends StatefulWidget {
  final bool requirePaymentToJoin;
  final double paymentAmount;
  final ValueChanged<bool> onPaymentToggleChanged;
  final ValueChanged<double> onPaymentAmountChanged;
  final int groupId;

  const PaymentSetting({
    Key? key,
    required this.requirePaymentToJoin,
    required this.paymentAmount,
    required this.onPaymentToggleChanged,
    required this.onPaymentAmountChanged,
    required this.groupId,
  }) : super(key: key);

  @override
  _PaymentSettingState createState() => _PaymentSettingState();
}

class _PaymentSettingState extends State<PaymentSetting> {
  bool _isLoading = false;

  Future<Map<String, dynamic>?> _getTokenAndCurrency() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);

      if (userProfile.isEmpty) {
        throw Exception('User profile not found');
      }

      final token = userProfile.first['token'] as String;
      final country = userProfile.first['country'] as String;
      final currency = CurrencyHelper.getCurrencyCode(country);

      return {'token': token, 'currency': currency};
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching profile: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
      return null;
    }
  }

  Future<bool> _updatePaymentSettings({
    required bool requirePayment,
    required double amount,
  }) async {
    setState(() => _isLoading = true);
    try {
      final profile = await _getTokenAndCurrency();
      if (profile == null) {
        throw Exception('No profile data found');
      }

      final token = profile['token'] as String;
      final currency = profile['currency'] as String;

      final data = {
        'groupId': widget.groupId,
        'requirePaymentToJoin': requirePayment,
        'paymentAmount': amount,
        'currency': currency,
      };

      final response = await ApiService.PayToJoinGroup(token, data);

      if (response['success'] == true) {
        widget.onPaymentToggleChanged(requirePayment);
        widget.onPaymentAmountChanged(amount);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment settings updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        return true;
      } else {
        throw Exception(response['message'] ?? 'Failed to update settings');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update settings: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
      return false;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showPaymentAmountDialog(String currency) {
    TextEditingController amountController = TextEditingController(
      text: widget.paymentAmount > 0 ? widget.paymentAmount.toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Set Payment Amount ($currency)',
            style: const TextStyle(color: Colors.black, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Amount ($currency)',
                  hintText: 'Enter the payment amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: primaryTwo),
                  ),
                ),
                keyboardType: TextInputType.number,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 10),
              Text(
                'Cyanase takes 30% of this amount',
                style: TextStyle(color: Colors.grey[600], fontSize: 15),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      final amount = double.tryParse(amountController.text);
                      if (amount != null && amount >= 0) {
                        final success = await _updatePaymentSettings(
                          requirePayment: true,
                          amount: amount,
                        );
                        if (success) {
                          Navigator.pop(context);
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid amount'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: primaryTwo,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Save',
                      style: TextStyle(color: primaryTwo),
                    ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.payment, color: primaryTwo),
      title: const Text(
        'Pay on Requesting to Enter Group',
        style: TextStyle(color: Colors.black87),
      ),
      subtitle: const Text(
        'Require payment before joining the group',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: _isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: Loader(),
            )
          : Switch(
              value: widget.requirePaymentToJoin,
              onChanged: _isLoading
                  ? null
                  : (value) async {
                      if (value) {
                        final profile = await _getTokenAndCurrency();
                        if (profile != null) {
                          _showPaymentAmountDialog(profile['currency']);
                        }
                      } else {
                        final success = await _updatePaymentSettings(
                          requirePayment: false,
                          amount: 0.0,
                        );
                        if (!success) {
                          setState(() {});
                        }
                      }
                    },
            ),
    );
  }
}
