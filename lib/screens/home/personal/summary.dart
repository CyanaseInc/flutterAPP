import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

class ActivitySummaryCard extends StatelessWidget {
  final List<Map<String, dynamic>> portfolios;

  const ActivitySummaryCard({Key? key, required this.portfolios})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalDeposits = portfolios.fold<int>(
        0, (sum, portfolio) => sum + (portfolio['deposits'] as int? ?? 0));
    final totalWithdrawals = portfolios.fold<int>(
        0, (sum, portfolio) => sum + (portfolio['withdrawals'] as int? ?? 0));
    final totalGoals = portfolios.fold<int>(
        0, (sum, portfolio) => sum + (portfolio['goals'] as int? ?? 0));
    final totalInvestments = portfolios.fold<int>(
        0, (sum, portfolio) => sum + (portfolio['investments'] as int? ?? 0));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: primaryTwo, // Light background color
        shadowColor: primaryTwo, // Shadow color
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Activity heading
              Text(
                'Activity',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 16),

              // Activity stats grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActivityStat('Deposit', totalDeposits),
                  _buildActivityStat('Withdraw', totalWithdrawals),
                  _buildActivityStat('Goals', totalGoals),
                  _buildActivityStat('Investments', totalInvestments),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityStat(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white, // Updated text color to white
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white, // Updated text color to white
          ),
        ),
      ],
    );
  }
}
