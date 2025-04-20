// lib/screens/home/group/settings/loan_setting.dart
import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'dart:convert';
import 'package:cyanase/helpers/loader.dart';

class LoanSettings extends StatefulWidget {
  final int groupId;
  final Map<String, dynamic> initialLoanSettings;
  const LoanSettings({
    Key? key,
    required this.groupId,
    required this.initialLoanSettings,
  }) : super(key: key);

  @override
  _LoanSettingsState createState() => _LoanSettingsState();
}

class _LoanSettingsState extends State<LoanSettings> {
  bool _allowLoans = true;
  bool _onlyMembersWithSavingsCanRequest = true;
  double _maxLoanMultiplier = 3.0;
  List<Map<String, dynamic>> loanPeriods = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeLoanSettings();
  }

  void _initializeLoanSettings() {
    if (widget.initialLoanSettings.isNotEmpty) {
      setState(() {
        _allowLoans = widget.initialLoanSettings['allow_loans'] ?? true;
        _onlyMembersWithSavingsCanRequest =
            widget.initialLoanSettings['require_savings'] ?? true;
        _maxLoanMultiplier =
            widget.initialLoanSettings['max_multiplier']?.toDouble() ?? 3.0;
        loanPeriods = List<Map<String, dynamic>>.from(
          widget.initialLoanSettings['periods'] ?? [],
        );
      });
    }
  }

  Future<void> _updateSettings(
    Map<String, dynamic> settings, {
    VoidCallback? onRevert,
  }) async {
    try {
      final db = await DatabaseHelper().database;
      final profile = await db.query('profile', limit: 1);

      // Log the profile query result

      // Check if profile is empty
      if (profile.isEmpty) {
        throw Exception('No user profile found. Please log in again.');
      }

      // Safely retrieve token
      final token = profile.first['token'];
      if (token == null || token is! String || token.isEmpty) {
        throw Exception(
            'Invalid or missing authentication token. Please log in again.');
      }

      final data = {
        'groupId': widget.groupId.toString(),
        'setting': jsonEncode({
          'action': 'update_loan_settings',
          'loan_settings': settings,
        }),
      };

      final response = await ApiService.loanSettings(token, data);

      if (response['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Setting updated successfully')),
        );
        setState(() {
          if (settings.containsKey('allow_loans')) {
            _allowLoans = settings['allow_loans'];
          }
          if (settings.containsKey('require_savings')) {
            _onlyMembersWithSavingsCanRequest = settings['require_savings'];
          }
          if (settings.containsKey('max_multiplier')) {
            _maxLoanMultiplier = settings['max_multiplier'];
          }
          if (settings.containsKey('periods')) {
            loanPeriods = List<Map<String, dynamic>>.from(settings['periods']);
          }
        });
      } else {
        throw Exception(
            'Failed to update setting: ${response['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update setting: $e')),
        );
        if (onRevert != null) {
          onRevert();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: Loader())
        : ListTile(
            leading: const Icon(Icons.money, color: Colors.blue),
            title: const Text(
              'Loan Settings',
              style: TextStyle(color: Colors.black87),
            ),
            subtitle: const Text(
              'Configure loan request and approval rules',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            onTap: _showLoanSettingsDialog,
          );
  }

  void _showLoanSettingsDialog() {
    // Local state for dialog
    bool localAllowLoans = _allowLoans;
    bool localOnlyMembersWithSavings = _onlyMembersWithSavingsCanRequest;
    double localMaxLoanMultiplier = _maxLoanMultiplier;
    List<Map<String, dynamic>> localLoanPeriods = List.from(loanPeriods);
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Stack(
              children: [
                Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  backgroundColor: white,
                  insetPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    constraints:
                        const BoxConstraints(maxWidth: 400, maxHeight: 600),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.account_balance_wallet,
                                    color: primaryTwo, size: 32),
                                const SizedBox(width: 12),
                                Text(
                                  'Loan Settings',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Customize loan rules for your group',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildToggleCard(
                              title: 'Allow Loans',
                              subtitle: 'Allow members to request for loans',
                              value: localAllowLoans,
                              isSaving: isSaving,
                              onChanged: (value) async {
                                setDialogState(() {
                                  localAllowLoans = value;
                                  isSaving = true;
                                });
                                await _updateSettings(
                                  {'allow_loans': value},
                                  onRevert: () {
                                    setDialogState(() {
                                      localAllowLoans = !value;
                                    });
                                  },
                                );
                                setDialogState(() {
                                  isSaving = false;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildToggleCard(
                              title: 'Loan Request',
                              subtitle:
                                  'Restrict loan requests to members with savings',
                              value: localOnlyMembersWithSavings,
                              isSaving: isSaving,
                              onChanged: (value) async {
                                setDialogState(() {
                                  localOnlyMembersWithSavings = value;
                                  isSaving = true;
                                });
                                await _updateSettings(
                                  {'require_savings': value},
                                  onRevert: () {
                                    setDialogState(() {
                                      localOnlyMembersWithSavings = !value;
                                    });
                                  },
                                );
                                setDialogState(() {
                                  isSaving = false;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildSliderCard(
                              title: 'Maximum Loan Multiplier',
                              subtitle:
                                  'Loans cannot exceed this multiple of savings',
                              value: localMaxLoanMultiplier,
                              min: 2.0,
                              max: 5.0,
                              divisions: 3,
                              isSaving: isSaving,
                              onChanged: (value) {
                                setDialogState(() {
                                  localMaxLoanMultiplier = value;
                                });
                              },
                              onChangeEnd: (value) async {
                                setDialogState(() {
                                  isSaving = true;
                                });
                                await _updateSettings(
                                  {'max_multiplier': value},
                                  onRevert: () {
                                    setDialogState(() {
                                      localMaxLoanMultiplier =
                                          _maxLoanMultiplier;
                                    });
                                  },
                                );
                                setDialogState(() {
                                  isSaving = false;
                                });
                              },
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Loan Periods & Interest Rates',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (localLoanPeriods.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'No loan periods defined. Add one below.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              )
                            else
                              ...localLoanPeriods.map((period) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: _buildLoanPeriodCard(
                                      period,
                                      setDialogState,
                                      localLoanPeriods,
                                      isSaving,
                                    ),
                                  )),
                            const SizedBox(height: 16),
                            Center(
                              child: _buildGradientButton(
                                text: 'Add New Loan Period',
                                icon: Icons.add,
                                onPressed: isSaving
                                    ? null
                                    : () => _addLoanPeriod(
                                          setDialogState,
                                          localLoanPeriods,
                                        ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Close',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (isSaving)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isSaving,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: isSaving ? null : onChanged,
              activeColor: primaryTwo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderCard({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    ValueChanged<double>? onChangeEnd,
    required bool isSaving,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${value.toStringAsFixed(1)}X',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryTwo,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: divisions,
                    activeColor: primaryTwo,
                    inactiveColor: Colors.grey[300],
                    onChanged: isSaving ? (_) {} : onChanged,
                    onChangeEnd: isSaving ? null : onChangeEnd,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanPeriodCard(
    Map<String, dynamic> period,
    StateSetter setDialogState,
    List<Map<String, dynamic>> localLoanPeriods,
    bool isSaving,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          '${period['days']} days',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          '${period['interestRate']}% interest',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: primaryTwo),
              onPressed: isSaving
                  ? null
                  : () =>
                      _editLoanPeriod(period, setDialogState, localLoanPeriods),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: isSaving
                  ? null
                  : () => _deleteLoanPeriod(
                      period, setDialogState, localLoanPeriods),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    IconData? icon,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        backgroundColor: primaryTwo,
        elevation: 4,
        shadowColor: Colors.grey.withOpacity(0.3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: primaryColor, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: const TextStyle(
              color: primaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _editLoanPeriod(
    Map<String, dynamic> period,
    StateSetter setDialogState,
    List<Map<String, dynamic>> localLoanPeriods,
  ) {
    final daysController =
        TextEditingController(text: period['days'].toString());
    final interestController =
        TextEditingController(text: period['interestRate'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Loan Period'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: daysController,
                decoration: const InputDecoration(labelText: 'Days'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: interestController,
                decoration:
                    const InputDecoration(labelText: 'Interest Rate (%)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final days = int.tryParse(daysController.text);
                final interest = double.tryParse(interestController.text);
                if (days != null && days > 0 && interest != null) {
                  setDialogState(() {
                    period['days'] = days;
                    period['interestRate'] = interest;
                  });
                  setState(() {
                    loanPeriods = localLoanPeriods;
                  });
                  await _updateSettings({'periods': localLoanPeriods});
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid values')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteLoanPeriod(
    Map<String, dynamic> period,
    StateSetter setDialogState,
    List<Map<String, dynamic>> localLoanPeriods,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content:
              const Text('Are you sure you want to delete this loan period?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final originalPeriods =
                    List<Map<String, dynamic>>.from(localLoanPeriods);
                setDialogState(() {
                  localLoanPeriods.remove(period);
                });
                setState(() {
                  loanPeriods = localLoanPeriods;
                });
                await _updateSettings(
                  {'periods': localLoanPeriods},
                  onRevert: () {
                    setDialogState(() {
                      localLoanPeriods.clear();
                      localLoanPeriods.addAll(originalPeriods);
                    });
                    setState(() {
                      loanPeriods = originalPeriods;
                    });
                  },
                );
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _addLoanPeriod(
    StateSetter setDialogState,
    List<Map<String, dynamic>> localLoanPeriods,
  ) {
    final daysController = TextEditingController();
    final interestController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Loan Period'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: daysController,
                decoration: const InputDecoration(labelText: 'Days'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: interestController,
                decoration:
                    const InputDecoration(labelText: 'Interest Rate (%)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final days = int.tryParse(daysController.text);
                final interest = double.tryParse(interestController.text);
                if (days != null && days > 0 && interest != null) {
                  final newPeriod = {'days': days, 'interestRate': interest};
                  setDialogState(() {
                    localLoanPeriods.add(newPeriod);
                  });
                  setState(() {
                    loanPeriods = localLoanPeriods;
                  });
                  await _updateSettings({'periods': localLoanPeriods});
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid values')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
