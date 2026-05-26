import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bottom sheet: fund performance (portal) + factsheet links + continue to invest.
Future<void> showFundOptionInsightSheet(
  BuildContext context, {
  required String fundName,
  required int investmentOptionId,
  required Map<String, dynamic> optionPayload,
  required void Function(Map<String, dynamic> opt) onContinueInvest,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _FundOptionInsightBody(
      fundName: fundName,
      investmentOptionId: investmentOptionId,
      optionPayload: optionPayload,
      onContinueInvest: onContinueInvest,
    ),
  );
}

class _FundOptionInsightBody extends StatefulWidget {
  final String fundName;
  final int investmentOptionId;
  final Map<String, dynamic> optionPayload;
  final void Function(Map<String, dynamic> opt) onContinueInvest;

  const _FundOptionInsightBody({
    required this.fundName,
    required this.investmentOptionId,
    required this.optionPayload,
    required this.onContinueInvest,
  });

  @override
  State<_FundOptionInsightBody> createState() => _FundOptionInsightBodyState();
}

class _FundOptionInsightBodyState extends State<_FundOptionInsightBody> {
  String _range = 'ALL';
  bool _loadingPerf = true;
  bool _loadingDocs = true;
  String? _perfError;
  String? _docsError;
  List<Map<String, dynamic>> _points = [];
  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loadingPerf = true;
      _loadingDocs = true;
      _perfError = null;
      _docsError = null;
    });
    try {
      final r = await ApiService.getFundOptionPublicPerformance(
        investmentOptionId: widget.investmentOptionId,
        range: _range,
      );
      if (!mounted) return;
      final pts = (r['points'] as List<dynamic>?) ?? [];
      setState(() {
        _points = List<Map<String, dynamic>>.from(pts);
        _loadingPerf = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _perfError = '$e';
          _loadingPerf = false;
        });
      }
    }
    try {
      final d = await ApiService.getFundOptionPublicDocuments(
        investmentOptionId: widget.investmentOptionId,
      );
      if (!mounted) return;
      final docs = (d['documents'] as List<dynamic>?) ?? [];
      setState(() {
        _documents = List<Map<String, dynamic>>.from(docs);
        _loadingDocs = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _docsError = '$e';
          _loadingDocs = false;
        });
      }
    }
  }

  Future<void> _setRange(String r) async {
    if (r == _range) return;
    setState(() => _range = r);
    setState(() {
      _loadingPerf = true;
      _perfError = null;
    });
    try {
      final res = await ApiService.getFundOptionPublicPerformance(
        investmentOptionId: widget.investmentOptionId,
        range: r,
      );
      if (!mounted) return;
      final pts = (res['points'] as List<dynamic>?) ?? [];
      setState(() {
        _points = List<Map<String, dynamic>>.from(pts);
        _loadingPerf = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _perfError = '$e';
          _loadingPerf = false;
        });
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final u = Uri.parse(url);
    if (await canLaunchUrl(u)) {
      await launchUrl(u, mode: LaunchMode.inAppWebView);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                widget.fundName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1a1d2e),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Performance & documents (from fund portal)',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Text(
                'Fund performance',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: primaryTwo,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _rangeChip('1M', '1M'),
                  _rangeChip('3M', '3M'),
                  _rangeChip('1Y', '1Y'),
                  _rangeChip('All', 'ALL'),
                ],
              ),
              const SizedBox(height: 12),
              if (_loadingPerf)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_perfError != null)
                Text(_perfError!, style: TextStyle(color: Colors.red.shade700))
              else if (_points.length < 2)
                Text(
                  'Not enough history to chart yet.',
                  style: TextStyle(color: Colors.grey.shade600),
                )
              else
                SizedBox(height: 200, child: _PerformanceChart(points: _points)),
              const SizedBox(height: 8),
              Text(
                'Past performance does not guarantee future results.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              Text(
                'Documents',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: primaryTwo,
                ),
              ),
              const SizedBox(height: 8),
              if (_loadingDocs)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_docsError != null)
                Text(_docsError!, style: TextStyle(color: Colors.red.shade700))
              else if (_documents.isEmpty)
                Text(
                  'No factsheets uploaded for this fund yet.',
                  style: TextStyle(color: Colors.grey.shade600),
                )
              else
                ..._documents.map((doc) {
                  final title = doc['original_name']?.toString() ??
                      doc['document_type']?.toString() ??
                      'Document';
                  final url = doc['url']?.toString() ?? '';
                  final type = doc['document_type']?.toString() ?? '';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.picture_as_pdf_outlined,
                          color: primaryTwo),
                      title: Text(title,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: type.isNotEmpty ? Text(type) : null,
                      trailing: const Icon(Icons.open_in_new, size: 20),
                      onTap: url.isNotEmpty ? () => _openUrl(url) : null,
                    ),
                  );
                }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onContinueInvest(widget.optionPayload);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTwo,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue to invest',
                    style: TextStyle(
                      color: white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _rangeChip(String label, String value) {
    final sel = _range == value;
    return FilterChip(
      label: Text(label),
      selected: sel,
      onSelected: (_) => _setRange(value),
      selectedColor: primaryTwo.withOpacity(0.2),
      checkmarkColor: primaryTwo,
      labelStyle: TextStyle(
        color: sel ? primaryTwo : Colors.grey.shade800,
        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

class _PerformanceChart extends StatelessWidget {
  final List<Map<String, dynamic>> points;

  const _PerformanceChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final values = points
        .map((p) => (p['value'] as num?)?.toDouble() ?? 0.0)
        .toList();
    double minY = values.reduce((a, b) => a < b ? a : b);
    double maxY = values.reduce((a, b) => a > b ? a : b);
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }
    final pad = (maxY - minY) * 0.08;
    minY -= pad;
    maxY += pad;

    final spots = <FlSpot>[];
    for (var i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i]));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: (spots.length / 4).ceilToDouble().clamp(1, 999),
              getTitlesWidget: (xv, meta) {
                final i = xv.round();
                if (i < 0 || i >= points.length) {
                  return const SizedBox.shrink();
                }
                final raw = points[i]['created']?.toString();
                final dt = raw != null ? DateTime.tryParse(raw) : null;
                final label = dt != null
                    ? DateFormat('MMM d').format(dt)
                    : '$i';
                return Text(
                  label,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, meta) {
                if (v.abs() >= 1e6) {
                  return Text('${(v / 1e6).toStringAsFixed(1)}M',
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade600));
                }
                if (v.abs() >= 1e3) {
                  return Text('${(v / 1e3).toStringAsFixed(1)}k',
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade600));
                }
                return Text(v.toStringAsFixed(0),
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade600));
              },
            ),
          ),
        ),
        minX: 0,
        maxX: (spots.length - 1).toDouble().clamp(0, double.infinity),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: spots.length > 2,
            barWidth: 2.5,
            color: primaryTwo,
            dotData: FlDotData(show: spots.length <= 12),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  primaryTwo.withOpacity(0.22),
                  primaryTwo.withOpacity(0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
