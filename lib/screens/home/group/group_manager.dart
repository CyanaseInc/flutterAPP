import 'package:cyanase/helpers/loader.dart';
import 'package:flutter/material.dart';
import 'investment_tab.dart';
import 'loan_tab.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/get_currency.dart';

class GroupFinancePage extends StatefulWidget {
  final int groupId;

  const GroupFinancePage({Key? key, required this.groupId}) : super(key: key);

  @override
  _GroupFinancePageState createState() => _GroupFinancePageState();
}

class _GroupFinancePageState extends State<GroupFinancePage> {
  bool _isLoading = true;
  bool _isAdmin = false;
  bool _requirePaymentToJoin = false;
  bool isAdminMode = false;
  double _paymentAmount = 0.0;
  String _totalBalance = '';
  String _myContributions = '';
  String _currencySymbol = '';
  Map<String, dynamic> _groupStat = {};
  Map<String, dynamic> _loansData = {};
  Map<String, dynamic> _investmentsData = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGroupStat();
  }

  Future<void> _loadGroupStat() async {
    setState(() => _isLoading = true);
    await _fetchGroupStat();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchGroupStat() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);

      if (userProfile.isEmpty) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      final token = userProfile.first['token'] as String;
      final userCountry = userProfile.first['country'] as String;
      final currency = CurrencyHelper.getCurrencyCode(userCountry);

      final response = await ApiService.getGroupStat(
        token: token,
        groupId: widget.groupId,
      );

      if (response['success'] == true) {
        final data = response['data'] ?? {};
        final groupStats = data['group_stats'] ?? {};

        final contributions = groupStats['contributions'] ?? {};
        final loansData = data['loans_data'] ?? {};
        final investmentsData = data['investments_data'] ?? {};

        setState(() {
          _currencySymbol = currency;
          _groupStat = groupStats;
          _loansData = loansData;
          _investmentsData = investmentsData;
          _requirePaymentToJoin = groupStats['requirePaymentToJoin'] ?? false;
          isAdminMode = groupStats['restrict_messages_to_admins'] ?? false;
          _paymentAmount =
              (groupStats['pay_amount'] as num?)?.toDouble() ?? 0.0;
          _totalBalance =
              _formatCurrency(contributions['group_total']?.toDouble() ?? 0.0);
          _myContributions =
              _formatCurrency(contributions['my_total']?.toDouble() ?? 0.0);
          _isAdmin = groupStats['isAdmin'] ?? false;
        });
      } else {
        throw Exception(
            response['error'] ?? 'Failed to load group finance data');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load group finance data: $e';
        _totalBalance = _formatCurrency(0.0);
        _myContributions = _formatCurrency(0.0);
        _isAdmin = false;
      });
      if (mounted) {
        print(_error!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_error!),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadGroupStat,
            ),
          ),
        );
      }
    }
  }

  String _formatCurrency(double amount) {
    return '$_currencySymbol ${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Group Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: white,
            ),
          ),
          backgroundColor: primaryTwo,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: white), // White back icon
            onPressed: () => Navigator.of(context).pop(),
          ),
          iconTheme: IconThemeData(color: white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Investments'),
              Tab(text: 'Loans'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: Loader())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadGroupStat,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    children: [
                      InvestmentsTab(
                        groupId: widget.groupId,
                        investmentsData: _investmentsData,
                        isAdmin: _isAdmin,
                      ),
                      LoansTab(
                        groupId: widget.groupId,
                        loansData: _loansData,
                      ),
                    ],
                  ),
      ),
    );
  }
}
