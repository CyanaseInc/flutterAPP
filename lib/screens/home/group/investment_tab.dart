import 'package:cyanase/helpers/loader.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/deposit.dart';
import 'package:cyanase/helpers/withdraw_helper.dart';

class InvestmentsTab extends StatefulWidget {
  final int groupId;
  final bool isAdmin;
  final Map<String, dynamic> investmentsData;

  const InvestmentsTab(
      {Key? key,
      required this.groupId,
      required this.investmentsData,
      required this.isAdmin})
      : super(key: key);

  @override
  _InvestmentsTabState createState() => _InvestmentsTabState();
}

class _InvestmentsTabState extends State<InvestmentsTab> {
  late List<Map<String, dynamic>> investments;

  @override
  void initState() {
    super.initState();
    // Get the initial investments and sort them by date (newest first)
    final initialInvestments = List<Map<String, dynamic>>.from(
        widget.investmentsData['investments'] ?? []);

    // Sort by date in descending order (newest first)
    initialInvestments.sort((a, b) {
      final dateA = DateTime.parse(a['date'] ?? '1970-01-01');
      final dateB = DateTime.parse(b['date'] ?? '1970-01-01');
      return dateB.compareTo(dateA);
    });

    investments = initialInvestments;
  }

  Future<void> _addInvestment(
    String name,
    double amount,
    double interest,
    BuildContext dialogContext,
  ) async {
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
          'rate': (interest / amount * 100).toInt(),
          'status': true,
          'groupid': widget.groupId,
          'created': DateTime.now()
              .toIso8601String()
              .split('T')[0]
              .replaceAll('-', ':'),
        },
      );

      if (response['success'] == true) {
        setState(() {
          // Insert at the beginning of the list instead of adding to the end
          investments.insert(0, {
            'id': response['investment_id'],
            'name': name,
            'amount': 'UGX ${amount.toInt()}',
            'interest': 'UGX ${interest.toInt()}',
            'date': DateTime.now().toIso8601String().split('T')[0],
          });

          // Update group investments total
          final currentGroupInvestment = double.parse(
            widget.investmentsData['summary']?['group_investments']?['amount']
                .replaceAll('UGX ', '')
                .replaceAll(',', ''),
          );
          widget.investmentsData['summary']?['group_investments']?['amount'] =
              'UGX ${(currentGroupInvestment + amount).toInt()}';
        });
        Navigator.pop(dialogContext);
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
    BuildContext dialogContext,
    Function(bool) setLoading,
  ) async {
    try {
      final totalGroupInterestStr = widget.investmentsData['summary']
              ?['total_group_interest']?['amount'] ??
          'UGX 0';
      final totalGroupInterest = double.parse(
          totalGroupInterestStr.replaceAll('UGX ', '').replaceAll(',', ''));

      if (amount > totalGroupInterest) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text(
                'Payout amount (UGX ${amount.toInt()}) exceeds total group interest (UGX ${totalGroupInterest.toInt()})'),
          ),
        );
        setLoading(false);
        return;
      }

      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      final token = userProfile.first['token'] as String;

      final response = await ApiService.payoutInterest(
        token: token,
        groupId: widget.groupId,
        amount: amount,
        password: password,
      );

      if (response['success'] == true) {
        setState(() {
          final newTotal = totalGroupInterest - amount;
          widget.investmentsData['summary']?['total_group_interest']
              ?['amount'] = 'UGX $newTotal';
        });
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          const SnackBar(
              content: Text('Interest payout processed successfully')),
        );
        Navigator.pop(dialogContext);
      } else {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text(response['error'] ?? 'Failed to payout interest'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(content: Text('Failed to payout interest: $e')),
      );
    } finally {
      setLoading(false);
    }
  }

  void _showPayoutInterestForm(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String? amount;
    String? password;
    bool isLoading = false;

    final totalGroupInterestStr = widget.investmentsData['summary']
            ?['total_group_interest']?['amount'] ??
        'UGX 0';
    final totalGroupInterest = double.parse(
        totalGroupInterestStr.replaceAll('UGX ', '').replaceAll(',', ''));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, dialogSetState) => AlertDialog(
          title: const Text(
            ' on th  Group Interest',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      'Interest will be auto-paid to all members based on their group deposit. ',
                      style: TextStyle(fontSize: 15, color: Colors.grey)),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Payout Amount (UGX)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !isLoading,
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
                    enabled: !isLoading,
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
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        dialogSetState(() => isLoading = true);
                        _payoutInterest(
                          double.parse(amount!),
                          password!,
                          dialogContext,
                          (loading) =>
                              dialogSetState(() => isLoading = loading),
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

  Future<void> onDeleteInvestment(
      int investmentId, double amount, String password) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      final token = userProfile.first['token'] as String;

      final response = await ApiService.deleteInvestment(
        token: token,
        investmentId: investmentId,
        password: password,
      );

      if (response['success'] == true) {
        setState(() {
          // Remove the investment
          investments.removeWhere((inv) => inv['id'] == investmentId);
          // Remove the investment
          investments.removeWhere((inv) => inv['id'] == investmentId);

          // Update the group investments total
          final currentGroupInvestment = double.parse(
            widget.investmentsData['summary']?['group_investments']?['amount']
                .replaceAll('UGX ', '')
                .replaceAll(',', ''),
          );
          widget.investmentsData['summary']?['group_investments']?['amount'] =
              'UGX ${(currentGroupInvestment - amount).toInt()}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Investment deleted successfully')),
        );
      } else {
        throw Exception(response['error'] ?? 'Failed to delete investment');
      }
    } catch (e) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete investment: $e')),
      );
    }
  }

  void _showWithdrawForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          "Withdraw Funds",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryTwo,
          ),
        ),
        content: SizedBox(
          height: 400, // Adjust as needed
          child: WithdrawHelper(
            withdrawDetails: "Withdraws are instant",
            withdrawType: "group_subscription_withdraw",
            groupId: widget.groupId,
          ),
        ),
      ),
    );
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
            // New Total Member Subscription Card
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
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: primaryTwo.withOpacity(0.1),
                            child:
                                Icon(Icons.people, color: primaryTwo, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Member Subscription',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: primaryTwo,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Total subscriptions by all members',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  summary['total_member_subscription']
                                          ?['amount'] ??
                                      'UGX 0',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: primaryTwo,
                                  ),
                                ),
                                Text(
                                  summary['total_member_subscription']
                                          ?['usd_equivalent'] ??
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
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (!widget.isAdmin) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Only admin members can withdraw from subscriptions'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } else {
                              _showWithdrawForm(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                !widget.isAdmin ? Colors.grey : Colors.amber,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            elevation: 4,
                          ),
                          icon: Icon(Icons.money_off,
                              color: !widget.isAdmin
                                  ? Colors.grey[600]
                                  : Colors.black,
                              size: 18),
                          label: Text(
                            'Withdraw',
                            style: TextStyle(
                              color: !widget.isAdmin
                                  ? Colors.grey[600]
                                  : Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                onPressed: !widget.isAdmin
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Only admin members can payout interest'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    : () => _showPayoutInterestForm(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: !widget.isAdmin ? Colors.grey : Colors.amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                ),
                icon: Icon(Icons.payment,
                    color: !widget.isAdmin ? Colors.grey[600] : Colors.black,
                    size: 18),
                label: Text(
                  'Pay Out',
                  style: TextStyle(
                    color: !widget.isAdmin ? Colors.grey[600] : Colors.black,
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
                              onAddInterest: (newInterest, password) {
                                final interestAmount = double.parse(
                                  newInterest
                                      .replaceAll('UGX ', '')
                                      .replaceAll(',', ''),
                                );
                                setState(() {
                                  final index = investments.indexWhere(
                                      (inv) => inv['id'] == investment['id']);
                                  if (index != -1) {
                                    final currentInterest = double.parse(
                                      investments[index]['interest']
                                          .replaceAll('UGX ', '')
                                          .replaceAll(',', ''),
                                    );
                                    investments[index]['interest'] =
                                        'UGX ${(currentInterest + interestAmount).toInt()}';
                                  }
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Interest added successfully')),
                                );
                              },
                              onDeleteInvestment:
                                  (investmentId, amount, password) {
                                onDeleteInvestment(
                                    investmentId, amount, password);
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

    // Removed unused and incorrectly declared variable
    bool isLoading = false; // Add this loading state variable

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing while loading
      builder: (context) => StatefulBuilder(
        // Use StatefulBuilder to update the dialog state
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add New Investment',
                style: TextStyle(fontSize: 18)),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Investment Name',
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: primaryTwo),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an investment name';
                        }
                        return null;
                      },
                      onSaved: (value) => name = value,
                      enabled: !isLoading, // Disable when loading
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Amount (UGX)',
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: primaryTwo),
                        ),
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
                      enabled: !isLoading, // Disable when loading
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Interest (%)',
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: primaryTwo),
                        ),
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
                      enabled: !isLoading, // Disable when loading
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          setState(() => isLoading = true); // Show loading

                          try {
                            await _addInvestment(
                              name!,
                              double.parse(amount!),
                              double.parse(interest!),
                              context,
                            );
                          } catch (e) {
                            setState(() =>
                                isLoading = false); // Hide loading on error
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Failed to add investment: $e')),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: primaryTwo),
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: Loader(), // Show loader when loading
                      )
                    : Text('Add', style: TextStyle(color: white)),
              ),
            ],
          );
        },
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
  final Function(String, String) onAddInterest;
  final Function(int, double, String) onDeleteInvestment;

  const ModernInvestmentCard({
    required this.investment,
    required this.onAddInterest,
    required this.onDeleteInvestment,
  });

  void _showAddInterestForm(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Interest ',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 400,
                child: DepositHelper(
                  depositCategory: "group_investment_interest",
                  selectedFundClass: investment['name'],
                  selectedOption: "Interest",
                  selectedFundManager: "Group Investment",
                  selectedOptionId: investment['id'],
                  detailText: "Add interest ",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                        onPressed: () => _showDeleteForm(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        icon: const Icon(Icons.delete,
                            color: Colors.black, size: 18),
                        label: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showAddInterestForm(
                          context,
                        ),
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

  void _showDeleteForm(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String? confirmationAmount;
    String? password;

    // Declare isLoading here so it's preserved across state updates
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Delete ${investment['name']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'WARNING: This will permanently remove the investment from group records...',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Confirm Investment Amount (UGX)',
                          border: UnderlineInputBorder(),
                          prefixIcon: Icon(Icons.money),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm the investment amount';
                          }
                          final parsedValue = double.tryParse(value);
                          if (parsedValue == null)
                            return 'Enter a valid number';
                          final investmentAmount = double.parse(
                            investment['amount']
                                .replaceAll('UGX ', '')
                                .replaceAll(',', ''),
                          );
                          if (parsedValue != investmentAmount) {
                            return 'Amount does not match investment (UGX $investmentAmount)';
                          }
                          return null;
                        },
                        onSaved: (value) => confirmationAmount = value,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: UnderlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        onSaved: (value) => password = value,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel',
                                  style: TextStyle(color: Colors.grey)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      if (_formKey.currentState!.validate()) {
                                        _formKey.currentState!.save();
                                        setModalState(() => isLoading = true);
                                        try {
                                          final amount = double.parse(
                                            investment['amount']
                                                .replaceAll('UGX ', '')
                                                .replaceAll(',', ''),
                                          );
                                          await onDeleteInvestment(
                                            investment['id'],
                                            amount,
                                            password!,
                                          );
                                          Navigator.pop(
                                              context); // Optional: close after delete
                                        } catch (e) {
                                          // Handle error or show dialog
                                        } finally {
                                          setModalState(
                                              () => isLoading = false);
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Confirm Deletion',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
