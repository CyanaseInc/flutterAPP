import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/theme.dart';

class ActivitySummaryCard extends StatelessWidget {
  final List<Map<String, dynamic>> portfolios;

  const ActivitySummaryCard({Key? key, required this.portfolios})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate totals
    final totalDeposits = portfolios.fold<double>(
        0.0, (sum, p) => sum + (p['deposit'] as double? ?? 0.0));
    final totalNetWorth = portfolios.fold<double>(
        0.0, (sum, p) => sum + (p['netWorth'] as double? ?? 0.0));
    final totalProfitLoss = totalNetWorth - totalDeposits;
    final totalWithdrawals = 0.0; // Replace with API data if available

    final numberFormat = NumberFormat('#,##0.0', 'en_US'); // Updated to show 1 decimal place

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: primaryTwo,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Investment Summary',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActivityStat('Total Deposits', totalDeposits, numberFormat),
                  _buildActivityStat('Current Value', totalNetWorth, numberFormat),
                  _buildProfitLossStat(totalProfitLoss, numberFormat, context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityStat(
    String label,
    double value,
    NumberFormat numberFormat, {
    Color? color,
  }) {
    final displayValue = _formatValue(value, numberFormat);
    final textColor = color ?? white;

    return Column(
      children: [
        Text(
          displayValue,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: textColor.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildProfitLossStat(
    double value,
    NumberFormat numberFormat,
    BuildContext context,
  ) {
    final isProfit = value >= 0;
    final displayValue = _formatValue(value.abs(), numberFormat);
    final textColor = isProfit ? Colors.green : Colors.red;
    final label = isProfit ? 'Profit' : 'Loss';
    final icon = isProfit
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$label: ${isProfit ? "Gains" : "Losses"} calculated as Current Value minus Total Deposits.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      },
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                child: Icon(
                  icon,
                  color: textColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 4),
              AnimatedDefaultTextStyle(
                duration: Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                child: Text(isProfit ? '+$displayValue' : '-$displayValue'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: textColor.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(double value, NumberFormat numberFormat) {
    final absValue = value.abs();
    if (absValue >= 1000000) {
      return '${numberFormat.format(value / 1000000)}M';
    } else if (absValue >= 1000) {
      return '${numberFormat.format(value / 1000)}k';
    }
    return numberFormat.format(value);
  }
}