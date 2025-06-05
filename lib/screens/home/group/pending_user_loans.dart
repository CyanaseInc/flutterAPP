import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:intl/intl.dart'; // For date formatting

class PendingUserLoansScreen extends StatelessWidget {
  final List<Map<String, dynamic>> loans;
  final VoidCallback onLoanProcessed;

  const PendingUserLoansScreen({
    Key? key,
    required this.loans,
    required this.onLoanProcessed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My pending loan requests',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryTwo,leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios, color: white), // White back icon
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: loans.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: loans.length,
              itemBuilder: (context, index) {
                final loan = loans[index];
                return _buildLoanCard(context, loan);
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
            Icons.hourglass_empty,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Pending Loan Requests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have no loan requests pending approval.',
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

  Widget _buildLoanCard(BuildContext context, Map<String, dynamic> loan) {
    final amount = loan['amount']?.toDouble() ?? 0.0;
    final payback = loan['payback']?.toDouble() ?? 0.0;
    final interestRate = amount > 0 ? ((payback - amount) / amount) * 100 : 0.0;
    final createdAt =
        DateTime.tryParse(loan['created_at'] ?? '') ?? DateTime.now();
    final repaymentPeriod = loan['repayment_period']?.toInt() ?? 0;
    final dueDate = createdAt.add(Duration(days: repaymentPeriod));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: primaryTwo, width: 1),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: () => _viewLoanDetails(context, loan),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${loan['group_name']} - Loan #${loan['loan_id']}',
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
                    _buildDetailRow('Status', 'Pending'),
                    _buildDetailRow(
                      'Due Date',
                      DateFormat('MMM dd, yyyy').format(dueDate),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: primaryTwo, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  void _viewLoanDetails(BuildContext context, Map<String, dynamic> loan) {
    final amount = loan['amount']?.toDouble() ?? 0.0;
    final payback = loan['payback']?.toDouble() ?? 0.0;
    final interestRate = amount > 0 ? ((payback - amount) / amount) * 100 : 0.0;
    final createdAt =
        DateTime.tryParse(loan['created_at'] ?? '') ?? DateTime.now();
    final repaymentPeriod = loan['repayment_period']?.toInt() ?? 0;
    final dueDate = createdAt.add(Duration(days: repaymentPeriod));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          '${loan['group_name']} - Loan #${loan['loan_id']}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                'Loan Amount',
                NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0)
                    .format(amount),
              ),
              _buildDetailRow('Group', loan['group_name'] ?? 'Unknown'),
              _buildDetailRow(
                'Request Date',
                DateFormat('MMM dd, yyyy').format(createdAt),
              ),
              _buildDetailRow(
                'Due Date',
                DateFormat('MMM dd, yyyy').format(dueDate),
              ),
              _buildDetailRow(
                'Total Payback',
                NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0)
                    .format(payback),
              ),
              _buildDetailRow(
                'Interest Rate',
                '${interestRate.toStringAsFixed(2)}%',
              ),
              _buildDetailRow('Repayment Period', '$repaymentPeriod days'),
              _buildDetailRow('Status', 'Pending'),
              _buildDetailRow('Purpose', 'Not specified'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: primaryTwo,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
