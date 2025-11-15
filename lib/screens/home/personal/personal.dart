import 'dart:async';

import 'package:cyanase/helpers/loader.dart';
import 'package:cyanase/screens/home/personal/conversion.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import '../../../theme/theme.dart';

import './portifolio.dart';
import './card.dart';
import './deposit_withdraw_buttons.dart';
import './fund_manager.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/get_currency.dart';
import 'package:cyanase/helpers/subscription_helper.dart';

class PersonalTab extends StatefulWidget {
  final TabController tabController;

  const PersonalTab({Key? key, required this.tabController}) : super(key: key);

  @override
  State<PersonalTab> createState() => _PersonalTabState();
}

class _PersonalTabState extends State<PersonalTab>
    with TickerProviderStateMixin {
  // ──────────────────────────────────────────────────────────────
  // State
  // ──────────────────────────────────────────────────────────────
  double _totalDepositUGX = 0.0;
  double _totalDepositUSD = 0.0;
  double _totalNetworthy = 0.0;
  double _totalNetworthyUSD = 0.0;
  String currency = '';
  String Phonenumber = '';
  String subscriptionFee = '';
  bool processing = false;
  bool _isLoading = true;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _initTab();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────
  // Init
  // ──────────────────────────────────────────────────────────────
  Future<void> _initTab() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _checkAndShowSubscriptionModal(),
        _getNumber(),
        _getDepositNetworth(),
      ]).timeout(const Duration(seconds: 30), onTimeout: () {
        throw TimeoutException('Initialization timed out');
      });

      if (mounted) _fadeController.forward();
    } catch (e) {
      debugPrint('Initialization error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _getNumber() async {
    try {
      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isEmpty) {
        throw Exception('User profile not found');
      }
      final userPhone = userProfile.first['phone_number'] as String;

      setState(() {
        Phonenumber = userPhone;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load profile data')),
      );
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Subscription Modal
  // ──────────────────────────────────────────────────────────────
  Future<void> _checkAndShowSubscriptionModal() async {
    try {
      final db = await _dbHelper.database;
      final profile = await db.query('profile', limit: 1);
      if (profile.isEmpty) return;
      final token = profile.first['token'] as String;
      final resp = await ApiService.subscriptionStatus(token);
      if (resp['status'] == 'pending') {
        Future.microtask(() => _showSubscriptionReminder());
      }
    } catch (e) {
      debugPrint('Subscription check error: $e');
    }
  }

  void _showSubscriptionReminder() {
    final price = subscriptionPrices[currency]?.toStringAsFixed(2) ?? '20,500';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubscriptionReminder(
        price: price, 
        currency: currency,
        onSubscribe: () {
          Navigator.pop(context); // Close subscription reminder
          _showPhoneNumberInput(); // Show phone input
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Payment Flow
  // ──────────────────────────────────────────────────────────────

  void _showPhoneNumberInput() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Confirm Payment Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryTwo,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 24, color: primaryTwo),
                      const SizedBox(width: 12),
                      Text(
                        formatPhoneNumber(Phonenumber),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryTwo,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Payment will be processed using this number',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: processing ? null : () => _processPayment(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTwo,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: processing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(white),
                      ),
                    )
                  : const Text(
                      'Confirm Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: white,
                        decoration: TextDecoration.none,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(BuildContext ctx) async {
    setState(() => processing = true);
    Navigator.pop(ctx); // Close the phone input dialog
    
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => const _ProcessingDialog(),
    );

    try {
      final db = await _dbHelper.database;
      final profile = await db.query('profile', limit: 1);
      if (profile.isEmpty) throw Exception('Profile not found');

      final token = profile.first['token'] as String;
      final country = profile.first['country'] as String;
      final cur = CurrencyHelper.getCurrencyCode(country);
      final amount = subscriptionPrices[cur] ?? 20500.0;
      final ref = 'CYANASE-SUB-${DateTime.now().millisecondsSinceEpoch}';

      final payment = await ApiService.requestPayment(token, {
        "account_no": "REL6AEDF95B5A",
        "reference": ref,
        "internal_reference": ref,
        "amount": amount,
        "currency": cur,
        "reference_id": DateTime.now().millisecondsSinceEpoch.toString(),
        "msisdn": Phonenumber,
        "tx_ref": ref,
        "type": "cyanase_subscription",
        "description": "Annual Subscription Payment",
      });

      if (!payment['success']) throw Exception(payment['message'] ?? 'Payment failed');

      await Future.delayed(const Duration(seconds: 25));
      final auth = await ApiService.getTransaction(token, payment);

      if (mounted) Navigator.pop(ctx);
      if (mounted) _showResultDialog(ctx, auth['success'], auth['message'] ?? '');
    } catch (e) {
      if (mounted) Navigator.pop(ctx);
      if (mounted) _showResultDialog(ctx, false, e.toString());
    } finally {
      if (mounted) setState(() => processing = false);
    }
  }

  void _showResultDialog(BuildContext ctx, bool success, String msg) {
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(success: success, message: msg),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Net‑worth / Deposits - Updated with File A logic
  // ──────────────────────────────────────────────────────────────
  Future<void> _getDepositNetworth() async {
  if (!mounted) return; // Early return if widget is disposed
  
  try {
    final db = await _dbHelper.database;
    final profile = await db.query('profile', limit: 1);
    if (profile.isEmpty) return;

    final token = profile.first['token'] as String;
    final country = profile.first['country'] as String;
    final cur = CurrencyHelper.getCurrencyCode(country);

    final netResp = await ApiService.depositNetworth(token);
    
    
    if (netResp['success'] == true && netResp['data'] != null) {
      final data = netResp['data'];
      
      // Safe parsing with helper function
      double safeParse(dynamic value) {
        if (value == null) return 0.0;
        try {
          return double.parse(value.toString());
        } catch (e) {
          return 0.0;
        }
      }

      final totalDeposit = safeParse(data['total_deposits']);
      final totalNet = safeParse(data['net_worth']);
      final parsedDepositUSD = safeParse(data['depositUSD']);
      final parsedNetUSD = safeParse(data['NetUSD']);

      if (mounted) {
        setState(() {
          _totalDepositUGX = totalDeposit;
          _totalDepositUSD = parsedDepositUSD;
          _totalNetworthy = totalNet;
          _totalNetworthyUSD = parsedNetUSD;
          currency = cur;
        });
      }
    }
    
  } catch (e) {
    debugPrint('Networth fetch error: $e');
    // Optionally show error to user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load investment data')),
      );
    }
  }
}

  // ──────────────────────────────────────────────────────────────
  // UI - Added My Goals section from File A
  // ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Portfolio button
          Align(
            alignment: Alignment.topRight,
            child: OutlinedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Portfolio(currency: currency),
                        ),
                      ),
              icon: const Icon(Icons.pie_chart, size: 18),
              label: const Text('My Portfolio'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryTwo,
                side: const BorderSide(color: primaryTwo),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Deposit Card
          _isLoading
              ? _buildDepositCardSkeleton()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: TotalDepositsCard(
                    depositLocal: formatNumberWithCommas(_totalDepositUGX),
                    depositForeign: formatNumberWithCommas(_totalDepositUSD),
                    currency: currency,
                  ),
                ),
          const SizedBox(height: 12),

          // Buttons
          _isLoading
              ? _buildButtonsSkeleton()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: DepositWithdrawButtons(),
                ),
          const SizedBox(height: 12),

          // Net Worth Card
          _isLoading
              ? _buildNetworthCardSkeleton()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: NetworthCard(
                    networthLocal: formatNumberWithCommas(_totalNetworthy),
                    currency: currency,
                    networthForeign: formatNumberWithCommas(_totalNetworthyUSD),
                  ),
                ),
          const SizedBox(height: 24),

          // Investment options title
          _isLoading
              ? _buildTitleSkeleton()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    'Investment options',
                    style: TextStyle(
                      color: primaryTwo,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
          const SizedBox(height: 12),
          FundManagerSlider(),
          const SizedBox(height: 24),

        
          _isLoading
              ? _buildTitleSkeleton()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    'Recent transactions',
                    style: TextStyle(
                      color: primaryTwo,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
          const SizedBox(height: 12),

          // Transactions
          _isLoading
              ? _buildTransactionsSkeleton()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: TransactionsSection(),
                ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // SHIMMER SKELETONS
  // ──────────────────────────────────────────────────────────────
  Widget _shimmer({required Widget child}) => Shimmer(
        duration: const Duration(milliseconds: 1300),
        interval: const Duration(milliseconds: 0),
        color: Colors.grey,
        colorOpacity: 0.3,
        enabled: true,
        direction: const ShimmerDirection.fromLeftToRight(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: child,
        ),
      );

  // Deposit Card
  Widget _buildDepositCardSkeleton() => _shimmer(
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: primaryLight),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _skeletonLine(width: 110, height: 20),
              const SizedBox(height: 8),
              _skeletonLine(width: 160, height: 32),
              const SizedBox(height: 8),
              _skeletonLine(width: 130, height: 18),
            ],
          ),
        ),
      );

  // Net‑worth Card
  Widget _buildNetworthCardSkeleton() => _shimmer(
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: primaryLight),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _skeletonLine(width: 110, height: 20),
              const SizedBox(height: 8),
              _skeletonLine(width: 160, height: 32),
              const SizedBox(height: 8),
              _skeletonLine(width: 130, height: 18),
            ],
          ),
        ),
      );

  // Buttons
  Widget _buildButtonsSkeleton() => Row(
        children: [
          Expanded(child: _shimmer(child: _skeletonButton())),
          const SizedBox(width: 12),
          Expanded(child: _shimmer(child: _skeletonButton())),
        ],
      );

  // Goals Skeleton - Added from File A
  Widget _buildGoalsSkeleton() => _shimmer(
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: primaryLight),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _skeletonLine(width: 200, height: 20),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _skeletonCircle(),
                  _skeletonCircle(),
                  _skeletonCircle(),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _skeletonButton() => Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      );

  // Title
  Widget _buildTitleSkeleton() => _shimmer(
        child: Container(
          width: 180,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );

  // Transactions
  Widget _buildTransactionsSkeleton() => Column(
    children: List.generate(
      3,
      (_) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _shimmer(
          child: Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: Row(
              children: [
                _skeletonCircle(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _skeletonLine(width: 130, height: 16),
                      const SizedBox(height: 6),
                      _skeletonLine(width: 190, height: 14),
                    ],
                  ),
                ),
                _skeletonLine(width: 80, height: 16),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  // Helpers
  Widget _skeletonLine({required double width, required double height}) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      );

  Widget _skeletonCircle() => Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      );

  String formatNumberWithCommas(double number) =>
      NumberFormat('#,###').format(number);
}

// ──────────────────────────────────────────────────────────────
// TRANSACTIONS SECTION – PROFESSIONAL, MODERN, CAPITALIZED
// ──────────────────────────────────────────────────────────────
class TransactionsSection extends StatefulWidget {
  const TransactionsSection({Key? key}) : super(key: key);

  @override
  State<TransactionsSection> createState() => _TransactionsSectionState();
}

class _TransactionsSectionState extends State<TransactionsSection> {
  bool _loading = true;
  List<Map<String, dynamic>> _tx = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final db = await DatabaseHelper().database;
      final profile = await db.query('profile', limit: 1);
      if (profile.isEmpty) return;
      final token = profile.first['token'] as String;

      final resp = await ApiService.getAllTransactions(token);
      final list = resp is List
          ? resp
          : (resp['transactions'] ?? resp['data'] ?? []);

      list.sort((a, b) {
        final da = DateTime.tryParse(a['created'] ?? '') ?? DateTime.now();
        final db = DateTime.tryParse(b['created'] ?? '') ?? DateTime.now();
        return db.compareTo(da);
      });

      setState(() => _tx = List<Map<String, dynamic>>.from(list));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // ────── UI Helpers ──────
  Color _statusColor(String s) => switch (s.toLowerCase()) {
        'success' => const Color(0xFF4CAF50),
        'failed' => const Color(0xFFF44336),
        'pending' => const Color(0xFFFFB300),
        _ => Colors.grey,
      };

  IconData _typeIcon(String t) => switch (t.toLowerCase()) {
        'deposit' || 'contribution' => Icons.account_balance_wallet_outlined,
        'withdrawal' || 'payout' => Icons.arrow_downward,
        'investment' => Icons.trending_up,
        'transfer' => Icons.swap_horiz,
        _ => Icons.sync_alt,
      };

  String _capitalizedType(String raw) {
    final cleaned = raw.replaceAll('_', ' ').trim();
    if (cleaned.isEmpty) return 'Unknown';
    return cleaned
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Loader()),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: _fetch,
            ),
          ],
        ),
      );
    }

    if (_tx.isEmpty) {
      return const Center(
        child: Text('No transactions yet', style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetch,
      color: primaryTwo,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _tx.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final t = _tx[i];
          final amount = (t['amount'] ?? 0.0).toDouble();
          final cur = t['currency']?.toString().toUpperCase() ?? 'UGX';
          final rawType = (t['transaction_type'] ?? '').toString();
          final type = _capitalizedType(rawType);
          final status = (t['status'] ?? '').toString().toLowerCase();
          final date = DateTime.tryParse(t['created'] ?? '') ?? DateTime.now();

          final showHeader = i == 0 ||
              DateFormat('MMM d, yyyy').format(date) !=
                  DateFormat('MMM d, yyyy').format(
                      DateTime.tryParse(_tx[i - 1]['created'] ?? '') ??
                          DateTime.now());

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHeader)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 8, top: 8),
                  child: Text(
                    DateFormat('MMM d, yyyy').format(date),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE5E5E5), width: 1),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: _statusColor(status).withOpacity(0.12),
                    child: Icon(
                      _typeIcon(rawType),
                      color: _statusColor(status),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    type,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${DateFormat('HH:mm').format(date)} • $cur ${NumberFormat('#,###').format(amount.abs())}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  trailing: Text(
                    '${amount >= 0 ? '+' : '-'}${NumberFormat('#,###').format(amount.abs())}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: amount >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Bottom sheets / dialogs - Fixed callback implementation
// ──────────────────────────────────────────────────────────────
class _SubscriptionReminder extends StatelessWidget {
  final String price;
  final String currency;
  final VoidCallback onSubscribe;
  
  const _SubscriptionReminder({
    required this.price, 
    required this.currency,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_border, size: 48, color: primaryTwo),
          const SizedBox(height: 16),
          const Text('Subscribe',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryTwo)),
          const SizedBox(height: 12),
          Text(
            'All cyanase users are required to pay $currency $price/year in subscription fees. Save smarter, achieve your goals!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onSubscribe, // Directly use the callback
            style: ElevatedButton.styleFrom(
                backgroundColor: primaryTwo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Subscribe Now',
                style: TextStyle(color: white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

class _ProcessingDialog extends StatelessWidget {
  const _ProcessingDialog();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Loader(),
              SizedBox(height: 16),
              Text('Processing Payment ...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primaryTwo)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultDialog extends StatelessWidget {
  final bool success;
  final String message;
  const _ResultDialog({required this.success, required this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(success ? Icons.check_circle : Icons.error_outline,
                size: 48, color: success ? Colors.green : Colors.red),
            const SizedBox(height: 16),
            Text(success ? 'Payment Successful!' : 'Payment Failed',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTwo)),
            const SizedBox(height: 12),
            Text(success ? 'Your subscription is now active. Enjoy all premium features!' : message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (success) {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTwo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(success ? 'Continue' : 'Try Again',
                  style: const TextStyle(color: white)),
            ),
            if (!success) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String formatPhoneNumber(String p) {
  if (p.length < 10) return p;
  return '${p.substring(0, 3)} ${p.substring(3, 6)} ${p.substring(6)}';
}