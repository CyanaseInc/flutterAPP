import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/loader.dart';
import '../../theme/theme.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
  String? _error;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isEmpty) throw Exception('User not found');
      final token = userProfile.first['token'] as String;

      final response = await ApiService.getAllTransactions(token);

      List txs = response is List
          ? response
          : (response['transactions'] ?? response['data'] ?? []);
      setState(() {
        _transactions = List<Map<String, dynamic>>.from(txs);
        _animationController.forward(from: 0);
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'exchange to usd':
        return Icons.flag;
      case 'add by mobile':
        return Icons.phone;
      case 'add to card':
        return Icons.credit_card;
      default:
        return Icons.account_balance;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,##0', 'en_US');

    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: white,
        iconTheme: const IconThemeData(color: primaryTwo),
        titleTextStyle: const TextStyle(
          color: primaryTwo,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
        elevation: 1,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(
                painter: DiagonalLinePainter(),
              ),
            ),
          ),
          _isLoading
              ? const Center(child: Loader())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded, color: const Color(0xFFE74C3C), size: 64),
                          const SizedBox(height: 16),
                          Text(_error!, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchTransactions,
                            style: ElevatedButton.styleFrom(backgroundColor: primaryTwo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                            child: const Text('Retry', style: TextStyle(color: white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ],
                      ),
                    )
                  : _transactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.credit_card_rounded, size: 100, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('No Transactions Yet!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryTwo)),
                              const SizedBox(height: 8),
                              Text(
                                'Start a transaction to see your history here.',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                textAlign: TextAlign.center, // Moved textAlign here
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(backgroundColor: primaryTwo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                                child: const Text('Start Now', style: TextStyle(color: white, fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchTransactions,
                          color: primaryTwo,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _transactions.length,
                            itemBuilder: (context, index) {
                              final tx = _transactions[index];
                              final amount = tx['amount']?.toDouble() ?? 0.0;
                              final currency = tx['currency'] ?? 'UGX';
                              final type = (tx['transaction_type']?.toString() ?? '').toLowerCase().replaceAll('_', ' ');
                              final date = tx['created'] != null ? DateTime.parse(tx['created']) : DateTime.now();
                              final time = DateFormat('HH:mm').format(date);

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (index == 0 || DateFormat('MMMM d, yyyy').format(DateTime.parse(_transactions[index]['created'])) != DateFormat('MMMM d, yyyy').format(DateTime.parse(_transactions[index - 1]['created'])))
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        DateFormat('MMMM d, yyyy').format(date),
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600]),
                                      ),
                                    ),
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: white,
                                      border: Border.all(color: primaryTwo, width: 1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: amount < 0 ? Colors.red[100] : Colors.green[100],
                                        child: Icon(_typeIcon(type), color: amount < 0 ? Colors.red : Colors.green),
                                      ),
                                      title: Text(type),
                                      subtitle: Text(time),
                                      trailing: Text(
                                        "${amount >= 0 ? '+' : ''}$currency ${numberFormat.format(amount.abs())}",
                                        style: TextStyle(
                                          color: amount < 0 ? Colors.red : Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
        ],
      ),
    );
  }
}

class DiagonalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryTwo.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const spacing = 40.0;
    for (double i = -size.height; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}