import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For number formatting
import '../../../theme/theme.dart';

class ActivitySummaryCard extends StatelessWidget {
  final List<Map<String, dynamic>> portfolios;

  const ActivitySummaryCard({Key? key, required this.portfolios})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate totals from portfolios
    final totalDeposits = portfolios.fold<double>(0.0,
        (sum, portfolio) => sum + (portfolio['deposit'] as double? ?? 0.0));
    final totalNetWorth = portfolios.fold<double>(0.0,
        (sum, portfolio) => sum + (portfolio['netWorth'] as double? ?? 0.0));

    // Infer withdrawals (assumption: if netWorth < deposits, difference could be withdrawals)
    final totalWithdrawals = portfolios.fold<double>(0.0, (sum, portfolio) {
      final deposit = portfolio['deposit'] as double? ?? 0.0;
      final netWorth = portfolio['netWorth'] as double? ?? 0.0;
      return sum + (deposit > netWorth ? deposit - netWorth : 0.0);
    });

    // Number formatter for clean display
    final numberFormat = NumberFormat('#,###', 'en_US');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: primaryTwo,
        shadowColor: primaryTwo,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Activity',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: white,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActivityStat('Deposits', totalDeposits, numberFormat),
                  _buildActivityStat(
                      'Withdrawals', totalWithdrawals, numberFormat),
                  _buildActivityStat('Net Worth', totalNetWorth, numberFormat),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityStat(
      String label, double value, NumberFormat numberFormat) {
    // Format value based on magnitude
    String displayValue;
    if (value.abs() >= 1000000) {
      displayValue = '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      displayValue = '${(value / 1000).toStringAsFixed(1)}k';
    } else {
      displayValue = numberFormat.format(value);
    }

    return Column(
      children: [
        Text(
          displayValue,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: white,
          ),
        ),
      ],
    );
  }
}
