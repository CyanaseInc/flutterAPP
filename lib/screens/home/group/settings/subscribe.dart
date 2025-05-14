import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/get_currency.dart';
import 'package:cyanase/helpers/loader.dart';

class SubscriptionSetting extends StatefulWidget {
  final bool requireSubscription;
  final double paymentAmount;
  final String paymentFrequency;
  final ValueChanged<bool> onPaymentToggleChanged;
  final ValueChanged<double> onPaymentAmountChanged;
  final ValueChanged<String> onPaymentFrequencyChanged;
  final int groupId;

  const SubscriptionSetting({
    Key? key,
    required this.requireSubscription,
    required this.paymentAmount,
    required this.paymentFrequency,
    required this.onPaymentToggleChanged,
    required this.onPaymentAmountChanged,
    required this.onPaymentFrequencyChanged,
    required this.groupId,
  }) : super(key: key);

  @override
  _SubscriptionSettingState createState() => _SubscriptionSettingState();
}

class _SubscriptionSettingState extends State<SubscriptionSetting> {
  bool _isLoading = false;
  late String _selectedFrequency;

  @override
  void initState() {
    super.initState();
    _selectedFrequency = widget.paymentFrequency.isNotEmpty &&
            ['Monthly', 'Yearly'].contains(widget.paymentFrequency)
        ? widget.paymentFrequency
        : 'Monthly';
  }

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

  Future<bool> _updateSubscriptionSettings({
    required bool requirePayment,
    required double amount,
    required String frequency,
  }) async {
    setState(() => _isLoading = true);
    try {
      final profile = await _getTokenAndCurrency();
      if (profile == null) {
        throw Exception('No profile data found');
      }

      final token = profile['token'] as String;

      final data = {
        'groupId': widget.groupId,
        'requireSubscription': requirePayment,
        'paymentAmount': amount,
        'paymentFrequency': frequency,
      };

      final response = await ApiService.SubscriptionSetting(token, data);

      if (response['success'] == true) {
        widget.onPaymentToggleChanged(requirePayment);
        widget.onPaymentAmountChanged(amount);
        widget.onPaymentFrequencyChanged(frequency);
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
      text: widget.paymentAmount > 0 ? widget.paymentAmount.toString() : '0',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Set Subscription Details',
            style: TextStyle(color: Colors.black, fontSize: 18),
          ),
          content: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1.0,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount ($currency)',
                    hintText: 'Enter the payment amount',
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: primaryTwo,
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: primaryTwo, // Use theme color for focus
                        width: 2.0,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  keyboardType: TextInputType.number,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedFrequency,
                  decoration: const InputDecoration(
                    labelText: 'Payment Frequency',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  items: ['Monthly', 'Yearly'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: _isLoading
                      ? null
                      : (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedFrequency = newValue;
                            });
                          }
                        },
                ),
                const SizedBox(height: 10),
                Text(
                  'Cyanase takes 30% of this amount',
                  style: TextStyle(color: Colors.grey[600], fontSize: 15),
                ),
              ],
            ),
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
                        final success = await _updateSubscriptionSettings(
                          requirePayment: true,
                          amount: amount,
                          frequency: _selectedFrequency,
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
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Loader(),
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
        'Subscriptions',
        style: TextStyle(color: Colors.black87),
      ),
      subtitle: const Text(
        'This allows members to pay a monthly or annual fee to remain active in the group',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: Loader(),
            )
          : Switch(
              value: widget.requireSubscription,
              onChanged: _isLoading
                  ? null
                  : (value) async {
                      if (value) {
                        final profile = await _getTokenAndCurrency();
                        if (profile != null) {
                          _showPaymentAmountDialog(profile['currency']);
                        }
                      } else {
                        final success = await _updateSubscriptionSettings(
                          requirePayment: false,
                          amount: 0.0,
                          frequency: _selectedFrequency,
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
