import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';

class GroupSettings extends StatefulWidget {
  const GroupSettings({Key? key}) : super(key: key);

  @override
  _GroupSettingsState createState() => _GroupSettingsState();
}

class _GroupSettingsState extends State<GroupSettings> {
  bool _allowMessageSending = true;
  bool _letMembersSeeSavings = true;
  bool _requirePaymentToJoin = false;
  bool _onlyMembersWithSavingsCanRequest = true;

  // Loan settings
  double _maxLoanMultiplier = 3.0; // Default to 3X
  List<Map<String, dynamic>> loanPeriods = [
    {'days': 30, 'interestRate': 10.0},
    {'days': 60, 'interestRate': 15.0},
    {'days': 180, 'interestRate': 20.0},
  ];

  // Dropdown options for loan multiplier
  final List<double> _loanMultiplierOptions = [2.0, 3.0, 4.0, 5.0];

  // Payment to enter group
  double _paymentAmount = 0.0;

  Widget _buildSettingItem(
      String title, String description, IconData icon, Widget? trailing) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title, style: const TextStyle(color: Colors.black87)),
      subtitle: Text(
        description,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: trailing,
      onTap: () {
        if (title == 'Loan Settings') {
          _showLoanSettingsDialog();
        }
      },
    );
  }

  void _showLoanSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Loan Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Toggle for allowing only members with savings to request loans
                ListTile(
                  title:
                      const Text('Only members with savings can request loans'),
                  subtitle: const Text(
                    'Restrict loan requests to members with savings',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  trailing: Switch(
                    value: _onlyMembersWithSavingsCanRequest,
                    onChanged: (value) {
                      setState(() {
                        _onlyMembersWithSavingsCanRequest = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Dropdown for maximum loan multiplier
                ListTile(
                  title: const Text('Maximum Loan Multiplier'),
                  subtitle: const Text(
                    'Loans should not exceed a multiple of savings',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  trailing: DropdownButton<double>(
                    value: _maxLoanMultiplier,
                    onChanged: (value) {
                      setState(() {
                        _maxLoanMultiplier = value!;
                      });
                    },
                    items: _loanMultiplierOptions.map((double value) {
                      return DropdownMenuItem<double>(
                        value: value,
                        child: Text('${value}X'),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),

                // List of loan periods and interest rates
                const Text(
                  'Loan Payment Periods and Interest Rates:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...loanPeriods.map((period) {
                  return ListTile(
                    title: Text(
                        '${period['days']} days - ${period['interestRate']}%'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            _editLoanPeriod(period);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deleteLoanPeriod(period);
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 10),

                // Button to add a new loan period
                ElevatedButton(
                  onPressed: () {
                    _addLoanPeriod();
                  },
                  child: const Text('Add New Loan Period'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
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
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  period['days'] = int.tryParse(daysController.text) ?? 0;
                  period['interestRate'] =
                      double.tryParse(interestController.text) ?? 0.0;
                });
                Navigator.pop(context);
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
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  loanPeriods.add({
                    'days': int.tryParse(daysController.text) ?? 0,
                    'interestRate':
                        double.tryParse(interestController.text) ?? 0.0,
                  });
                });
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentAmountDialog() {
    TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Payment Amount',
              style: TextStyle(color: Colors.black, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: 'Enter the payment amount',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              const Text(
                'Cyanase takes 30% of this amount',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _paymentAmount =
                      double.tryParse(amountController.text) ?? 0.0;
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: white,
      margin: const EdgeInsets.only(top: 8.0),
      child: ExpansionTile(
        title: const Text(
          'Group Settings',
          style: TextStyle(
              color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        children: [
          _buildSettingItem(
            'Edit group roles',
            'change group roles and permissions',
            Icons.edit,
            null,
          ),
          _buildSettingItem(
            'Send Messages',
            'Allow or restrict members from sending messages',
            Icons.message,
            Switch(
              value: _allowMessageSending,
              onChanged: (value) {
                setState(() {
                  _allowMessageSending = value;
                });
              },
            ),
          ),
          _buildSettingItem(
            'Group Permissions',
            'Manage who can add members or change settings',
            Icons.admin_panel_settings,
            null,
          ),
          _buildSettingItem(
            'Let Members See Each Other\'s Savings',
            'Enable or disable visibility of savings among members',
            Icons.visibility,
            Switch(
              value: _letMembersSeeSavings,
              onChanged: (value) {
                setState(() {
                  _letMembersSeeSavings = value;
                });
              },
            ),
          ),
          _buildSettingItem(
            'Loan Settings',
            'Configure loan request and approval rules',
            Icons.money,
            null,
          ),
          _buildSettingItem(
            'Pay on Requesting to Enter Group',
            'Require payment before joining the group',
            Icons.payment,
            Switch(
              value: _requirePaymentToJoin,
              onChanged: (value) {
                setState(() {
                  _requirePaymentToJoin = value;
                  if (value) {
                    _showPaymentAmountDialog();
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
