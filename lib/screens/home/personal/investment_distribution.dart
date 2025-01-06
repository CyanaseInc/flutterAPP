import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // For pie chart implementation
import '../../../theme/theme.dart';

class InvestmentDistribution extends StatelessWidget {
  final List<Map<String, dynamic>> portfolios;

  const InvestmentDistribution({Key? key, required this.portfolios})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure deposits are treated as doubles, using type casting
    List<double> deposits = portfolios
        .map((portfolio) => (portfolio['deposit'] as num)
            .toDouble()) // Cast to num then convert to double
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pie Chart
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0, // No space between sections
                centerSpaceRadius: 40, // Space in the center
                sections: deposits.asMap().entries.map((entry) {
                  final index = entry.key;
                  final deposit = entry.value;
                  return PieChartSectionData(
                    value: deposit,
                    color: _getColorForIndex(index),
                    // Removed the title field from here
                    radius: 40,
                  );
                }).toList(),
              ),
            ),
          ),
          // Investment Legends
          const SizedBox(height: 16),
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
    );
  }

  Color _getColorForIndex(int index) {
    // You can use custom colors for the different sections
    List<Color> colors = [
      primaryDark,
      primaryTwoDark,
      primaryLight,
      primaryTwoDark
    ];
    return colors[index % colors.length];
  }

  Widget _buildLegendItem(String portfolioName, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          portfolioName,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
