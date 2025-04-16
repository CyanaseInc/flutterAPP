import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';

class LoanSettings extends StatefulWidget {
  final int groupId;

  const LoanSettings({Key? key, required this.groupId}) : super(key: key);

  @override
  _LoanSettingsState createState() => _LoanSettingsState();
}

class _LoanSettingsState extends State<LoanSettings> {
  bool _onlyMembersWithSavingsCanRequest = true;
  double _maxLoanMultiplier = 3.0;
  List<Map<String, dynamic>> loanPeriods = [
    {'days': 30, 'interestRate': 10.0},
    {'days': 60, 'interestRate': 15.0},
    {'days': 180, 'interestRate': 20.0},
  ];

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.money, color: Colors.blue),
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
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            backgroundColor: white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
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

                      // Toggle for savings requirement
                      _buildToggleCard(
                        title: 'Only Members with Savings Can Request',
                        subtitle:
                            'Restrict loan requests to members with savings',
                        value: _onlyMembersWithSavingsCanRequest,
                        onChanged: (value) {
                          setState(() {
                            _onlyMembersWithSavingsCanRequest = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Loan multiplier slider
                      _buildSliderCard(
                        title: 'Maximum Loan Multiplier',
                        subtitle:
                            'Loans cannot exceed this multiple of savings',
                        value: _maxLoanMultiplier,
                        min: 2.0,
                        max: 5.0,
                        divisions: 3,
                        onChanged: (value) {
                          setState(() {
                            _maxLoanMultiplier = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Loan periods
                      Text(
                        'Loan Periods & Interest Rates',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...loanPeriods.asMap().entries.map((entry) {
                        final period = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _buildLoanPeriodCard(period),
                        );
                      }).toList(),
                      const SizedBox(height: 16),

                      // Add new period button
                      Center(
                        child: _buildGradientButton(
                          text: 'Add New Loan Period',
                          icon: Icons.add,
                          onPressed: _addLoanPeriod,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ),
                          _buildGradientButton(
                            text: 'Save',
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: primaryTwo,
              ),
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
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanPeriodCard(Map<String, dynamic> period) {
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
              onPressed: () => _editLoanPeriod(period),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _deleteLoanPeriod(period),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    IconData? icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryTwo, primaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 8.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                color: white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editLoanPeriod(Map<String, dynamic> period) {
    TextEditingController daysController =
        TextEditingController(text: period['days'].toString());
    TextEditingController interestController =
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
              onPressed: () {
                final days = int.tryParse(daysController.text);
                final interest = double.tryParse(interestController.text);
                if (days != null && days > 0 && interest != null) {
                  setState(() {
                    period['days'] = days;
                    period['interestRate'] = interest;
                  });
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

  void _deleteLoanPeriod(Map<String, dynamic> period) {
    setState(() {
      loanPeriods.remove(period);
    });
  }

  void _addLoanPeriod() {
    TextEditingController daysController = TextEditingController();
    TextEditingController interestController = TextEditingController();

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
              onPressed: () {
                final days = int.tryParse(daysController.text);
                final interest = double.tryParse(interestController.text);
                if (days != null && days > 0 && interest != null) {
                  setState(() {
                    loanPeriods.add({
                      'days': days,
                      'interestRate': interest,
                    });
                  });
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
