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
          builder: (BuildContext context) {
            return LoanModal();
          },
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
        style:
            TextStyle(color: white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class LoanModal extends StatefulWidget {
  @override
  _LoanModalState createState() => _LoanModalState();
}

class _LoanModalState extends State<LoanModal> {
  int _currentStep = 0;
  double _loanAmount = 0.0;
  int _loanPeriod = 30;
  double _totalPayable = 0.0;

  void _nextStep() {
    setState(() {
      _currentStep++;
    });
  }

  void _prevStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      }
    });
  }

  void _calculateTotalPayable() {
    double interestRate;
    switch (_loanPeriod) {
      case 30:
        interestRate = 0.04;
        break;
      case 90:
        interestRate = 0.10;
        break;
      case 180:
        interestRate = 0.15;
        break;
      default:
        interestRate = 0.04;
    }
    _totalPayable = _loanAmount + (_loanAmount * interestRate);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Loan Application'),
      content: Container(
        width: double.maxFinite,
        child: _getStepContent(),
      ),
      actions: [
        if (_currentStep > 0)
          TextButton(
            child: Text('Back'),
            onPressed: _prevStep,
          ),
        if (_currentStep < 2)
          TextButton(
            child: Text('Next'),
            onPressed: _nextStep,
          ),
        if (_currentStep == 2)
          TextButton(
            child: Text('Submit'),
            onPressed: () {
              // Handle submission logic here
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Loan application submitted!')),
              );
            },
          ),
      ],
    );
  }

  Widget _getStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          children: [
            TextField(
              keyboardType: TextInputType.number,
              onChanged: (value) => _loanAmount = double.tryParse(value) ?? 0.0,
              decoration: InputDecoration(labelText: 'Loan Amount'),
            ),
          ],
        );
      case 1:
        return Column(
          children: [
            Text('Step 2: Choose Repayment Plan'),
            DropdownButton<int>(
              value: _loanPeriod,
              onChanged: (value) {
                setState(() {
                  _loanPeriod = value!;
                });
              },
              items: [
                DropdownMenuItem(
                    child: Text('30 Days (4% Interest)'), value: 30),
                DropdownMenuItem(
                    child: Text('90 Days (10% Interest)'), value: 90),
                DropdownMenuItem(
                    child: Text('180 Days (15% Interest)'), value: 180),
              ],
            ),
          ],
        );
      case 2:
        _calculateTotalPayable();
        return Column(
          children: [
            Text('Step 3: Loan Summary'),
            Text('Loan Amount: ${_loanAmount.toStringAsFixed(2)}'),
            Text('Repayment Period: $_loanPeriod days'),
            Text('Total Payable: ${_totalPayable.toStringAsFixed(2)}'),
          ],
        );
      default:
        return Container();
    }
  }
}
