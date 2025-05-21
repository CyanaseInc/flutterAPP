import 'package:cyanase/helpers/withdraw_helper.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';

class WithdrawButton extends StatelessWidget {
  final int groupId; // <- Make sure to pass groupId
  final String withdrawType;
  const WithdrawButton({
    Key? key,
    required this.groupId,
    required this.withdrawType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => WithdrawModal(
            groupId: groupId,
            withdrawType: withdrawType,
          ),
        );
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: primaryTwo),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: const Text(
        'Withdraw',
        style: TextStyle(
          color: primaryTwo,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class WithdrawModal extends StatefulWidget {
  final int groupId;
  final String withdrawType;
  const WithdrawModal({
    Key? key,
    required this.groupId,
    required this.withdrawType,
  }) : super(key: key);

  @override
  _WithdrawModalState createState() => _WithdrawModalState();
}

class _WithdrawModalState extends State<WithdrawModal> {
  int _currentStep = 0;
  String _withdrawChannel = 'Mobile Money';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  void nextStep() {
    setState(() {
      if (_currentStep == 0) {
        _currentStep++;
      } else if (_currentStep == 1 &&
          _amountController.text.isNotEmpty &&
          _phoneController.text.isNotEmpty) {
        _submitWithdraw();
      }
    });
  }

  void prevStep() {
    setState(() {
      if (_currentStep > 0) _currentStep--;
    });
  }

  void _submitWithdraw() {
    Navigator.of(context).pop();
    // TODO: Handle withdrawal submission logic here
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      title: const Text(
        "Withdraw Funds",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: primaryTwo,
        ),
      ),
      content: SizedBox(
        height: 400, // Adjust as needed
        child: WithdrawHelper(
          withdrawDetails: "Withdraws are instant",
          withdrawType: widget.withdrawType,
          groupId: widget.groupId,
        ),
      ),
    );
  }
}
