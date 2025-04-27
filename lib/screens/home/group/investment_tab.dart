import 'package:cyanase/helpers/loader.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/database_helper.dart';

class InvestmentsTab extends StatefulWidget {
  final int groupId;
  final Map<String, dynamic> investmentsData;

  const InvestmentsTab(
      {Key? key, required this.groupId, required this.investmentsData})
      : super(key: key);

  @override
  _InvestmentsTabState createState() => _InvestmentsTabState();
}

class _InvestmentsTabState extends State<InvestmentsTab> {
  late List<Map<String, dynamic>> investments;

  @override
  void initState() {
    super.initState();
    investments = List<Map<String, dynamic>>.from(
        widget.investmentsData['investments'] ?? []);
  }

  Future<void> _addInvestment(
      String name, double amount, double interest) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      final token = userProfile.first['token'] as String;

      final response = await ApiService.addInvestment(
        token: token,
        groupId: widget.groupId,
        data: {
          'assets': name,
          'amountout': amount,
          'amountin': 0,
          'rate':
              (interest / amount * 100).toInt(), // Calculate rate as percentage
          'status': true,
          'created': DateTime.now()
              .toIso8601String()
              .split('T')[0]
              .replaceAll('-', ':'),
        },
      );

      if (response['success'] == true) {
        setState(() {
          investments.add({
            'id': response['data']['id'],
            'name': name,
            'amount': 'UGX ${amount.toInt()}',
            'interest': 'UGX ${interest.toInt()}',
            'date': DateTime.now().toIso8601String().split('T')[0],
          });
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Investment added successfully')),
        );
      } else {
        throw Exception(response['error'] ?? 'Failed to add investment');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add investment: $e')),
      );
    }
  }

  Future<void> _payoutInterest(
    double amount,
    String password,
    BuildContext dialogContext, // To control modal closure
    Function(bool) setLoading, // To manage loading state
  ) async {
    try {
      // Get the total group interest amount from the summary data
      final totalGroupInterestStr = widget.investmentsData['summary']
              ?['total_group_interest']?['amount'] ??
          'UGX 0';
      final totalGroupInterest = double.parse(
          totalGroupInterestStr.replaceAll('UGX ', '').replaceAll(',', ''));

      // Validate that the payout amount doesn't exceed total group interest
      if (amount > totalGroupInterest) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text(
                'Payout amount (UGX ${amount.toInt()}) exceeds total group interest (UGX ${totalGroupInterest.toInt()})'),
          ),
        );
        setLoading(false); // Reset loading state
        return;
      }

      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      final token = userProfile.first['token'] as String;

      // Send payout request with password, currency, and txRef
      final response = await ApiService.payoutInterest(
        token: token,
        groupId: widget.groupId,
        amount: amount,
        password: password,
      );

      if (response['success'] == true) {
        setState(() {
          // Update the total_group_interest in the summary data
          final newTotal = totalGroupInterest - amount;
          widget.investmentsData['summary']?['total_group_interest']
              ?['amount'] = 'UGX $newTotal';
        });
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          const SnackBar(
              content: Text('Interest payout processed successfully')),
        );
        // Close the modal only on success
        Navigator.pop(dialogContext);
      } else {
        // Show error without closing the modal
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text(response['error'] ?? 'Failed to payout interest'),
          ),
        );
      }
    } catch (e) {
      // Show error without closing the modal
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(content: Text('Failed to payout interest: $e')),
      );
    } finally {
      setLoading(false); // Reset loading state
    }
  }

  void _showPayoutInterestForm(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String? amount;
    String? password;

    bool isLoading = false; // Track loading state locally

    final totalGroupInterestStr = widget.investmentsData['summary']
            ?['total_group_interest']?['amount'] ??
        'UGX 0';
    final totalGroupInterest = double.parse(
        totalGroupInterestStr.replaceAll('UGX ', '').replaceAll(',', ''));

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, dialogSetState) => AlertDialog(
          title: const Text(
            'Pay Out Group Interest',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Payout Amount (UGX)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !isLoading, // Disable input during loading
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      final amountValue = double.tryParse(value);
                      if (amountValue == null) {
                        return 'Please enter a valid number';
                      }
                      if (amountValue > totalGroupInterest) {
                        return 'Amount exceeds total group interest (UGX ${totalGroupInterest.toInt()})';
                      }
                      if (amountValue <= 0) {
                        return 'Amount must be greater than zero';
                      }
                      return null;
                    },
                    onSaved: (value) => amount = value,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    enabled: !isLoading, // Disable input during loading
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                    onSaved: (value) => password = value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading
                  ? null
                  : () => Navigator.pop(dialogContext), // Close on Cancel
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        dialogSetState(() => isLoading = true); // Start loading
                        // Call _payoutInterest without closing the modal
                        _payoutInterest(
                          double.parse(amount!),
                          password!,

                          dialogContext,
                          (loading) => dialogSetState(() =>
                              isLoading = loading), // Update loading state
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: primaryTwo),
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: Loader())
                  : Text('Payout', style: TextStyle(color: white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addInterest(int investmentId, double interest) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      final token = userProfile.first['token'] as String;

      final response = await ApiService.addInvestmentInterest(
        token: token,
        investmentId: investmentId,
        data: {
          'amount': interest,
          'rate': 0, // Placeholder; calculate if needed
          'created': DateTime.now()
              .toIso8601String()
              .split('T')[0]
              .replaceAll('-', ':'),
        },
      );

      if (response['success'] == true) {
        setState(() {
          final index =
              investments.indexWhere((inv) => inv['id'] == investmentId);
          if (index != -1) {
            final currentInterest = double.parse(
              investments[index]['interest']
                  .replaceAll('UGX ', '')
                  .replaceAll(',', ''),
            );
            investments[index]['interest'] =
                'UGX ${(currentInterest + interest).toInt()}';
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Interest added successfully')),
        );
      } else {
        throw Exception(response['error'] ?? 'Failed to add interest');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add interest: $e')),
      );
    }
  }

  Future<void> _cashOut(int investmentId, double amount) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      final token = userProfile.first['token'] as String;

      final response = await ApiService.cashOutInvestment(
        token: token,
        investmentId: investmentId,
        amount: amount,
      );

      if (response['success'] == true) {
        setState(() {
          final index =
              investments.indexWhere((inv) => inv['id'] == investmentId);
          if (index != -1) {
            final currentAmount = double.parse(
              investments[index]['amount']
                  .replaceAll('UGX ', '')
                  .replaceAll(',', ''),
            );
            investments[index]['amount'] =
                'UGX ${(currentAmount - amount).toInt()}';
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cash out successful')),
        );
      } else {
        throw Exception(response['error'] ?? 'Failed to cash out');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cash out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.investmentsData['summary'] ?? {};

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ModernSummaryCard(
              title: 'My Contributions',
              subtitle: 'Your total contributions to the group',
              amount: summary['my_contributions']?['amount'] ?? 'UGX 0',
              usdEquivalent:
                  summary['my_contributions']?['usd_equivalent'] ?? '\$0.00',
              icon: Icons.account_balance_wallet,
              color: primaryTwo,
            ),
            const SizedBox(height: 16),
            ModernSummaryCard(
              title: 'Interest Earned',
              subtitle: 'Your earned interest',
              amount: summary['interest_earned']?['amount'] ?? 'UGX 0',
              usdEquivalent:
                  summary['interest_earned']?['usd_equivalent'] ?? '\$0.00',
              icon: Icons.trending_up,
              color: primaryColor,
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 6,
              shadowColor: Colors.black.withOpacity(0.2),
              child: Container(
                decoration: BoxDecoration(
                  color: white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryTwo.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: primaryTwo.withOpacity(0.1),
                        child:
                            Icon(Icons.bar_chart, color: primaryTwo, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Group Investments',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryTwo,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total investments made by the group',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              summary['group_investments']?['amount'] ??
                                  'UGX 0',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: primaryTwo,
                              ),
                            ),
                            Text(
                              summary['group_investments']?['usd_equivalent'] ??
                                  '\$0.00',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ModernSummaryCard(
              title: 'Total Group Interest',
              subtitle: 'Total interest earned by the group',
              amount: summary['total_group_interest']?['amount'] ?? 'UGX 0',
              usdEquivalent: summary['total_group_interest']
                      ?['usd_equivalent'] ??
                  '\$0.00',
              icon: Icons.group,
              color: primaryTwo,
              actionButton: ElevatedButton.icon(
                onPressed: () => _showPayoutInterestForm(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                ),
                icon: const Icon(Icons.payment, color: Colors.black, size: 18),
                label: const Text(
                  'Pay Out',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Investment List',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryTwo,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All deposits coming in from members are automatically put on a unit trust / mutual fund investment plan. These are investments that you might make elsewhere',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            investments.isEmpty
                ? const Center(
                    child: Text(
                      'No investments available',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : Column(
                    children: investments
                        .map((investment) => ModernInvestmentCard(
                              investment: investment,
                              onAddInterest: (newInterest) {
                                final interestAmount = double.parse(
                                  newInterest
                                      .replaceAll('UGX ', '')
                                      .replaceAll(',', ''),
                                );
                                _addInterest(investment['id'], interestAmount);
                              },
                              onCashOut: (cashOutAmount) {
                                final amount = double.parse(cashOutAmount);
                                _cashOut(investment['id'], amount);
                              },
                            ))
                        .toList(),
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddInvestmentForm(context),
        backgroundColor: primaryTwo,
        child: Icon(Icons.add, color: white),
      ),
    );
  }

  void _showAddInvestmentForm(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String? name;
    String? amount;
    String? interest;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Investment'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Investment Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an investment name';
                    }
                    return null;
                  },
                  onSaved: (value) => name = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Amount (UGX)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  onSaved: (value) => amount = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Interest (UGX)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an interest amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  onSaved: (value) => interest = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                _addInvestment(
                  name!,
                  double.parse(amount!),
                  double.parse(interest!),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryTwo),
            child: Text('Add', style: TextStyle(color: white)),
          ),
        ],
      ),
    );
  }
}

class ModernSummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final String? usdEquivalent;
  final IconData icon;
  final Color color;
  final Widget? actionButton;

  const ModernSummaryCard({
    required this.title,
    required this.subtitle,
    required this.amount,
    this.usdEquivalent,
    required this.icon,
    required this.color,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.2),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: white.withOpacity(0.2),
                    child: Icon(icon, color: white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          amount,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: white,
                          ),
                        ),
                        if (usdEquivalent != null)
                          Text(
                            usdEquivalent!,
                            style: TextStyle(
                              fontSize: 14,
                              color: white.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (actionButton != null) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: actionButton!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ModernInvestmentCard extends StatelessWidget {
  final Map<String, dynamic> investment;
  final Function(String) onAddInterest;
  final Function(String) onCashOut;

  const ModernInvestmentCard({
    required this.investment,
    required this.onAddInterest,
    required this.onCashOut,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.2),
      child: Container(
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryTwo.withOpacity(0.2)),
        ),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: primaryTwo.withOpacity(0.1),
            child: Icon(Icons.bar_chart, color: primaryTwo),
          ),
          title: Text(
            investment['name'],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryTwo,
            ),
          ),
          subtitle: Text(
            'Invested on ${investment['date']}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Investment Amount',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      Text(
                        investment['amount'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryTwo,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Interest Earned',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      Text(
                        investment['interest'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryTwo,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showCashOutForm(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        icon: const Icon(Icons.money,
                            color: Colors.black, size: 18),
                        label: const Text(
                          'Cash Out',
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showAddInterestForm(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTwo,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        icon: const Icon(Icons.add, color: white, size: 18),
                        label: const Text(
                          'Add Interest',
                          style: TextStyle(color: white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddInterestForm(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String? interestAmount;
    String? password;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Interest to ${investment['name']}'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Interest Amount (UGX)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an interest amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  onSaved: (value) => interestAmount = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }

                    return null;
                  },
                  onSaved: (value) => password = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                onAddInterest('UGX $interestAmount');
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryTwo),
            child: Text('Add', style: TextStyle(color: white)),
          ),
        ],
      ),
    );
  }

  void _showCashOutForm(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String? cashOutAmount;
    String? password;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cash Out from ${investment['name']}'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Cash Out Amount (UGX)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a cash out amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  onSaved: (value) => cashOutAmount = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }

                    return null;
                  },
                  onSaved: (value) => password = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                onCashOut(cashOutAmount!);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryTwo),
            child: Text('Cash Out', style: TextStyle(color: white)),
          ),
        ],
      ),
    );
  }
}
