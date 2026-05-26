import 'package:country_picker/country_picker.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/get_currency.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:flutter/material.dart';

/// Edit an IPS row returned from [ApiService.getIpsDocuments].
class IpsDocumentEditScreen extends StatefulWidget {
  final Map<String, dynamic> document;

  const IpsDocumentEditScreen({super.key, required this.document});

  @override
  State<IpsDocumentEditScreen> createState() => _IpsDocumentEditScreenState();
}

class _IpsDocumentEditScreenState extends State<IpsDocumentEditScreen> {
  static const _riskKeys = [
    'conservative',
    'moderate',
    'moderate_aggressive',
    'aggressive',
  ];
  static const _horizonKeys = ['short', 'medium', 'long'];
  static const _liquidityKeys = ['low', 'medium', 'high'];
  static const _currencies = ['USD', 'EUR', 'GBP', 'UGX', 'KES', 'ZAR'];
  static const _reviewFreq = [
    'Monthly',
    'Quarterly',
    'Semi-Annually',
    'Annually',
  ];

  late final String _documentId;
  final _documentIdDisplayCtrl = TextEditingController();
  int? _groupId;

  final _nameCtrl = TextEditingController();
  final _clientNameCtrl = TextEditingController();
  final _advisorCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _monthlySavingsCtrl = TextEditingController();
  final _investmentGoalsCtrl = TextEditingController();
  final _educationGoalsCtrl = TextEditingController();
  final _retirementGoalsCtrl = TextEditingController();
  final _emergencyFundCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  final _legalCtrl = TextEditingController();
  final _ethicalCtrl = TextEditingController();
  final _prohibitedCtrl = TextEditingController();
  final _specialCtrl = TextEditingController();

  String _residence = '';
  String _incomeCurrency = 'UGX';
  String _risk = 'moderate';
  String _timeHorizon = 'medium';
  String _liquidity = 'medium';
  String _reviewFrequency = 'Annually';

  double _equities = 50;
  double _bonds = 30;
  double _realAssets = 10;
  double _alternatives = 5;
  double _cash = 5;

  bool _saving = false;

  double get _allocTotal =>
      _equities + _bonds + _realAssets + _alternatives + _cash;

  double _toDouble(dynamic v, double fallback) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  @override
  void initState() {
    super.initState();
    final d = widget.document;
    _documentId = (d['document_id'] ?? '').toString();
    _documentIdDisplayCtrl.text = _documentId;
    final g = d['group'];
    if (g is int) {
      _groupId = g;
    } else if (g != null) {
      _groupId = int.tryParse('$g');
    }

    _nameCtrl.text = (d['name'] ?? '').toString();
    _clientNameCtrl.text = (d['client_name'] ?? '').toString();
    _advisorCtrl.text = (d['advisor_name'] ?? '').toString();
    final age = d['client_age'];
    _ageCtrl.text = age != null ? '$age' : '';
    _residence = (d['residence'] ?? '').toString();
    final cur = (d['income_currency'] ?? '').toString();
    if (cur.isNotEmpty && _currencies.contains(cur)) {
      _incomeCurrency = cur;
    }
    _monthlySavingsCtrl.text = (d['monthly_savings'] ?? '').toString();
    _investmentGoalsCtrl.text = (d['investment_goals'] ?? '').toString();
    _educationGoalsCtrl.text = (d['education_goals'] ?? '').toString();
    _retirementGoalsCtrl.text = (d['retirement_goals'] ?? '').toString();
    _emergencyFundCtrl.text = (d['emergency_fund'] ?? '').toString();

    final rt = (d['risk_tolerance'] ?? 'moderate').toString();
    _risk = _riskKeys.contains(rt) ? rt : 'moderate';
    final th = (d['time_horizon'] ?? 'medium').toString();
    _timeHorizon = _horizonKeys.contains(th) ? th : 'medium';
    final liq = (d['liquidity_needs'] ?? 'medium').toString();
    _liquidity = _liquidityKeys.contains(liq) ? liq : 'medium';

    final rf = (d['review_frequency'] ?? 'Annually').toString();
    _reviewFrequency = _reviewFreq.contains(rf) ? rf : 'Annually';

    _equities = _toDouble(d['global_equities'], 50);
    _bonds = _toDouble(d['global_bonds'], 30);
    _realAssets = _toDouble(d['real_assets'], 10);
    _alternatives = _toDouble(d['alternatives'], 5);
    _cash = _toDouble(d['cash_mmf'], 5);

    _taxCtrl.text = (d['tax_considerations'] ?? '').toString();
    _legalCtrl.text = (d['legal_regulatory'] ?? '').toString();
    _ethicalCtrl.text = (d['ethical_preferences'] ?? '').toString();
    _prohibitedCtrl.text = (d['prohibited_investments'] ?? '').toString();
    _specialCtrl.text = (d['special_circumstances'] ?? '').toString();
  }

  @override
  void dispose() {
    _documentIdDisplayCtrl.dispose();
    _nameCtrl.dispose();
    _clientNameCtrl.dispose();
    _advisorCtrl.dispose();
    _ageCtrl.dispose();
    _monthlySavingsCtrl.dispose();
    _investmentGoalsCtrl.dispose();
    _educationGoalsCtrl.dispose();
    _retirementGoalsCtrl.dispose();
    _emergencyFundCtrl.dispose();
    _taxCtrl.dispose();
    _legalCtrl.dispose();
    _ethicalCtrl.dispose();
    _prohibitedCtrl.dispose();
    _specialCtrl.dispose();
    super.dispose();
  }

  void _pickResidence() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country c) {
        String currency = 'UGX';
        try {
          currency = CurrencyHelper.getCurrencyCode(c.countryCode);
        } catch (_) {
          currency = 'UGX';
        }
        setState(() {
          _residence = c.name;
          if (_currencies.contains(currency)) {
            _incomeCurrency = currency;
          }
        });
      },
    );
  }

  InputDecoration _dec(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<void> _save() async {
    if (_documentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing document id')),
      );
      return;
    }
    if (_clientNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client name is required')),
      );
      return;
    }
    if ((_allocTotal - 100).abs() > 0.51) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Allocation must total 100% (now ${_allocTotal.toStringAsFixed(0)}%)',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final db = await DatabaseHelper().database;
      final rows = await db.query('profile', limit: 1);
      if (rows.isEmpty) throw Exception('Not signed in');
      final token = (rows.first['token'] as String?)?.trim() ?? '';
      if (token.isEmpty) throw Exception('Not signed in');

      final age = int.tryParse(_ageCtrl.text.trim());
      final body = <String, dynamic>{
        'document_id': _documentId,
        'name': _nameCtrl.text.trim(),
        'client_name': _clientNameCtrl.text.trim(),
        'advisor_name': _advisorCtrl.text.trim(),
        if (age != null && age >= 18 && age <= 100) 'client_age': age,
        'residence': _residence.trim(),
        'income_currency': _incomeCurrency,
        'monthly_savings': _monthlySavingsCtrl.text.trim(),
        'investment_goals': _investmentGoalsCtrl.text.trim(),
        'education_goals': _educationGoalsCtrl.text.trim(),
        'retirement_goals': _retirementGoalsCtrl.text.trim(),
        'emergency_fund': _emergencyFundCtrl.text.trim(),
        'risk_tolerance': _risk,
        'time_horizon': _timeHorizon,
        'liquidity_needs': _liquidity,
        'global_equities': _equities,
        'global_bonds': _bonds,
        'real_assets': _realAssets,
        'alternatives': _alternatives,
        'cash_mmf': _cash,
        'review_frequency': _reviewFrequency,
        'tax_considerations': _taxCtrl.text.trim(),
        'legal_regulatory': _legalCtrl.text.trim(),
        'ethical_preferences': _ethicalCtrl.text.trim(),
        'prohibited_investments': _prohibitedCtrl.text.trim(),
        'special_circumstances': _specialCtrl.text.trim(),
      };
      if (_groupId != null) body['group_id'] = _groupId;

      final result = await ApiService.updateIpsDocument(token, body);
      if (!mounted) return;
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('IPS updated')),
        );
        Navigator.of(context).pop(true);
      } else {
        throw Exception(result['message']?.toString() ?? 'Update failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _slider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('${value.round()}%'),
          ],
        ),
        Slider(
          value: value.clamp(0, 100),
          min: 0,
          max: 100,
          divisions: 100,
          activeColor: primaryTwo,
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit IPS',
          style: TextStyle(color: white, fontSize: 18),
        ),
        backgroundColor: primaryTwo,
        foregroundColor: Colors.white,
        actions: [
          if (_saving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: white,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save', style: TextStyle(color: white)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          TextField(
            controller: _documentIdDisplayCtrl,
            readOnly: true,
            decoration: _dec('Document ID'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: _dec('IPS title', hint: 'e.g. Annual IPS review'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _clientNameCtrl,
            decoration: _dec('Client name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _advisorCtrl,
            decoration: _dec('Advisor name', hint: 'Optional'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ageCtrl,
            keyboardType: TextInputType.number,
            decoration: _dec('Client age'),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Country of residence'),
            subtitle: Text(
              _residence.isEmpty ? 'Tap to choose' : _residence,
              style: TextStyle(
                color: _residence.isEmpty
                    ? Colors.grey.shade600
                    : Colors.black87,
              ),
            ),
            trailing: const Icon(Icons.public),
            onTap: _pickResidence,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _incomeCurrency,
            decoration: _dec('Income currency'),
            items: _currencies
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _incomeCurrency = v ?? 'UGX'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _monthlySavingsCtrl,
            decoration: _dec('Monthly savings', hint: 'Amount or range'),
          ),
          const SizedBox(height: 20),
          Text(
            'Goals',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryTwo,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _investmentGoalsCtrl,
            maxLines: 4,
            decoration: _dec('Investment goals'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _educationGoalsCtrl,
            maxLines: 3,
            decoration: _dec('Education goals', hint: 'Optional'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _retirementGoalsCtrl,
            maxLines: 3,
            decoration: _dec('Retirement goals', hint: 'Optional'),
          ),
          const SizedBox(height: 20),
          Text(
            'Risk profile',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryTwo,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _risk,
            decoration: _dec('Risk tolerance'),
            items: _riskKeys
                .map(
                  (k) => DropdownMenuItem(
                    value: k,
                    child: Text(k.replaceAll('_', ' ')),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _risk = v ?? 'moderate'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _timeHorizon,
            decoration: _dec('Time horizon'),
            items: _horizonKeys
                .map(
                  (k) => DropdownMenuItem(
                    value: k,
                    child: Text(switch (k) {
                      'short' => 'Short (1–3 years)',
                      'medium' => 'Medium (3–7 years)',
                      _ => 'Long (7+ years)',
                    }),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _timeHorizon = v ?? 'medium'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _liquidity,
            decoration: _dec('Liquidity needs'),
            items: _liquidityKeys
                .map(
                  (k) => DropdownMenuItem(
                    value: k,
                    child: Text(k[0].toUpperCase() + k.substring(1)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _liquidity = v ?? 'medium'),
          ),
          const SizedBox(height: 20),
          Text(
            'Strategic allocation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryTwo,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total: ${_allocTotal.toStringAsFixed(0)}% (must be 100%)',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          _slider('Global equities', _equities, (v) => setState(() => _equities = v)),
          _slider('Global bonds', _bonds, (v) => setState(() => _bonds = v)),
          _slider('Real assets', _realAssets, (v) => setState(() => _realAssets = v)),
          _slider('Alternatives', _alternatives,
              (v) => setState(() => _alternatives = v)),
          _slider('Cash & money market', _cash, (v) => setState(() => _cash = v)),
          const SizedBox(height: 16),
          TextField(
            controller: _emergencyFundCtrl,
            decoration: _dec('Emergency fund', hint: 'Optional'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _reviewFrequency,
            decoration: _dec('Review frequency'),
            items: _reviewFreq
                .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                .toList(),
            onChanged: (v) =>
                setState(() => _reviewFrequency = v ?? 'Annually'),
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            title: const Text('Constraints & notes'),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _taxCtrl,
                  maxLines: 3,
                  decoration: _dec('Tax considerations'),
                ),
              ),
              TextField(
                controller: _legalCtrl,
                maxLines: 3,
                decoration: _dec('Legal / regulatory'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ethicalCtrl,
                maxLines: 3,
                decoration: _dec('Ethical preferences'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _prohibitedCtrl,
                maxLines: 3,
                decoration: _dec('Prohibited investments'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _specialCtrl,
                maxLines: 3,
                decoration: _dec('Special circumstances'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: primaryTwo,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(_saving ? 'Saving…' : 'Save changes'),
          ),
        ],
      ),
    );
  }
}
