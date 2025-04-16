import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';

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
  void _showPaymentAmountDialog() {
    TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Set Payment Amount',
            style: TextStyle(color: Colors.black, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: 'Enter the payment amount',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              const Text(
                'Cyanase takes 30% of this amount',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (amount != null && amount >= 0) {
                  widget.onPaymentAmountChanged(amount);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid amount')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.payment, color: Colors.blue),
      title: const Text(
        'Pay on Requesting to Enter Group',
        style: TextStyle(color: Colors.black87),
      ),
      subtitle: const Text(
        'Require payment before joining the group',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: Switch(
        value: widget.requirePaymentToJoin,
        onChanged: (value) {
          widget.onPaymentToggleChanged(value);
          if (value) {
            _showPaymentAmountDialog();
          }
        },
      ),
    );
  }
}
