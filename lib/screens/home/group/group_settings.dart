import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'settings/message_setting.dart';
import 'settings/savings_visibility_setting.dart';
import 'settings/loan_setting.dart';
import 'settings/pay_join.dart';

class GroupSettings extends StatefulWidget {
  final int groupId;
  final bool initialRequirePayment;
  final double initialPaymentAmount;
  final Map<String, dynamic> initialLoanSettings; // New parameter
  final Function(bool, double) onPaymentSettingChanged;

  const GroupSettings({
    Key? key,
    required this.groupId,
    required this.initialRequirePayment,
    required this.initialPaymentAmount,
    required this.initialLoanSettings,
    required this.onPaymentSettingChanged,
  }) : super(key: key);

  @override
  _GroupSettingsState createState() => _GroupSettingsState();
}

class _GroupSettingsState extends State<GroupSettings> {
  bool _allowMessageSending = true;
  bool _letMembersSeeSavings = true;
  late bool _requirePaymentToJoin;
  late double _paymentAmount;

  @override
  void initState() {
    super.initState();
    _requirePaymentToJoin = widget.initialRequirePayment;
    _paymentAmount = widget.initialPaymentAmount;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: white,
      margin: const EdgeInsets.only(top: 8.0),
      child: ExpansionTile(
        title: const Text(
          'Group Settings',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          SendMessagesSetting(
            allowMessageSending: _allowMessageSending,
            onChanged: (value) => setState(() => _allowMessageSending = value),
          ),
          VisibilitySetting(
            letMembersSeeSavings: _letMembersSeeSavings,
            onChanged: (value) => setState(() => _letMembersSeeSavings = value),
          ),
          LoanSettings(
            groupId: widget.groupId,
            initialLoanSettings:
                widget.initialLoanSettings, // Pass loan settings
          ),
          PaymentSetting(
            requirePaymentToJoin: _requirePaymentToJoin,
            paymentAmount: _paymentAmount,
            groupId: widget.groupId,
            onPaymentToggleChanged: _handlePaymentToggleChange,
            onPaymentAmountChanged: _handlePaymentAmountChange,
          ),
        ],
      ),
    );
  }

  Future<void> _handlePaymentToggleChange(bool value) async {
    setState(() {
      _requirePaymentToJoin = value;
      _paymentAmount = value ? _paymentAmount : 0.0;
    });
    await widget.onPaymentSettingChanged(value, _paymentAmount);
  }

  Future<void> _handlePaymentAmountChange(double amount) async {
    setState(() => _paymentAmount = amount);
    await widget.onPaymentSettingChanged(_requirePaymentToJoin, amount);
  }
}
