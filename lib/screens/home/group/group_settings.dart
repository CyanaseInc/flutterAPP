import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'settings/message_setting.dart';
import 'settings/savings_visibility_setting.dart';
import 'settings/loan_setting.dart';
import 'settings/pay_join.dart';

class GroupSettings extends StatefulWidget {
  final int groupId;
  const GroupSettings({Key? key, required this.groupId}) : super(key: key);

  @override
  _GroupSettingsState createState() => _GroupSettingsState();
}

class _GroupSettingsState extends State<GroupSettings> {
  bool _allowMessageSending = true;
  bool _letMembersSeeSavings = true;
  bool _requirePaymentToJoin = false;
  double _paymentAmount = 0.0;

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
            onChanged: (value) {
              setState(() {
                _allowMessageSending = value;
              });
            },
          ),
          VisibilitySetting(
            letMembersSeeSavings: _letMembersSeeSavings,
            onChanged: (value) {
              setState(() {
                _letMembersSeeSavings = value;
              });
            },
          ),
          LoanSettings(groupId: widget.groupId),
          PaymentSetting(
            requirePaymentToJoin: _requirePaymentToJoin,
            paymentAmount: _paymentAmount,
            onPaymentToggleChanged: (value) {
              setState(() {
                _requirePaymentToJoin = value;
              });
            },
            onPaymentAmountChanged: (amount) {
              setState(() {
                _paymentAmount = amount;
              });
            },
            groupId: widget.groupId,
          ),
        ],
      ),
    );
  }
}
