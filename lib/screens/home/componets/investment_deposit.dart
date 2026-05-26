import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/loader.dart';
import 'package:cyanase/helpers/deposit.dart';
import 'investment_class.dart';
import 'investment_option.dart';
import 'calculator_screen.dart';

enum InvestFlowStep {
  selectClass,
  selectFund,
  projections,
  payment,
}

class Deposit extends StatefulWidget {
  final int? initialInvestmentClassId;
  final int? initialInvestmentOptionId;

  const Deposit({
    Key? key,
    this.initialInvestmentClassId,
    this.initialInvestmentOptionId,
  }) : super(key: key);

  @override
  State<Deposit> createState() => _DepositState();
}

class _DepositState extends State<Deposit> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _investmentData = [];

  String _classSearchQuery = '';
  Map<String, dynamic>? _selectedClass;

  String _optionSearchQuery = '';
  Map<String, dynamic>? _selectedOption;

  InvestFlowStep _step = InvestFlowStep.selectClass;

  @override
  void initState() {
    super.initState();
    _fetchInvestmentData();
  }

  Future<void> _fetchInvestmentData() async {
    try {
      final db = await DatabaseHelper().database;
      final userProfile = await db.query('profile', limit: 1);
      final token =
          userProfile.isNotEmpty ? userProfile.first['token'] as String : '';

      final response = await ApiService.getClasses(token);
      final data = List<Map<String, dynamic>>.from(response);

      setState(() {
        _investmentData = data;
        _isLoading = false;
      });
      _applyInitialSelection();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load investment classes')),
        );
      }
    }
  }

  void _applyInitialSelection() {
    final cid = widget.initialInvestmentClassId;
    if (cid == null || _investmentData.isEmpty || !mounted) return;
    Map<String, dynamic>? match;
    for (final c in _investmentData) {
      final id = c['investment_class_id'];
      final parsed = id is int ? id : int.tryParse('$id');
      if (parsed == cid) {
        match = c;
        break;
      }
    }
    if (match == null) return;
    setState(() {
      _selectedClass = match;
      _step = InvestFlowStep.selectFund;
    });
  }

  int get _stepIndex {
    switch (_step) {
      case InvestFlowStep.selectClass:
        return 0;
      case InvestFlowStep.selectFund:
        return 1;
      case InvestFlowStep.projections:
        return 2;
      case InvestFlowStep.payment:
        return 3;
    }
  }

  String get _appBarTitle {
    switch (_step) {
      case InvestFlowStep.selectClass:
        return 'Make an investment';
      case InvestFlowStep.selectFund:
        return 'Choose a fund';
      case InvestFlowStep.projections:
        return 'Estimate returns';
      case InvestFlowStep.payment:
        return 'Complete payment';
    }
  }

  bool get _showAppBarBack {
    if (_step == InvestFlowStep.selectClass && _selectedClass == null) {
      return false;
    }
    return true;
  }

  void _handleBack() {
    switch (_step) {
      case InvestFlowStep.payment:
        setState(() => _step = InvestFlowStep.projections);
        break;
      case InvestFlowStep.projections:
        setState(() {
          _selectedOption = null;
          _step = InvestFlowStep.selectFund;
        });
        break;
      case InvestFlowStep.selectFund:
        setState(() {
          _selectedClass = null;
          _optionSearchQuery = '';
          _step = InvestFlowStep.selectClass;
        });
        break;
      case InvestFlowStep.selectClass:
        Navigator.of(context).pop();
        break;
    }
  }

  void _onOptionSelected(Map<String, dynamic> opt) {
    if (_selectedClass == null) return;
    setState(() {
      _selectedOption = opt;
      _step = InvestFlowStep.projections;
    });
  }

  Widget _buildFiveStepIndicator() {
    final s = _stepIndex;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _stepNode(label: 'Class', active: s >= 0, done: s > 0),
            _stepConnector(done: s >= 1),
            _stepNode(label: 'Fund', active: s >= 1, done: s > 1),
            _stepConnector(done: s >= 2),
            _stepNode(label: 'Est.', active: s >= 2, done: s > 2),
            _stepConnector(done: s >= 3),
            _stepNode(label: 'Deposit', active: s >= 3, done: false),
          ],
        ),
      ),
    );
  }

  Widget _stepNode(
      {required String label, required bool active, required bool done}) {
    final color = done || active ? primaryTwo : Colors.grey.shade400;
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: done ? primaryTwo : Colors.transparent,
              border: Border.all(color: color, width: 2),
              shape: BoxShape.circle,
            ),
            child: done
                ? const Center(
                    child: Icon(Icons.check, size: 14, color: white),
                  )
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? primaryTwo : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepConnector({required bool done}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        width: 14,
        height: 2,
        color: done ? primaryTwo : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildClassAndFundBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFiveStepIndicator(),
          Expanded(
            child: _step == InvestFlowStep.selectClass
                ? InvestmentClassStep(
                    investmentData: _investmentData,
                    searchQuery: _classSearchQuery,
                    onSearchChanged: (q) =>
                        setState(() => _classSearchQuery = q),
                    onClassSelected: (cls) => setState(() {
                      _selectedClass = cls;
                      _step = InvestFlowStep.selectFund;
                    }),
                  )
                : InvestmentOptionStep(
                    selectedClass: _selectedClass!,
                    searchQuery: _optionSearchQuery,
                    onSearchChanged: (q) =>
                        setState(() => _optionSearchQuery = q),
                    onOptionSelected: _onOptionSelected,
                    onBack: null,
                    preferredOptionId: widget.initialInvestmentOptionId,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectionsBody() {
    if (_selectedClass == null || _selectedOption == null) {
      return const Center(child: Text('No fund selected'));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildFiveStepIndicator(),
          ),
          Expanded(
            child: CalculatorScreen(
              selectedClass: _selectedClass!,
              selectedOption: _selectedOption!,
              onProceedToPayment: () =>
                  setState(() => _step = InvestFlowStep.payment),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildFiveStepIndicator(),
          ),
          Expanded(child: _buildWithDepositHelper()),
        ],
      ),
    );
  }

  Widget _buildWithDepositHelper() {
    final String? selectedFundClass =
        _selectedClass?['investment_class'] as String?;
    final String? selectedOptionName =
        _selectedOption?['investment_option'] as String?;
    final int? selectedOptionId = _selectedOption?['investment_option_id'] is int
        ? _selectedOption!['investment_option_id'] as int
        : int.tryParse(
            '${_selectedOption?['investment_option_id'] ?? ''}',
          );
    final String? selectedFundManager =
        _selectedOption?['handler'] as String?;
    if (selectedFundClass == null ||
        selectedOptionName == null ||
        selectedOptionId == null ||
        selectedFundManager == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.error, size: 50, color: Colors.red),
            SizedBox(height: 10),
            Text('Missing required data for deposit'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedOptionName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: primaryTwo,
                          ),
                        ),
                        Text(
                          'Class: $selectedFundClass',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildSummaryItem(
                    Icons.attach_money,
                    'Min Deposit:',
                    _selectedOption?['minimum_deposit']?.toString() ?? 'N/A',
                  ),
                  const SizedBox(width: 16),
                  _buildSummaryItem(
                    Icons.trending_up,
                    'Interest:',
                    '${_selectedOption?['interest']?.toString()}%',
                  ),
                  const SizedBox(width: 16),
                  _buildSummaryItem(
                    Icons.credit_card,
                    'Units:',
                    _selectedOption?['units']?.toString() ?? 'N/A',
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: DepositHelper(
              selectedFundClass: selectedFundClass,
              selectedOption: selectedOptionName,
              selectedOptionId: selectedOptionId,
              selectedFundManager: selectedFundManager,
              depositCategory: 'personal_invest',
              groupId: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: primaryTwo),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bodyForStep() {
    switch (_step) {
      case InvestFlowStep.selectClass:
      case InvestFlowStep.selectFund:
        return _buildClassAndFundBody();
      case InvestFlowStep.projections:
        return _buildProjectionsBody();
      case InvestFlowStep.payment:
        return _buildPaymentBody();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:
          _step == InvestFlowStep.selectClass && _selectedClass == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _appBarTitle,
            style: const TextStyle(color: white, fontSize: 20),
          ),
          backgroundColor: primaryTwo,
          foregroundColor: Colors.white,
          leading: _showAppBarBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _handleBack,
                )
              : null,
        ),
        body: _isLoading ? const Center(child: Loader()) : _bodyForStep(),
      ),
    );
  }
}
