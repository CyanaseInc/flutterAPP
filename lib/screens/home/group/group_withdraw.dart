import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';

class WithdrawButton extends StatelessWidget {
  const WithdrawButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => const WithdrawModal(),
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
            color: primaryTwo, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class WithdrawModal extends StatefulWidget {
  const WithdrawModal({Key? key}) : super(key: key);

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
    // Handle withdrawal submission logic here
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
            fontSize: 18, fontWeight: FontWeight.bold, color: primaryTwo),
      ),
      content: _buildStepContent(),
      actions: _buildStepActions(),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Step 1: Choose Withdrawal Channel',
            ),
            DropdownButton<String>(
              value: _withdrawChannel,
              onChanged: (value) => setState(() => _withdrawChannel = value!),
              items: const [
                DropdownMenuItem(
                    value: 'Mobile Money', child: Text('Mobile Money')),
                DropdownMenuItem(value: 'Bank', child: Text('Bank')),
              ],
            ),
          ],
        );
      case 1:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Step 2: Enter Withdrawal Details'),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Enter  Amount'),
            ),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration:
                  const InputDecoration(labelText: 'Enter Phone Number'),
            ),
          ],
        );
      default:
        return Container();
    }
  }

  List<Widget> _buildStepActions() {
    return [
      if (_currentStep > 0)
        TextButton(onPressed: prevStep, child: const Text('Previous')),
      TextButton(
          onPressed: nextStep,
          child: Text(_currentStep == 1 ? 'Submit' : 'Next')),
    ];
  }
}
