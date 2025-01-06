import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // For graph implementation
import '../../../theme/theme.dart';
import 'summary.dart';
import 'investment_distribution.dart';

class Portfolio extends StatelessWidget {
  final List<Map<String, dynamic>> portfolios = [
    {
      'name': 'Bombo Land',
      'deposit': 4000,
      'netWorth': 4500,
      'performance': [
        FlSpot(0, 4000),
        FlSpot(1, 4200),
        FlSpot(2, 4300),
        FlSpot(3, 4500)
      ],
    },
    {
      'name': 'Kampala Estate',
      'deposit': 7000,
      'netWorth': 8000,
      'performance': [
        FlSpot(0, 7000),
        FlSpot(1, 7200),
        FlSpot(2, 7500),
        FlSpot(3, 8000)
      ],
    },
    {
      'name': 'Lake View Apartments',
      'deposit': 5000,
      'netWorth': 5200,
      'performance': [
        FlSpot(0, 5000),
        FlSpot(1, 5100),
        FlSpot(2, 5150),
        FlSpot(3, 5200)
      ],
    },
  ];

  final List<Color> lineColors = [
    primaryColor,
    primaryTwo,
    primaryDark,
    primaryTwoLight
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Portfolio',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryTwo,
            fontSize: 25,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        // Wrap the Column with SingleChildScrollView
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Portfolio Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  color: primaryTwo,
                ),
              ),
            ),
            _buildScrollCards(),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Performance Overview',
                style: TextStyle(
                  fontSize: 18,
                  color: primaryTwo,
                ),
              ),
            ),

            _buildPerformanceGraph(),
            _buildLegend(),
            ActivitySummaryCard(
                portfolios: portfolios), // Use the new widget here
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Investment Distribution',
                style: TextStyle(
                  fontSize: 18,
                  color: primaryTwo,
                ),
              ),
            ),
            InvestmentDistribution(portfolios: portfolios)
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceGraph() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        height: 250,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            borderData: FlBorderData(
              show: true,
              border: const Border(
                bottom: BorderSide(color: Colors.grey, width: 1),
                left: BorderSide(color: Colors.grey, width: 1),
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '${value.toInt()}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: Text(
                        '\$${value.toInt()}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: portfolios.asMap().entries.map((entry) {
              final index = entry.key;
              final portfolio = entry.value;
              return LineChartBarData(
                spots: portfolio['performance'],
                isCurved: true,
                barWidth: 3,
                color: lineColors[index % lineColors.length],
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                    radius: 3,
                    color: lineColors[index % lineColors.length],
                    strokeWidth: 1.5,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: lineColors[index % lineColors.length].withOpacity(0.2),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Wrap(
        spacing: 16.0,
        runSpacing: 8.0,
        children: portfolios.asMap().entries.map((entry) {
          final index = entry.key;
          final portfolio = entry.value;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: lineColors[index % lineColors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                portfolio['name'],
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScrollCards() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: portfolios.length,
        itemBuilder: (context, index) {
          final portfolio = portfolios[index];
          return _buildCard(
            portfolio['name'],
            '${portfolio['deposit']}',
            '${portfolio['netWorth']}',
            primaryTwo,
          );
        },
      ),
    );
  }

  Widget _buildCard(
      String title, String deposit, String netWorth, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 16.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end, // Right-align all content
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Title of the portfolio
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),
            // Portfolio details (Deposit and Net Worth)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end, // Right-align text
              children: [
                Text(
                  'Deposit:',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.right,
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(
                        child: Transform.translate(
                          offset: const Offset(0, -6),
                          child: Text(
                            'UGX',
                            style: const TextStyle(
                              fontSize: 8,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      TextSpan(
                        text: deposit,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 10),
                Text(
                  'Net Worth:',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.right,
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(
                        child: Transform.translate(
                          offset: const Offset(0, -6),
                          child: Text(
                            'UGX',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      TextSpan(
                        text: netWorth,
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
