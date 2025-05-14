import 'package:cyanase/helpers/loader.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:intl/intl.dart';

class OngoingLoansScreen extends StatefulWidget {
  final List<Map<String, dynamic>> loans;
  final VoidCallback onLoanUpdated;

  const OngoingLoansScreen({
    Key? key,
    required this.loans,
    required this.onLoanUpdated,
  }) : super(key: key);

  @override
  _OngoingLoansScreenState createState() => _OngoingLoansScreenState();
}

class _OngoingLoansScreenState extends State<OngoingLoansScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _paymentController = TextEditingController();
  final Map<int, bool> _loadingStates = {};

  Future<bool> payLoan({
    required int loanId,
    required int groupId,
    required double amount,
  }) async {
    try {
      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isEmpty) {
        throw Exception('User profile not found');
      }
      final token = userProfile.first['token'] as String;

      final response = await ApiService.recordLoanPayment(
        token: token,
        loanId: loanId,
        groupId: groupId,
        amount: amount,
      );

      if (!response['success']) {
        throw Exception(response['message'] ?? 'Payment failed');
      }

      return true;
    } catch (e) {
      print('PayLoan Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to record payment: $e')),
      );
      return false;
    }
  }

  @override
  void dispose() {
    _paymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ongoing Loans',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryTwo,
        elevation: 0,
        centerTitle: true,
      ),
      body: widget.loans.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: widget.loans.length,
              itemBuilder: (context, index) {
                final loan = widget.loans[index];
                return _buildLoanCard(context, loan, index);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Ongoing Loans',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have no active loans at the moment.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoanCard(
      BuildContext context, Map<String, dynamic> loan, int index) {
    final amount = loan['amount']?.toDouble() ?? 0.0;
    final payback = loan['payback']?.toDouble() ?? 0.0;
    final createdAt =
        DateTime.tryParse(loan['created_at'] ?? '') ?? DateTime.now();
    final repaymentPeriod = loan['repayment_period']?.toInt() ?? 0;
    final dueDate = createdAt.add(Duration(days: repaymentPeriod));
    final amountPaid = loan['amount_paid']?.toDouble() ?? 0.0;

    final progress = payback > 0 ? amountPaid / payback : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${loan['group_name']} - Loan #${index + 1}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Amount',
              NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0)
                  .format(amount),
            ),
            _buildDetailRow('Group', loan['group_name'] ?? 'Unknown'),
            _buildDetailRow(
              'Due Date',
              DateFormat('MMM dd, yyyy').format(dueDate),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(primaryTwo),
              minHeight: 6,
            ),
            const SizedBox(height: 4),
            Text(
              'Progress: ${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => _viewLoanDetails(context, loan, index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Pay Loan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewLoanDetails(
      BuildContext context, Map<String, dynamic> loan, int index) {
    final amount = loan['amount']?.toDouble() ?? 0.0;
    final payback = loan['payback']?.toDouble() ?? 0.0;
    final interestRate = amount > 0 ? ((payback - amount) / amount) * 100 : 0.0;
    final createdAt =
        DateTime.tryParse(loan['created_at'] ?? '') ?? DateTime.now();
    final repaymentPeriod = loan['repayment_period']?.toInt() ?? 0;
    final dueDate = createdAt.add(Duration(days: repaymentPeriod));
    final amountPaid = loan['amount_paid']?.toDouble() ?? 0.0;
    final loanBalance = loan['outstanding_balance']?.toDouble() ?? 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${loan['group_name']} - Loan #${index + 1}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                _buildDetailRow(
                  'Loan Amount',
                  NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0)
                      .format(amount),
                ),
                _buildDetailRow('Group', loan['group_name'] ?? 'Unknown'),
                _buildDetailRow(
                  'Issue Date',
                  DateFormat('MMM dd, yyyy').format(createdAt),
                ),
                _buildDetailRow(
                  'Due Date',
                  DateFormat('MMM dd, yyyy').format(dueDate),
                ),
                _buildDetailRow(
                  'Interest Rate',
                  '${interestRate.toStringAsFixed(2)}%',
                ),
                _buildDetailRow(
                  'Total Payback',
                  NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0)
                      .format(payback),
                ),
                _buildDetailRow(
                  'Amount Paid',
                  NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0)
                      .format(amountPaid),
                ),
                _buildDetailRow(
                  'Loan Balance',
                  NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0)
                      .format(loanBalance),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _paymentController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Payment Amount (UGX)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loadingStates[loan['loan_id']] == true
                        ? null
                        : () async {
                            final paymentAmount =
                                double.tryParse(_paymentController.text);
                            if (paymentAmount == null || paymentAmount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Please enter a valid payment amount')),
                              );
                              return;
                            }

                            setState(() {
                              _loadingStates[loan['loan_id']] = true;
                            });

                            final success = await payLoan(
                              loanId: loan['loan_id'] as int,
                              groupId: loan['group_id'] as int,
                              amount: paymentAmount,
                            );

                            setState(() {
                              _loadingStates[loan['loan_id']] = false;
                            });

                            if (success) {
                              _paymentController.clear();
                              widget.onLoanUpdated();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Payment recorded successfully')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Payment failed, please try again')),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: _loadingStates[loan['loan_id']] == true
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Loader(),
                          )
                        : const Text(
                            'Pay Loan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
