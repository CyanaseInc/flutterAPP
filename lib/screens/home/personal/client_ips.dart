import 'package:flutter/material.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/theme/theme.dart';

class ClientIpsScreen extends StatefulWidget {
  final String shareId;
  const ClientIpsScreen({super.key, required this.shareId});

  @override
  State<ClientIpsScreen> createState() => _ClientIpsScreenState();
}

class _ClientIpsScreenState extends State<ClientIpsScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _goalController = TextEditingController();
  final _riskController = TextEditingController(text: 'moderate');
  final _signNameController = TextEditingController();
  bool _agree = false;
  bool _loading = true;
  bool _signing = false;
  int _step = 0;
  Map<String, dynamic>? _shared;

  @override
  void initState() {
    super.initState();
    _loadSharedIps();
  }

  Future<void> _loadSharedIps() async {
    String profileEmail = '';
    try {
      final db = await DatabaseHelper().database;
      final rows = await db.query('profile', limit: 1);
      if (rows.isNotEmpty) {
        profileEmail = (rows.first['email'] as String? ?? '').trim();
      }
    } catch (_) {}

    try {
      final result = await ApiService.getSharedIPS(widget.shareId);
      final ips = result['ips'] as Map<String, dynamic>?;
      if (ips != null) {
        _shared = ips;
        _nameController.text = (ips['client_name'] ?? '').toString();
        if (profileEmail.isNotEmpty) {
          _emailController.text = profileEmail;
        } else {
          _emailController.text = (ips['client_email'] ?? '').toString();
        }
        _goalController.text = (ips['investment_goals'] ?? '').toString();
        _riskController.text =
            (ips['risk_tolerance'] ?? 'moderate').toString();
      } else if (profileEmail.isNotEmpty) {
        _emailController.text = profileEmail;
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitAndSign() async {
    if (_signNameController.text.trim().isEmpty || !_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete signature fields to continue')),
      );
      return;
    }

    setState(() => _signing = true);
    try {
      await ApiService.signSharedIPS({
        'share_id': widget.shareId,
        'accepted_by_name': _signNameController.text.trim(),
        'client_email': _emailController.text.trim(),
        'fund_email': (_shared?['fund_email'] ?? '').toString(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('IPS signed successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signing failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _signing = false);
    }
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryTwo, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: white,
        appBar: AppBar(
          backgroundColor: primaryTwo,
          foregroundColor: white,
          title: const Text('Investment Policy Statement'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: primaryTwo),
        ),
      );
    }

    final steps = ['Profile', 'Objectives', 'Review & Sign'];
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: primaryTwo,
        foregroundColor: white,
        elevation: 0,
        title: const Text(
          'Investment Policy Statement',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: List.generate(steps.length, (index) {
                  final active = index == _step;
                  final done = index < _step;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: active
                            ? primaryTwo.withOpacity(0.12)
                            : done
                                ? surfaceMuted
                                : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: active
                              ? primaryTwo
                              : surfaceMutedBorder,
                        ),
                      ),
                      child: Text(
                        steps[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                          color: active ? primaryTwo : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _step == 0
                    ? _profileStep()
                    : _step == 1
                        ? _objectivesStep()
                        : _reviewStep(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step -= 1),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryTwo,
                          side: const BorderSide(color: primaryTwo),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTwo,
                        foregroundColor: white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _step < 2
                          ? () => setState(() => _step += 1)
                          : (_signing ? null : _submitAndSign),
                      child: Text(_step < 2
                          ? 'Continue'
                          : (_signing ? 'Signing...' : 'Accept & Sign')),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _profileStep() {
    return Column(
      children: [
        TextField(
            controller: _nameController,
            decoration: _fieldDecoration('Full name')),
        const SizedBox(height: 12),
        TextField(
          controller: _emailController,
          readOnly: true,
          enableInteractiveSelection: true,
          decoration: _fieldDecoration('Account email').copyWith(
            helperText: 'Uses your signed-in email for this IPS',
            suffixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  Widget _objectivesStep() {
    return Column(
      children: [
        TextField(
          controller: _goalController,
          maxLines: 4,
          decoration: _fieldDecoration('Investment objectives'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _riskController,
          decoration: _fieldDecoration('Risk tolerance (IPS)'),
        ),
      ],
    );
  }

  Widget _reviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email: ${_emailController.text}',
            style: TextStyle(color: Colors.grey.shade800, fontSize: 14)),
        const SizedBox(height: 6),
        Text('Client: ${_nameController.text}',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: primaryTwo)),
        const SizedBox(height: 6),
        Text('Goals: ${_goalController.text}',
            style: TextStyle(color: Colors.grey.shade800)),
        const SizedBox(height: 6),
        Text('Risk tolerance: ${_riskController.text}',
            style: TextStyle(color: Colors.grey.shade800)),
        const SizedBox(height: 20),
        TextField(
          controller: _signNameController,
          decoration: _fieldDecoration('Type your legal name to sign'),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: primaryTwo,
          title: const Text('I accept this Investment Policy Statement'),
          value: _agree,
          onChanged: (v) => setState(() => _agree = v ?? false),
        ),
      ],
    );
  }
}
