import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/loader.dart';
import 'package:intl/intl.dart';

class PendingAdminLoansScreen extends StatefulWidget {
  final List<Map<String, dynamic>> loans;
  final VoidCallback onLoanProcessed;

  const PendingAdminLoansScreen({
    Key? key,
    required this.loans,
    required this.onLoanProcessed,
  }) : super(key: key);

  @override
  _PendingAdminLoansScreenState createState() =>
      _PendingAdminLoansScreenState();
}

class _PendingAdminLoansScreenState extends State<PendingAdminLoansScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Map<String, bool> _loadingStates = {};
  late List<Map<String, dynamic>> loans; // Local state copy of loans

  @override
  void initState() {
    super.initState();
    loans = List.from(widget.loans); // Initialize with widget.loans
  }

  Future<Map<String, dynamic>> processLoan({
    required int loanId,
    required int groupId,
    required bool approved,
  }) async {
    try {
      print('Starting loan processing...');
      final db = await _dbHelper.database;
      print('Database connection successful');
      
      final userProfile = await db.query('profile', limit: 1);
      print('User profile query result: $userProfile');
      
      if (userProfile.isEmpty) {
        print('Error: User profile not found in database');
        throw Exception('User profile not found');
      }
      
      // Ensure token is properly cast to String
      final token = userProfile.first['token']?.toString();
      print('Token retrieved: ${token != null ? 'Token exists' : 'Token is null'}');
      
      if (token == null) {
        print('Error: Invalid token format - token is null');
        throw Exception('Invalid token format');
      }

      print('Processing loan with data: {loanId: $loanId, groupId: $groupId, approved: $approved}');
      
      final response = await ApiService.processLoanRequest(
        token: token,
        loanId: loanId,
        groupId: groupId,
        approved: approved,
      );

      print('API Response received: $response');

      if (response == null) {
        print('Error: No response from server');
        throw Exception('No response from server');
      }

      if (response['success'] == false) {
        print('Error: Loan processing failed - ${response['message']}');
        throw Exception(response['message'] ?? 'Loan processing failed');
      }

      print('Loan processed successfully');
      return {
        'success': true,
        'message': response['message'] ?? 'Loan processed successfully',
        'loan_status': response['loan_status'] ?? 'processed'
      };
    } catch (e, stackTrace) {
      print('Error: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process loan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return {'success': false, 'message': e.toString()};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pending Loan Requests',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryTwo,
         leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
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
            'There are no loan requests awaiting your approval.',
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
    final totalSavings = loan['total_savings']?.toDouble() ?? 0.0;
    final interestRate = amount > 0 ? ((payback - amount) / amount) * 100 : 0.0;
    final createdAt =
        DateTime.tryParse(loan['created_at'] ?? '') ?? DateTime.now();
    final repaymentPeriod = loan['repayment_period']?.toInt() ?? 0;
    final dueDate = createdAt.add(Duration(days: repaymentPeriod));
    final loanKey = '${loan['loan_id']}';
    final isApproving = _loadingStates['$loanKey-approve'] ?? false;
    final isDenying = _loadingStates['$loanKey-deny'] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: primaryTwo, width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            _buildDetailRow('Borrower', loan['full_name'] ?? 'Unknown'),
            _buildDetailRow(
              'Savings in Group',
              NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0)
                  .format(totalSavings),
              highlight: true,
            ),
            _buildDetailRow(
              'Loan Amount',
              NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0)
                  .format(amount),
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
            _buildDetailRow(
              'Repayment Period',
              '$repaymentPeriod days',
            ),
            _buildDetailRow(
              'Due Date',
              DateFormat('MMM dd, yyyy').format(dueDate),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: isApproving || isDenying
                      ? null
                      : () => _confirmProcessLoan(context, loan, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: isApproving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: Loader(),
                        )
                      : const Text(
                          'Approve',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isApproving || isDenying
                      ? null
                      : () => _confirmProcessLoan(context, loan, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: isDenying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Deny',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmProcessLoan(
      BuildContext context, Map<String, dynamic> loan, bool approved) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approved ? 'Approve Loan' : 'Deny Loan'),
        content: Text(
          'Are you sure you want to ${approved ? 'approve' : 'deny'} the loan request for ${loan['full_name']} in ${loan['group_name']} (Loan #${loan['loan_id']})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              final loanKey = '${loan['loan_id']}';
              if (!mounted) return;
              setState(() {
                _loadingStates['$loanKey-${approved ? 'approve' : 'deny'}'] = true;
              });

              try {
                print("my loan is, $loan");
                // Ensure proper type casting for loan_id and group_id
                final response = await processLoan(
                  loanId: int.parse(loan['loan_id'].toString()),
                  groupId: int.parse(loan['group_id'].toString()),
                  approved: approved,
                );

                if (!mounted) return;

                if (response['success']) {
                  // Remove the loan from the list immediately after successful processing
                  setState(() {
                    loans.removeWhere((l) => l['loan_id'] == loan['loan_id']);
                  });

                  // Notify parent to refresh data and update counts
                  widget.onLoanProcessed();

                  if (mounted) {
                    // Show success message with remaining count
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${response['message']} (${loans.length} remaining)',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // If no more loans, pop back to previous screen
                    if (loans.isEmpty) {
                      Navigator.pop(context);
                    }
                  }
                } else {
                  throw Exception(response['message'] ?? 'Failed to process loan');
                }
              } catch (e) {
                print('Error: ${e.toString()}');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _loadingStates.remove('$loanKey-${approved ? 'approve' : 'deny'}');
                  });
                }
              }
            },
            child: Text(
              approved ? 'Approve' : 'Deny',
              style: TextStyle(
                color: approved ? Colors.green[600] : Colors.red[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool highlight = false}) {
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
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: highlight ? primaryColor : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
