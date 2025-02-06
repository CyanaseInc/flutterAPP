import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';

class LoanButton extends StatelessWidget {
  const LoanButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => const LoanApplicationModal(),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: const Text(
        'Get Loan',
        style: TextStyle(
          color: white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class LoanApplicationModal extends StatefulWidget {
  const LoanApplicationModal({Key? key}) : super(key: key);

  @override
  _LoanApplicationModalState createState() => _LoanApplicationModalState();
}

class _LoanApplicationModalState extends State<LoanApplicationModal> {
  int _currentStep = 0;
  final TextEditingController _amountController = TextEditingController();
  int _loanPeriod = 30;
  double _calculatedPayment = 0.0;

  void nextStep() {
    setState(() {
      if (_currentStep == 0 && _amountController.text.isNotEmpty) {
        _currentStep++;
      } else if (_currentStep == 1) {
        double amount = double.tryParse(_amountController.text) ?? 0.0;
        _calculatedPayment = amount + (amount * _getInterestRate(_loanPeriod));
        _currentStep++;
      }
    });
  }

  void prevStep() {
    setState(() {
      if (_currentStep > 0) _currentStep--;
    });
  }

  double _getInterestRate(int period) {
    switch (period) {
      case 30:
        return 0.04;
      case 90:
        return 0.10;
      case 180:
        return 0.15;
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      title: const Text(
        "Loan Application",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: primaryTwo,
        ),
      ),
      content: _buildStepContent(),
      actions: _buildStepActions(),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Enter Loan Amount',
          ),
          onSubmitted: (_) => nextStep(),
        );
      case 1:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Step 2: Choose Repayment Plan'),
            DropdownButton<int>(
              value: _loanPeriod,
              onChanged: (value) => setState(() => _loanPeriod = value!),
              items: const [
                DropdownMenuItem(
                  value: 30,
                  child: Text('30 Days (4% Interest)'),
                ),
                DropdownMenuItem(
                  value: 90,
                  child: Text('90 Days (10% Interest)'),
                ),
                DropdownMenuItem(
                  value: 180,
                  child: Text('180 Days (15% Interest)'),
                ),
              ],
            ),
          ],
        );
      case 2:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Step 3: Review Loan Details'),
            Text('Loan Amount: UGX ${_amountController.text}'),
            Text('Repayment Period: $_loanPeriod days'),
            Text(
                'Total Payable Amount: UGX ${_calculatedPayment.toStringAsFixed(2)}'),
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
      if (_currentStep < 2)
        TextButton(onPressed: nextStep, child: const Text('Next')),
      if (_currentStep == 2)
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Handle loan submission logic here
          },
          child: const Text('Submit'),
        ),
    ];
  }
}
