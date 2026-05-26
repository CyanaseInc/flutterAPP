import 'package:country_picker/country_picker.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/get_currency.dart';
import 'package:cyanase/screens/home/personal/ips_documents_screen.dart';
import 'package:cyanase/screens/settings/account_settings.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:flutter/material.dart';

/// Mirrors fund_portal `IPSWizard`: Personal → Financial goals → Risk → Allocation → Review.
class PersonalInvestmentPolicyScreen extends StatefulWidget {
  const PersonalInvestmentPolicyScreen({super.key});

  @override
  State<PersonalInvestmentPolicyScreen> createState() =>
      _PersonalInvestmentPolicyScreenState();
}

class _PersonalInvestmentPolicyScreenState
    extends State<PersonalInvestmentPolicyScreen> {
  static const _steps = [
    'Personal',
    'Goals',
    'Risk',
    'Allocation',
    'Review',
  ];

  static const _riskKeys = [
    'conservative',
    'moderate',
    'moderate_aggressive',
    'aggressive',
  ];

  static const _riskLabels = {
    'conservative': 'Conservative — capital preservation focus',
    'moderate': 'Moderate — balanced growth approach',
    'moderate_aggressive': 'Moderate-Aggressive — growth oriented',
    'aggressive': 'Aggressive — maximum growth potential',
  };

  static const _riskShort = {
    'conservative': 'Conservative',
    'moderate': 'Moderate',
    'moderate_aggressive': 'Mod-Agg',
    'aggressive': 'Aggressive',
  };

  static const _horizonKeys = ['short', 'medium', 'long'];
  static const _horizonLabels = {
    'short': 'Short term (1–3 years)',
    'medium': 'Medium term (3–7 years)',
    'long': 'Long term (7+ years)',
  };

  static const _horizonShort = {
    'short': '1–3y',
    'medium': '3–7y',
    'long': '7+y',
  };

  static const _liquidityKeys = ['low', 'medium', 'high'];
  static const _liquidityLabels = {
    'low': 'Low — funds are long term',
    'medium': 'Medium — occasional withdrawals',
    'high': 'High — frequent access needed',
  };

  static const _liquidityShort = {
    'low': 'Low',
    'medium': 'Med',
    'high': 'High',
  };

  int _step = 0;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  /// From SQLite profile — authoritative for display and save payload.
  String _profileName = '';
  String _profileEmail = '';
  String _profilePhone = '';

  final _advisorCtrl = TextEditingController();
  final _monthlySavingsCtrl = TextEditingController();
  final _strategyNotesCtrl = TextEditingController();

  final _clientAgeCtrl = TextEditingController();

  String _residence = '';
  String _incomeCurrency = 'UGX';

  String _risk = 'moderate';
  String _timeHorizon = 'medium';
  String _liquidity = 'medium';

  double _equities = 50;
  double _bonds = 30;
  double _realAssets = 10;
  double _alternatives = 5;
  double _cash = 5;

  bool _ageFromProfile = false;
  bool _didAutoApplyAllocation = false;

  double _toDouble(dynamic v, double fallback) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  int _toInt(dynamic v, int fallback) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  double get _allocationTotal =>
      _equities + _bonds + _realAssets + _alternatives + _cash;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _advisorCtrl.dispose();
    _monthlySavingsCtrl.dispose();
    _strategyNotesCtrl.dispose();
    _clientAgeCtrl.dispose();
    super.dispose();
  }

  void _applyRecommendedAllocation() {
    final m = {
      'conservative': [20.0, 50.0, 10.0, 5.0, 15.0],
      'moderate': [50.0, 30.0, 10.0, 5.0, 5.0],
      'moderate_aggressive': [65.0, 20.0, 10.0, 3.0, 2.0],
      'aggressive': [75.0, 15.0, 5.0, 3.0, 2.0],
    };
    final row = m[_risk] ?? m['moderate']!;
    setState(() {
      _equities = row[0];
      _bonds = row[1];
      _realAssets = row[2];
      _alternatives = row[3];
      _cash = row[4];
    });
  }

  String _maskEmail(String e) {
    final t = e.trim();
    if (t.length <= 4) return t;
    final at = t.indexOf('@');
    if (at <= 1) return t;
    return '${t.substring(0, 2)}•••@${t.substring(at + 1)}';
  }

  String _initials(String name) {
    final p = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (p.isEmpty) return '?';
    if (p.length == 1) return p.first.substring(0, 1).toUpperCase();
    return '${p.first[0]}${p.last[0]}'.toUpperCase();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final db = await DatabaseHelper().database;
      final rows = await db.query('profile', limit: 1);
      if (rows.isEmpty) throw Exception('Not signed in');
      final token = (rows.first['token'] as String?)?.trim() ?? '';
      if (token.isEmpty) throw Exception('Not signed in');
      final p = rows.first;
      final data = await ApiService.getInvestmentPolicy(token);
      if (!mounted) return;

      final profileName = (p['name'] ?? '').toString();
      final profileEmail = (p['email'] ?? '').toString();
      final profilePhone = (p['phone_number'] ?? '').toString();

      final res = (data['residence'] ?? p['country'] ?? '').toString();
      final cur = (data['income_currency'] ?? '').toString();
      final ms = (data['monthly_savings'] ?? '').toString();
      final rt = (data['risk_tolerance'] ?? 'moderate').toString().trim();
      final th = (data['time_horizon'] ?? 'medium').toString().trim();
      final liq = (data['liquidity_needs'] ?? 'medium').toString().trim();
      final goals = (data['investment_goals'] ?? '').toString();
      final age = data['client_age'];
      final ageFromProfile = data['age_from_profile'] == true;

      setState(() {
        _profileName = profileName;
        _profileEmail = profileEmail;
        _profilePhone = profilePhone;
        _residence = res;
        if (cur.isNotEmpty) {
          _incomeCurrency = cur;
        }
        _monthlySavingsCtrl.text = ms;
        _strategyNotesCtrl.text = goals;
        _advisorCtrl.text = (data['advisor_name'] ?? '').toString();
        _ageFromProfile = ageFromProfile;
        if (_ageFromProfile && age != null) {
          final ai = _toInt(age, 0);
          _clientAgeCtrl.text = ai > 0 ? '$ai' : '';
        } else {
          _clientAgeCtrl.text = age != null && '$age'.isNotEmpty && _toInt(age, 0) > 0
              ? '${_toInt(age, 0)}'
              : '';
        }
        _risk = _riskKeys.contains(rt) ? rt : 'moderate';
        _timeHorizon = _horizonKeys.contains(th) ? th : 'medium';
        _liquidity = _liquidityKeys.contains(liq) ? liq : 'medium';
        _equities = _toDouble(data['global_equities'], 50);
        _bonds = _toDouble(data['global_bonds'], 30);
        _realAssets = _toDouble(data['real_assets'], 10);
        _alternatives = _toDouble(data['alternatives'], 5);
        _cash = _toDouble(data['cash_mmf'], 5);
        _didAutoApplyAllocation = false;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final db = await DatabaseHelper().database;
      final rows = await db.query('profile', limit: 1);
      if (rows.isEmpty) throw Exception('Not signed in');
      final token = (rows.first['token'] as String?)?.trim() ?? '';
      if (token.isEmpty) throw Exception('Not signed in');

      final age = int.tryParse(_clientAgeCtrl.text.trim()) ?? 0;
      final body = <String, dynamic>{
        'risk_tolerance': _risk,
        'time_horizon': _timeHorizon,
        'investment_goals': _strategyNotesCtrl.text.trim(),
        'client_name': _profileName.trim(),
        'client_email': _profileEmail.trim(),
        'client_phone': _profilePhone.trim(),
        'advisor_name': _advisorCtrl.text.trim(),
        'residence': _residence.trim(),
        'income_currency': _incomeCurrency,
        'monthly_savings': _monthlySavingsCtrl.text.trim(),
        'liquidity_needs': _liquidity,
        'goal_name': '',
        'client_age': age,
        'global_equities': _equities,
        'global_bonds': _bonds,
        'real_assets': _realAssets,
        'alternatives': _alternatives,
        'cash_mmf': _cash,
      };

      final result = await ApiService.saveInvestmentPolicy(token, body);
      if (!mounted) return;
      final complete = result['complete'] == true;
      if (complete) {
        Navigator.of(context).pop(true);
      } else {
        final miss = (result['missing'] as List<dynamic>?)?.join(', ') ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              miss.isNotEmpty
                  ? 'Still incomplete: $miss'
                  : 'Please complete all required sections.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _validateStep(int s) {
    switch (s) {
      case 0:
        if (!_ageFromProfile) {
          final age = int.tryParse(_clientAgeCtrl.text.trim()) ?? 0;
          if (age < 18 || age > 120) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter a valid age (18–120)')),
            );
            return false;
          }
        }
        if (_residence.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select country of residence')),
          );
          return false;
        }
        if (_monthlySavingsCtrl.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter monthly savings')),
          );
          return false;
        }
        return true;
      case 1:
        if (_strategyNotesCtrl.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please describe what you are investing for'),
            ),
          );
          return false;
        }
        return true;
      case 2:
        return true;
      case 3:
        if ((_allocationTotal - 100).abs() > 0.51) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Asset allocation must total 100% (currently ${_allocationTotal.toStringAsFixed(0)}%)',
              ),
            ),
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _goNext() {
    if (!_validateStep(_step)) return;
    if (_step == 2 && !_didAutoApplyAllocation) {
      _applyRecommendedAllocation();
      _didAutoApplyAllocation = true;
    }
    setState(() => _step += 1);
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
          _incomeCurrency = currency;
        });
      },
    );
  }

  Widget _stepIntro(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryTwo,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, height: 1.35, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String label, {String? hint, String? helper}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _stepCard({required Widget child}) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _identityCard() {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: primaryTwo.withValues(alpha: 0.15),
              child: Text(
                _initials(_profileName),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryTwo,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _profileName.trim().isEmpty ? 'Your account' : _profileName.trim(),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _profileEmail.isEmpty ? '—' : _maskEmail(_profileEmail),
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  if (_profilePhone.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      _profilePhone.trim(),
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    ),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                        await Navigator.of(context).push<bool>(
                          MaterialPageRoute(builder: (_) => AccountSettingsPage()),
                        );
                        if (mounted) _load();
                      },
                      child: const Text('Update in account settings'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segmentedRow<T extends Object>({
    required String label,
    required List<T> keys,
    required T value,
    required String Function(T) shortLabel,
    required ValueChanged<T> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<T>(
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            showSelectedIcon: false,
            segments: keys
                .map(
                  (k) => ButtonSegment<T>(
                    value: k,
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        shortLabel(k),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                )
                .toList(),
            selected: {value},
            onSelectionChanged: (Set<T> next) {
              if (next.isEmpty) return;
              onChanged(next.first);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepIntro(
          'About you',
          'We use your account details below. Add a few details only we do not already have.',
        ),
        _identityCard(),
        const SizedBox(height: 16),
        _stepCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_ageFromProfile) ...[
                TextFormField(
                  controller: _clientAgeCtrl,
                  decoration: _dec('Age', hint: 'e.g. 30'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
              ] else ...[
                Text(
                  'Age on file: ${_clientAgeCtrl.text.trim().isEmpty ? "—" : _clientAgeCtrl.text.trim()}',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _monthlySavingsCtrl,
                decoration: _dec(
                  'Monthly savings ($_incomeCurrency)',
                  hint: 'e.g. 2000',
                  helper: 'Currency follows country of residence',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Country of residence *'),
                subtitle: Text(
                  _residence.isEmpty ? 'Tap to select' : _residence,
                  style: TextStyle(
                    color: _residence.isEmpty ? Colors.grey : primaryTwo,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: _pickResidence,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepIntro(
          'Your goals',
          'In your own words, what are you investing for?',
        ),
        _stepCard(
          child: TextFormField(
            controller: _strategyNotesCtrl,
            minLines: 5,
            maxLines: 10,
            decoration: InputDecoration(
              labelText: 'What are you investing for? *',
              hintText:
                  'e.g. Retirement in 20 years, children\'s education, building an emergency fund…',
              alignLabelWithHint: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRiskStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepIntro(
          'Risk profile',
          'Pick the options that best describe you. Tap a segment to change it.',
        ),
        _stepCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _segmentedRow<String>(
                label: 'Risk tolerance',
                keys: _riskKeys,
                value: _riskKeys.contains(_risk) ? _risk : 'moderate',
                shortLabel: (k) => _riskShort[k] ?? k,
                onChanged: (v) => setState(() => _risk = v),
              ),
              _segmentedRow<String>(
                label: 'Time horizon',
                keys: _horizonKeys,
                value: _horizonKeys.contains(_timeHorizon) ? _timeHorizon : 'medium',
                shortLabel: (k) => _horizonShort[k] ?? k,
                onChanged: (v) => setState(() => _timeHorizon = v),
              ),
              _segmentedRow<String>(
                label: 'Liquidity needs',
                keys: _liquidityKeys,
                value: _liquidityKeys.contains(_liquidity) ? _liquidity : 'medium',
                shortLabel: (k) => _liquidityShort[k] ?? k,
                onChanged: (v) => setState(() => _liquidity = v),
              ),
              const SizedBox(height: 4),
              Text(
                '${_riskLabels[_risk]}\n${_horizonLabels[_timeHorizon]}\n${_liquidityLabels[_liquidity]}',
                style: TextStyle(fontSize: 12, height: 1.4, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sliderRow(String label, String hint, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
            Text('${value.round()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value.clamp(0, 100),
          min: 0,
          max: 100,
          divisions: 100,
          activeColor: primaryTwo,
          label: '${value.round()}%',
          onChanged: onChanged,
        ),
        Text(hint, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildAllocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepIntro(
          'Asset allocation',
          'Adjust the mix below. It must total 100%. We started from a model split for your risk level.',
        ),
        _stepCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 20, color: primaryTwo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Model: ${_riskShort[_risk] ?? _risk}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _applyRecommendedAllocation();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reset to recommended split')),
                      );
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _sliderRow(
                'Global equities',
                'Higher growth potential, higher volatility',
                _equities,
                (v) => setState(() => _equities = v),
              ),
              _sliderRow(
                'Fixed income (bonds)',
                'Steady income, capital preservation',
                _bonds,
                (v) => setState(() => _bonds = v),
              ),
              _sliderRow(
                'Real assets',
                'Real estate / commodities, inflation hedge',
                _realAssets,
                (v) => setState(() => _realAssets = v),
              ),
              _sliderRow(
                'Alternatives',
                'Private equity, hedge funds, etc.',
                _alternatives,
                (v) => setState(() => _alternatives = v),
              ),
              _sliderRow(
                'Cash & equivalents',
                'Liquidity and safety',
                _cash,
                (v) => setState(() => _cash = v),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(
                    '${_allocationTotal.round()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: (_allocationTotal - 100).abs() <= 0.51
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              k,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(v, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    final age = int.tryParse(_clientAgeCtrl.text.trim()) ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepIntro(
          'Review',
          'Confirm your investment profile before saving.',
        ),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                _reviewRow('Name', _profileName.trim().isEmpty ? '—' : _profileName.trim()),
                _reviewRow('Email', _profileEmail.isEmpty ? '—' : _profileEmail.trim()),
                _reviewRow(
                  'Phone',
                  _profilePhone.trim().isEmpty ? '—' : _profilePhone.trim(),
                ),
                _reviewRow('Age', (_ageFromProfile || age > 0) ? '$age' : '—'),
                _reviewRow('Residence', _residence.isEmpty ? '—' : _residence),
                _reviewRow(
                  'Monthly savings',
                  '${_monthlySavingsCtrl.text.trim()} $_incomeCurrency',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              'Advanced (optional)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            subtitle: const Text('Financial advisor name'),
            children: [
              TextFormField(
                controller: _advisorCtrl,
                decoration: _dec('Advisor name', hint: "Optional"),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Goals & risk',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                _reviewRow('Investing for', _strategyNotesCtrl.text.trim()),
                _reviewRow('Risk', _riskLabels[_risk] ?? _risk),
                _reviewRow('Time horizon', _horizonLabels[_timeHorizon] ?? _timeHorizon),
                _reviewRow('Liquidity', _liquidityLabels[_liquidity] ?? _liquidity),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Asset allocation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                _reviewRow('Equities', '${_equities.round()}%'),
                _reviewRow('Bonds', '${_bonds.round()}%'),
                _reviewRow('Real assets', '${_realAssets.round()}%'),
                _reviewRow('Alternatives', '${_alternatives.round()}%'),
                _reviewRow('Cash', '${_cash.round()}%'),
                _reviewRow('Total', '${_allocationTotal.round()}%'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: List.generate(_steps.length, (i) {
              final done = i < _step;
              final active = i == _step;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: done || active ? primaryTwo : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            'Step ${_step + 1} of ${_steps.length}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            _steps[_step],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryTwo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return _buildPersonalStep();
      case 1:
        return _buildGoalsStep();
      case 2:
        return _buildRiskStep();
      case 3:
        return _buildAllocationStep();
      default:
        return _buildReviewStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Investment profile',
          style: TextStyle(color: white, fontSize: 18),
        ),
        backgroundColor: primaryTwo,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primaryTwo))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    _buildProgressHeader(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Material(
                        color: Colors.white,
                        elevation: 1,
                        shadowColor: primaryTwo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          leading: Icon(
                            Icons.folder_special_outlined,
                            color: primaryTwo,
                          ),
                          title: const Text(
                            'Formal IPS documents',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text(
                            'View or edit saved Investment Policy Statements',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const IpsDocumentsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        children: [_stepBody()],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        8 + MediaQuery.paddingOf(context).bottom,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          if (_step > 0)
                            OutlinedButton(
                              onPressed: _saving
                                  ? null
                                  : () => setState(() => _step -= 1),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryTwo,
                                side: const BorderSide(color: primaryTwo),
                              ),
                              child: const Text('Back'),
                            )
                          else
                            const SizedBox(width: 72),
                          const Spacer(),
                          if (_step < _steps.length - 1)
                            FilledButton(
                              onPressed: _saving ? null : _goNext,
                              style: FilledButton.styleFrom(
                                backgroundColor: primaryTwo,
                                foregroundColor: white,
                              ),
                              child: const Text('Next'),
                            )
                          else
                            FilledButton(
                              onPressed: _saving
                                  ? null
                                  : () {
                                      if (!_validateStep(0) ||
                                          !_validateStep(1) ||
                                          !_validateStep(3)) {
                                        return;
                                      }
                                      _save();
                                    },
                              style: FilledButton.styleFrom(
                                backgroundColor: primaryTwo,
                                foregroundColor: white,
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: white,
                                      ),
                                    )
                                  : const Text('Save profile'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
