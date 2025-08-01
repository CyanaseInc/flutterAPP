import 'package:cyanase/helpers/loader.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/theme.dart';
import 'summary.dart';
import 'investment_distribution.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:intl/intl.dart';

class Portfolio extends StatefulWidget {
  final String? currency;
  const Portfolio({
    super.key,
    this.currency,
  });

  @override
  _PortfolioState createState() => _PortfolioState();
}

class _PortfolioState extends State<Portfolio> {
  List<Map<String, dynamic>> portfolios = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPortfolioData();
  }

  Future<void> _fetchPortfolioData() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);

      if (userProfile.isNotEmpty) {
        final token = userProfile.first['token'] as String;
        final response = await ApiService.depositNetworth(token);
        final data = response['data'] ?? {};
  print('Portfolio data: $data');
        final investmentPerformance =
            data['investment_performance'] as List? ?? [];
        final historyData = data['history'] as List? ?? [];

        final referenceDate = DateTime(2000, 1, 1);

        setState(() {
          portfolios = investmentPerformance.map((item) {
            final investmentId = item['investment_option_id'] as int?;
            final history = historyData.firstWhere(
              (historyItem) =>
                  historyItem['investment_option_id'] == investmentId,
              orElse: () => {'history': []},
            )['history'] as List;

            final performance = history.map((historyEntry) {
              final date = DateTime.parse(historyEntry['date']);
              final closingBalance = historyEntry['closing_balance'] as double;

              final xValue = ((date.year - referenceDate.year) * 12) +
                  (date.month - referenceDate.month);
              final yValue = closingBalance;

              return FlSpot(xValue.toDouble(), yValue);
            }).toList();

            return {
              'name': item['name'] ?? 'Unknown',
              'deposit': (item['deposits'] as num?)?.toDouble() ?? 0.0,
              'netWorth': (item['networth'] as num?)?.toDouble() ?? 0.0,
              'performance': performance,
            };
          }).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  final List<Color> gradientColors = [
    primaryColor,
    primaryTwo,
    primaryDark,
    primaryTwoLight
  ];

  final NumberFormat numberFormat = NumberFormat('#,###', 'en_US');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          isLoading
              ? const SliverToBoxAdapter(
                  child: Center(child: Loader()),
                )
              : SliverToBoxAdapter(child: _buildPortfolioCarousel(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
          isLoading
              ? const SliverToBoxAdapter(child: SizedBox.shrink())
              : SliverToBoxAdapter(child: _buildPerformanceSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
          isLoading
              ? const SliverToBoxAdapter(child: SizedBox.shrink())
              : SliverToBoxAdapter(
                  child: ActivitySummaryCard(portfolios: portfolios)),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
          isLoading
              ? const SliverToBoxAdapter(child: SizedBox.shrink())
              : SliverToBoxAdapter(
                  child: InvestmentDistribution(portfolios: portfolios)),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 60,
      floating: false,
      pinned: true,
      backgroundColor: white,
      elevation: 0,
      title: const Text(
        'My Portfolio',
        style: TextStyle(
            fontWeight: FontWeight.bold, color: primaryTwo, fontSize: 18),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey[300], height: 1),
      ),
    );
  }

  Widget _buildPortfolioCarousel(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth * 0.9;
        return Container(
          height: 150,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.9),
            itemCount: portfolios.length,
            itemBuilder: (context, index) {
              final portfolio = portfolios[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildPortfolioCard(portfolio, index, maxWidth),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPortfolioCard(
      Map<String, dynamic> portfolio, int index, double maxWidth) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: maxWidth,
        decoration: BoxDecoration(
          color: gradientColors[index % gradientColors.length],
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              portfolio['name'],
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: white),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                    child: _buildValueWidget('Deposit', portfolio['deposit'])),
                const SizedBox(width: 16),
                Flexible(
                    child:
                        _buildValueWidget('Net Worth', portfolio['netWorth'])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueWidget(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: white.withOpacity(0.8), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                  text: '${widget.currency ?? "UGX"} ',
                  style: const TextStyle(color: white, fontSize: 12)),
              TextSpan(
                text: numberFormat.format(value),
                style: const TextStyle(
                    color: white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceSection() {
    if (portfolios.isEmpty) {
      return const Center(
        child: Text(
          'No portfolio data available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final portfolio in portfolios) {
      final List<FlSpot> performance = portfolio['performance'];
      if (performance.isEmpty) continue;
      for (final spot in performance) {
        if (spot.x < minX) minX = spot.x;
        if (spot.x > maxX) maxX = spot.x;
        if (spot.y < minY) minY = spot.y;
        if (spot.y > maxY) maxY = spot.y;
      }
    }

    final hasData = minX != double.infinity &&
        maxX != double.negativeInfinity &&
        minY != double.infinity &&
        maxY != double.negativeInfinity;

    if (!hasData) {
      return const Center(
        child: Text(
          'No performance data available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Handle cases where all values are the same
    if (minX == maxX) {
      minX -= 1;
      maxX += 1;
    }
    if (minY == maxY) {
      minY -= (maxY.abs() * 0.1).clamp(1000.0, double.infinity);
      maxY += (maxY.abs() * 0.1).clamp(1000.0, double.infinity);
    }

    final xRange = maxX - minX;
    final yRange = maxY - minY;

    // Add padding to ranges
    final xPadding = xRange * 0.1;
    final yPadding = yRange * 0.2;
    minX -= xPadding;
    maxX += xPadding;
    minY -= yPadding;
    maxY += yPadding;

    // Ensure minY is non-negative for investment data
    if (minY < 0) minY = 0;

    // Calculate intervals with safeguards
    double xInterval = (maxX - minX) / 5;
    double yInterval = yRange / 5;

    // Ensure minimum intervals
    xInterval = xInterval > 0 ? xInterval : 1.0;
    yInterval = yInterval > 0 ? yInterval : (maxY > 0 ? maxY / 10 : 1.0);

    // For very small ranges, use smaller intervals
    if (yRange < 10) {
      yInterval = yRange / 10;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Overview',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: primaryTwo),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(
                    show: true, border: Border.all(color: Colors.grey)),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      interval: xInterval,
                      getTitlesWidget: (value, meta) {
                        if (value < minX || value > maxX)
                          return const SizedBox.shrink();
                        final referenceDate = DateTime(2000, 1, 1);
                        final date = DateTime(
                          referenceDate.year + (value ~/ 12),
                          referenceDate.month + (value % 12).toInt(),
                        );
                        return Text(
                          DateFormat('MMMyy').format(date),
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: yInterval,
                      getTitlesWidget: (value, meta) {
                        if (value < minY || value > maxY)
                          return const SizedBox.shrink();
                        if (value.abs() >= 1000000) {
                          return Text(
                            '${(value / 1000000).toStringAsFixed(1)}M',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey),
                          );
                        } else if (value.abs() >= 1000) {
                          return Text(
                            '${(value / 1000).toStringAsFixed(1)}k',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey),
                          );
                        }
                        return Text(
                          value.toStringAsFixed(0),
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: portfolios.asMap().entries.map((entry) {
                  final index = entry.key;
                  final spots = entry.value['performance'] as List<FlSpot>;
                  if (spots.length < 2) {
                    return LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      barWidth: 3,
                      color: gradientColors[index % gradientColors.length],
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    );
                  }
                  return LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    barWidth: 3,
                    color: gradientColors[index % gradientColors.length],
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          gradientColors[index % gradientColors.length]
                              .withOpacity(0.3),
                          gradientColors[index % gradientColors.length]
                              .withOpacity(0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  );
                }).toList(),
                minX: minX,
                maxX: maxX,
                minY: minY,
                maxY: maxY,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            children: portfolios.asMap().entries.map((entry) {
              final index = entry.key;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: gradientColors[index % gradientColors.length],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.value['name'],
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}