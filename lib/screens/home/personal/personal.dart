import 'dart:async';

import 'package:cyanase/helpers/loader.dart';

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
import 'package:cyanase/helpers/xcel_payment_helper.dart';
import 'package:cyanase/helpers/subscription_helper.dart';
import 'package:cyanase/screens/home/transactions_screen.dart';

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
  SubscriptionQuote? _subscriptionQuote;
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
      final quote = parseSubscriptionQuote(resp);
      if (mounted) {
        setState(() {
          _subscriptionQuote = quote;
          if (quote.currency.isNotEmpty) currency = quote.currency;
          subscriptionFee = formatSubscriptionPrice(quote.amount);
        });
      }
      if (resp['status'] == 'pending') {
        Future.microtask(() => _showSubscriptionReminder());
      }
    } catch (e) {
      debugPrint('Subscription check error: $e');
    }
  }

  void _showSubscriptionReminder() {
    final quote = _subscriptionQuote;
    final displayCurrency = quote?.currency ?? currency;
    final price = quote != null
        ? formatSubscriptionPrice(quote.amount)
        : subscriptionFee.isNotEmpty
            ? subscriptionFee
            : formatSubscriptionPrice(subscriptionPricesFallback['UGX']!);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubscriptionReminder(
        price: price,
        currency: displayCurrency,
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
      builder: (sheetContext) {
        var paying = false;
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
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
                  onPressed: paying
                      ? null
                      : () => _processPayment(
                            sheetContext,
                            () => setSheetState(() => paying = true),
                            () => setSheetState(() => paying = false),
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTwo,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: paying
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
                  onPressed: paying ? null : () => Navigator.pop(sheetContext),
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
            );
          },
        );
      },
    );
  }

  Future<void> _processPayment(
    BuildContext sheetContext,
    VoidCallback onPayStart,
    VoidCallback onPayEnd,
  ) async {
    if (!mounted) return;
    final hostContext = context;

    onPayStart();

    try {
      final db = await _dbHelper.database;
      final profile = await db.query('profile', limit: 1);
      if (profile.isEmpty) throw Exception('Profile not found');

      final token = profile.first['token'] as String;
      var quote = _subscriptionQuote;
      if (quote == null) {
        final statusResp = await ApiService.subscriptionStatus(token);
        quote = parseSubscriptionQuote(statusResp);
      }
      final reference = 'CYSUB${DateTime.now().millisecondsSinceEpoch}';

      final paymentPayload = {
        "reference": reference,
        "amount": quote.amount,
        "currency": quote.currency,
        // Use locally-stored profile phone number; backend can also fill it if missing.
        "msisdn": Phonenumber,
        "type": "cyanase_subscription",
        "description": "Annual Subscription Payment",
      };

      final payment = await ApiService.requestPayment(token, paymentPayload);

      if (!payment['success']) {
        final msg = payment['message']?.toString().trim();
        throw Exception(
          msg != null && msg.isNotEmpty ? msg : 'Payment request failed',
        );
      }

      final auth = await finalizeMobileMoneyPayment(
        context: sheetContext,
        token: token,
        requestPayment: payment,
      );

      if (!mounted) return;
      Navigator.pop(sheetContext);

      final success = auth['success'] == true;
      final message = auth['message']?.toString() ??
          (success ? 'Subscription payment successful' : 'Payment not completed');

      ScaffoldMessenger.of(hostContext).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Your subscription is now active.'
                : message,
          ),
          duration: Duration(seconds: success ? 4 : 6),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(hostContext).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      onPayEnd();
    }
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
  Widget _sectionHeader(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: primaryTwo,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionHeaderWithAction(
    String title, {
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Row(
      children: [
        Expanded(child: _sectionHeader(title)),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: primaryTwo,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            actionLabel,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _isLoading
              ? _buildDepositCardSkeleton()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: PortfolioHeroCard(
                    currency: currency,
                    networthLocal:
                        formatNumberWithCommas(_totalNetworthy),
                    networthForeign:
                        formatNumberWithCommas(_totalNetworthyUSD),
                    depositLocal:
                        formatNumberWithCommas(_totalDepositUGX),
                    depositForeign:
                        formatNumberWithCommas(_totalDepositUSD),
                    onPortfolioTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Portfolio(currency: currency),
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 14),

          _isLoading
              ? _buildButtonsSkeleton()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: const DepositWithdrawButtons(),
                ),
          const SizedBox(height: 14),

          _isLoading
              ? _buildNetworthCardSkeleton()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: NetworthInsightCard(
                    currency: currency,
                    networthLocal:
                        formatNumberWithCommas(_totalNetworthy),
                    networthForeign:
                        formatNumberWithCommas(_totalNetworthyUSD),
                    growthPercent: _growthPercent(),
                  ),
                ),
          const SizedBox(height: 28),

          _isLoading
              ? _buildTitleSkeleton()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: _sectionHeader(
                    'Investment options',
                    subtitle: 'Funds curated for your goals',
                  ),
                ),
          const SizedBox(height: 14),
          FundManagerSlider(),
          const SizedBox(height: 28),

          _isLoading
              ? _buildTitleSkeleton()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: _sectionHeaderWithAction(
                    'Recent activity',
                    actionLabel: 'View all',
                    onAction: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const TransactionsScreen(),
                        ),
                      );
                    },
                  ),
                ),
          const SizedBox(height: 10),

          _isLoading
              ? _buildTransactionsSkeleton()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: TransactionsSection(),
                ),
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
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: primaryLight),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _skeletonLine(width: 110, height: 16),
              const SizedBox(height: 12),
              _skeletonLine(width: 160, height: 28),
            ],
          ),
        ),
      );

  // Networth insight card (matches [NetworthInsightCard] row layout — avoids overflow)
  Widget _buildNetworthCardSkeleton() => _shimmer(
        child: Container(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primaryLight),
          ),
          child: Row(
            children: [
              _skeletonCircle(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _skeletonLine(width: 120, height: 12),
                    const SizedBox(height: 8),
                    _skeletonLine(width: 140, height: 18),
                  ],
                ),
              ),
              _skeletonLine(width: 52, height: 22),
            ],
          ),
        ),
      );

  // Buttons
  Widget _buildButtonsSkeleton() => SizedBox(
        height: DepositWithdrawButtons.buttonHeight,
        child: Row(
          children: [
            Expanded(
              child: _shimmer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _shimmer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
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
        height: 48,
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
  Widget _buildTransactionsSkeleton() => _shimmer(
        child: Container(
          height: 168,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E5E5)),
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

  double _growthPercent() {
    if (_totalDepositUGX <= 0) return 0;
    return (_totalNetworthy / _totalDepositUGX) * 100;
  }
}

// ──────────────────────────────────────────────────────────────
// TRANSACTIONS SECTION – PROFESSIONAL, MODERN, CAPITALIZED
// ──────────────────────────────────────────────────────────────
class TransactionsSection extends StatefulWidget {
  /// Home preview only — keep small; full list on [TransactionsScreen].
  final int maxItems;

  TransactionsSection({super.key, this.maxItems = 3});

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

  void _openAllTransactions(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const TransactionsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Loader()),
      );
    }

    if (_error != null) {
      return _previewCard(
        child: Column(
          children: [
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            TextButton(onPressed: _fetch, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_tx.isEmpty) {
      return _previewCard(
        child: Text(
          'No activity yet',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
      );
    }

    final preview = _tx.take(widget.maxItems).toList();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openAllTransactions(context),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: surfaceMutedBorder.withOpacity(0.6)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < preview.length; i++) ...[
                if (i > 0) Divider(height: 1, color: Colors.grey.shade200),
                _previewRow(preview[i]),
              ],
              Divider(height: 1, color: Colors.grey.shade200),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'See all transactions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryTwo,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 20, color: primaryTwo),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: surfaceMutedBorder.withOpacity(0.6)),
      ),
      child: Center(child: child),
    );
  }

  Widget _previewRow(Map<String, dynamic> t) {
    final amount = (t['amount'] ?? 0.0).toDouble();
    final cur = t['currency']?.toString().toUpperCase() ?? 'UGX';
    final rawType = (t['transaction_type'] ?? '').toString();
    final type = _capitalizedType(rawType);
    final status = (t['status'] ?? '').toString().toLowerCase();
    final date = DateTime.tryParse(t['created'] ?? '') ?? DateTime.now();
    final isCredit = amount >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _statusColor(status).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon(rawType), color: _statusColor(status), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: primaryTwo,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM d · HH:mm').format(date),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'} $cur ${NumberFormat('#,###').format(amount.abs())}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isCredit ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
            ),
          ),
        ],
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


String formatPhoneNumber(String p) {
  if (p.length < 10) return p;
  return '${p.substring(0, 3)} ${p.substring(3, 6)} ${p.substring(6)}';
}