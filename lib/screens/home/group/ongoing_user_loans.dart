import 'package:cyanase/helpers/deposit.dart';
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
          'On going loans',
          style: TextStyle(fontSize: 20, color: white),
        ),
        backgroundColor: primaryTwo,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios, color: white), // White back icon
          onPressed: () => Navigator.of(context).pop(),
        ),
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

  Future<void> _handleLoanPayment(Map<String, dynamic> loan) async {
    // Show loading popup

    final loanID = loan['loan_id'];
    final groupID = loan['group_id'];

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        content: SizedBox(
          height: 350,
          child: DepositHelper(
            depositCategory: 'pay_loan',
            loanId: loanID,
            groupId: groupID,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Closes the dialog
            },
            child: Text('Cancel'),
          ),
        ],
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loadingStates[loan['loan_id']] == true
                        ? null
                        : () => _handleLoanPayment(loan),
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
                )
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
