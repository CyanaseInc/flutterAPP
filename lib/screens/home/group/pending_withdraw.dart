import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:intl/intl.dart';

class PendingWithdrawScreen extends StatefulWidget {
  final List<Map<String, dynamic>> withdraws;
  final VoidCallback onWithdrawProcessed;

  const PendingWithdrawScreen({
    Key? key,
    required this.withdraws,
    required this.onWithdrawProcessed,
  }) : super(key: key);

  @override
  _PendingWithdrawScreenState createState() => _PendingWithdrawScreenState();
}

class _PendingWithdrawScreenState extends State<PendingWithdrawScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Map<String, bool> _loadingStates = {};
  late List<Map<String, dynamic>> withdraws;

  @override
  void initState() {
    super.initState();
    withdraws = List.from(widget.withdraws);
    debugPrint('Initialized withdraws: ${withdraws.length}');
  }

  @override
  void didUpdateWidget(PendingWithdrawScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local withdraws list if the parent passes a new list
    if (widget.withdraws != oldWidget.withdraws) {
      setState(() {
        withdraws = List.from(widget.withdraws);
        debugPrint('Updated withdraws from parent: ${withdraws.length}');
      });
    }
  }

  Future<Map<String, dynamic>> processWithdraw({
    required int withdrawId,
    required int groupId,
    required bool approved,
  }) async {
    try {
      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isEmpty) {
        throw Exception('User profile not found');
      }
      final token = userProfile.first['token'] as String;
      debugPrint('Processing withdraw: $withdrawId, Group: $groupId, Approved: $approved');
      final response = await ApiService.processWithdrawRequest(
        token: token,
        withdrawId: withdrawId,
        groupId: groupId,
        approved: approved,
      );

      if (!response['success']) {
        throw Exception(response['message'] ?? 'Withdraw processing failed');
      }

      return response;
    } catch (e) {
      debugPrint('Process withdraw error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building UI with withdraws: ${withdraws.length}');
    return WillPopScope(
      onWillPop: () async {
        return !_loadingStates.values.any((isLoading) => isLoading);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Withdraw Requests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: primaryTwo,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          elevation: 0,
          centerTitle: true,
        ),
        body: withdraws.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: withdraws.length,
                itemBuilder: (context, index) {
                  final withdraw = withdraws[index];
                  return _buildWithdrawCard(context, withdraw);
                },
              ),
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
            'No Pending Withdraw Requests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no withdraw requests awaiting your approval.',
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

  Widget _buildWithdrawCard(BuildContext context, Map<String, dynamic> withdraw) {
    final amount = withdraw['amount']?.toDouble() ?? 0.0;
    final totalSavings = withdraw['total_savings']?.toDouble() ?? 0.0;
    final createdAt =
        DateTime.tryParse(withdraw['created_at'] ?? '') ?? DateTime.now();
    final withdrawKey = '${withdraw['withdraw_id']}';
    final isApproving = _loadingStates['$withdrawKey-approve'] ?? false;
    final isDenying = _loadingStates['$withdrawKey-deny'] ?? false;

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
              '${withdraw['group_name'] ?? 'Unknown Group'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Member', withdraw['full_name'] ?? 'Unknown'),
            _buildDetailRow(
              'Savings in Group',
              NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0)
                  .format(totalSavings),
              highlight: true,
            ),
            _buildDetailRow(
              'Withdraw Amount',
              NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0)
                  .format(amount),
            ),
            _buildDetailRow(
              'Requested On',
              DateFormat('MMM dd, yyyy').format(createdAt),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: isApproving || isDenying
                      ? null
                      : () => _confirmProcessWithdraw(context, withdraw, true),
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
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
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
                      : () => _confirmProcessWithdraw(context, withdraw, false),
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

  void _confirmProcessWithdraw(
      BuildContext context, Map<String, dynamic> withdraw, bool approved) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approved ? 'Approve Withdraw' : 'Deny Withdraw'),
        content: Text(
          'Are you sure you want to ${approved ? 'approve' : 'deny'} the withdraw request for ${withdraw['full_name'] ?? 'Unknown'} in ${withdraw['group_name'] ?? 'Unknown Group'} (Withdraw #${withdraw['withdraw_id']})?',
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

              final withdrawKey = '${withdraw['withdraw_id']}';
              final withdrawId = int.tryParse(withdraw['withdraw_id'].toString());
              final groupId = int.tryParse(withdraw['group_id'].toString());

              if (withdrawId == null || groupId == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid withdraw or group ID'),
                    ),
                  );
                }
                return;
              }

              // Store ScaffoldMessengerState before async operation
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              if (!mounted) return; // Early exit if not mounted

              setState(() {
                _loadingStates['$withdrawKey-${approved ? 'approve' : 'deny'}'] =
                    true;
              });

              final response = await processWithdraw(
                withdrawId: withdrawId,
                groupId: groupId,
                approved: approved,
              );

              if (!mounted) return; // Exit if widget is no longer mounted

              setState(() {
                _loadingStates
                    .remove('$withdrawKey-${approved ? 'approve' : 'deny'}');
                if (response['success']) {
                  // Remove the withdraw from the list
                  withdraws.removeWhere((w) => w['withdraw_id'].toString() == withdrawId.toString());
                  debugPrint(
                      'Removed withdraw $withdrawId from list. Remaining: ${withdraws.length}');
                }
              });

              if (response['success']) {
                // Notify parent to update badge or refresh state
                widget.onWithdrawProcessed();
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(response['message'] ??
                        'Withdraw ${approved ? 'approved' : 'denied'} successfully'),
                  ),
                );
              } else {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                        'Failed to process withdraw: ${response['message']}'),
                  ),
                );
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