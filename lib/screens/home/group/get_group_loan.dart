import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/loader.dart';

class LoanButton extends StatelessWidget {
  final int groupId;
  final Map<String, dynamic> loansettings;
  const LoanButton(
      {Key? key, required this.groupId, required this.loansettings})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => LoanApplicationModal(
              groupId: groupId, loansettings: loansettings),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        elevation: 2,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: const Text('Get Loan'),
    );
  }
}

class LoanApplicationModal extends StatefulWidget {
  final int groupId;
  final Map<String, dynamic> loansettings;

  const LoanApplicationModal(
      {Key? key, required this.groupId, required this.loansettings})
      : super(key: key);

  @override
  _LoanApplicationModalState createState() => _LoanApplicationModalState();
}

class _LoanApplicationModalState extends State<LoanApplicationModal> {
  int _currentStep = 0;
  final TextEditingController _amountController = TextEditingController();
  int _loanPeriod = 0;
  double _calculatedPayment = 0.0;
  String? _amountError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize with the first available period
    _loanPeriod = widget.loansettings['periods'][0]['days'];
  }

  void _nextStep() {
    setState(() {
      if (_currentStep == 0) {
        double? amount = double.tryParse(_amountController.text);
        if (amount == null || amount <= 0) {
          _amountError = 'Please enter a valid amount';
          return;
        }
        _amountError = null;
        _currentStep++;
      } else if (_currentStep == 1) {
        double amount = double.parse(_amountController.text);
        final period = widget.loansettings['periods'].firstWhere(
          (p) => p['days'] == _loanPeriod,
          orElse: () => {'interestRate': 0.0},
        );
        final interestRate = period['interestRate'] / 100;
        _calculatedPayment = amount + (amount * interestRate);
        _currentStep++;
      }
    });
  }

  void _prevStep() {
    setState(() {
      if (_currentStep > 0) _currentStep--;
      _amountError = null;
    });
  }

  Future<void> _submitLoanApplication() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);

      if (userProfile.isEmpty) {
        throw Exception('User profile not found');
      }

      final token = userProfile.first['token'] as String;
      final amount = double.parse(_amountController.text);

      final data = {
        'groupId': widget.groupId,
        'amount': amount,
        'repaymentPeriod': _loanPeriod,
        'payback': _calculatedPayment,
      };

      final response = await ApiService.submitLoanApplication(token, data);
      if (response['success'] == true) {
        Navigator.of(context).pop();
        _showSuccessDialog();
      } else {
        Navigator.of(context).pop();
        _showErrorDialog(
            response['message'] ?? 'Failed to submit loan application');
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorDialog('Failed to submit loan application: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: white,
        title: const Text(
          'Application Submitted',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryTwo,
          ),
        ),
        content: const Text(
          'Your loan application is under review by admins.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: white,
        title: const Text(
          'Submission Failed',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: white,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      title: const Text(
        'Loan Application',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primaryTwo,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStepIndicator(),
            const SizedBox(height: 16),
            _isSubmitting ? const Center(child: Loader()) : _buildStepContent(),
          ],
        ),
      ),
      actions: _isSubmitting ? [] : _buildStepActions(),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(3, (index) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 4,
            decoration: BoxDecoration(
              color: index <= _currentStep ? primaryColor : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 1: Enter Loan Amount',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Loan Amount (UGX)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                errorText: _amountError,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: (_) => _nextStep(),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 2: Choose Repayment Plan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _loanPeriod,
              onChanged: (value) => setState(() => _loanPeriod = value!),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: (widget.loansettings['periods'] as List).map((period) {
                final days = period['days'] as int;
                final rate = period['interestRate'] as double;
                return DropdownMenuItem(
                  value: days,
                  child: Text('$days Days ($rate%)'),
                );
              }).toList(),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 3: Review Loan Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildReviewItem('Loan Amount', 'UGX ${_amountController.text}'),
            const SizedBox(height: 12),
            _buildReviewItem('Repayment Period', '$_loanPeriod days'),
            const SizedBox(height: 12),
            _buildReviewItem(
              'Payback',
              'UGX ${_calculatedPayment.toStringAsFixed(2)}',
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildReviewItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildStepActions() {
    return [
      if (_currentStep > 0)
        TextButton(
          onPressed: _prevStep,
          child: const Text(
            'Previous',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      const Spacer(),
      if (_currentStep < 2)
        ElevatedButton(
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            elevation: 2,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Next'),
        ),
      if (_currentStep == 2)
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitLoanApplication,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            elevation: 2,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Submit'),
        ),
    ];
  }
}
