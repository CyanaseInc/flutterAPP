import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'settings/message_setting.dart';
import 'settings/loan_setting.dart';
import 'settings/pay_join.dart';
import 'settings/subscribe.dart';

class GroupSettings extends StatefulWidget {
  final int groupId;
  final bool initialRequirePayment;
  final double initialPaymentAmount;
  final Map<String, dynamic> initialLoanSettings;
  final Function(bool, double) onPaymentSettingChanged;
  final bool isAdminMode;
  final bool initialRequireSubscription;
  final double initialSubscriptionAmount;
  const GroupSettings({
    Key? key,
    required this.groupId,
    required this.isAdminMode,
    required this.initialRequireSubscription,
    required this.initialSubscriptionAmount,
    required this.initialRequirePayment,
    required this.initialPaymentAmount,
    required this.initialLoanSettings,
    required this.onPaymentSettingChanged,
  }) : super(key: key);

  @override
  _GroupSettingsState createState() => _GroupSettingsState();
}

class _GroupSettingsState extends State<GroupSettings> {
  late bool _allowMessageSending;
  late bool _requirePaymentToJoin;
  late bool _requireSubscription;
  late double _paymentAmount;
  late double _subscriptionAmount;
  @override
  void initState() {
    super.initState();
    _allowMessageSending = widget.isAdminMode;
    _requirePaymentToJoin = widget.initialRequirePayment;
    _requireSubscription = widget.initialRequireSubscription;
    _paymentAmount = widget.initialPaymentAmount;
    _subscriptionAmount = widget.initialSubscriptionAmount;
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
            groupId: widget.groupId,
            allowMessageSending: _allowMessageSending,
            onChanged: (value) => setState(() => _allowMessageSending = value),
          ),
          const SizedBox(height: 8),
          LoanSettings(
            groupId: widget.groupId,
            initialLoanSettings: widget.initialLoanSettings,
          ),
          const SizedBox(height: 8),
          SubscriptionSetting(
            requireSubscription: _requireSubscription,
            paymentAmount: _paymentAmount,
            groupId: widget.groupId,
            paymentFrequency: 'Monthly', // Example value, replace as needed
            onPaymentFrequencyChanged: (frequency) {
              // Handle frequency change logic here
            },
            onPaymentToggleChanged: _handleSubscriptionToggleChange,
            onPaymentAmountChanged: _handleSubsriptiontAmountChange,
          ),
          const SizedBox(height: 8),
          PaymentSetting(
            requirePaymentToJoin: _requirePaymentToJoin,
            paymentAmount: _paymentAmount,
            groupId: widget.groupId,
            onPaymentToggleChanged: _handlePaymentToggleChange,
            onPaymentAmountChanged: _handlePaymentAmountChange,
          ),
          const SizedBox(height: 8),
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

  Future<void> _handleSubscriptionToggleChange(bool value) async {
    setState(() {
      _requireSubscription = value;
      _subscriptionAmount = value ? _subscriptionAmount : 0.0;
    });
    await widget.onPaymentSettingChanged(value, _subscriptionAmount);
  }

  Future<void> _handlePaymentAmountChange(double amount) async {
    setState(() => _paymentAmount = amount);
    await widget.onPaymentSettingChanged(_requirePaymentToJoin, amount);
  }

  Future<void> _handleSubsriptiontAmountChange(double amount) async {
    setState(() => _paymentAmount = amount);
    await widget.onPaymentSettingChanged(_requireSubscription, amount);
  }
}
