import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/theme.dart';
import 'dart:math' as math; // For log function

class InvestmentDistribution extends StatelessWidget {
  final List<Map<String, dynamic>> portfolios;

  const InvestmentDistribution({Key? key, required this.portfolios})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure deposits are treated as doubles
    List<double> deposits = portfolios
        .map((portfolio) => (portfolio['deposit'] as num).toDouble())
        .toList();

    // Handle case with no data or all zeros
    if (deposits.isEmpty || deposits.every((d) => d == 0)) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: white,
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Investment Distribution',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryTwo,
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: Text(
                    'No investment data available',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Calculate transformed values for pie chart
    final minVisibleValue = 1.0; // Minimum value to ensure visibility
    List<double> transformedDeposits = deposits.map((deposit) {
      if (deposit <= 0) return minVisibleValue; // Handle zero or negative
      // Use log scaling to compress large differences
      return math.log(deposit + 1) + minVisibleValue; // +1 to avoid log(0)
    }).toList();

    // Debugging: Print raw and transformed values

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        color: white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Investment Distribution',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryTwo,
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                height: 250,
                child: PieChart(
                  PieChartData(
                    sectionsSpace:
                        2, // Small space between sections for clarity
                    centerSpaceRadius: 50, // Adjusted center space
                    sections: transformedDeposits.asMap().entries.map((entry) {
                      final index = entry.key;
                      final transformedValue = entry.value;
                      final originalDeposit = deposits[index];
                      return PieChartSectionData(
                        value: transformedValue,
                        color: _getColorForIndex(index),
                        radius: 60, // Slightly larger radius
                        title: originalDeposit >= 1000
                            ? '${(originalDeposit / 1000).toStringAsFixed(1)}k'
                            : originalDeposit.toStringAsFixed(0),
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        badgeWidget: originalDeposit < transformedValue * 10
                            ? Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  originalDeposit.toStringAsFixed(0),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : null,
                        showTitle: originalDeposit >= transformedValue * 10,
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 16.0,
                children: portfolios.asMap().entries.map((entry) {
                  final index = entry.key;
                  final portfolio = entry.value;
                  return _buildLegendItem(
                    portfolio['name'] as String,
                    _getColorForIndex(index),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForIndex(int index) {
    List<Color> colors = [
      primaryColor,
      primaryTwoDark,
      primaryLight,
      primaryTwoDark,
      white,
    ];
    return colors[index % colors.length];
  }

  Widget _buildLegendItem(String portfolioName, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Text(
          portfolioName,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
