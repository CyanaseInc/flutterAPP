import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';

class InvestmentsTab extends StatefulWidget {
  @override
  _InvestmentsTabState createState() => _InvestmentsTabState();
}

class _InvestmentsTabState extends State<InvestmentsTab> {
  // Sample investment data (can be replaced with API data)
  List<Map<String, dynamic>> investments = [
    {
      'id': 1,
      'name': 'Real Estate Fund',
      'amount': 'UGX 15,000,000,000',
      'interest': 'UGX 1,500,000,000',
      'date': '2024-01-15',
    },
    {
      'id': 2,
      'name': 'Tech Startup',
      'amount': 'UGX 10,000,000,000',
      'interest': 'UGX 800,000,000',
      'date': '2024-03-10',
    },
  ];

  // Sample total group interest (for demo purposes, can be computed or fetched from API)
  String totalGroupInterest = 'UGX 25,000,000';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ModernSummaryCard(
              title: 'My Contributions',
              subtitle: 'Your total contributions to the group',
              amount: '\$12,900,345',
              icon: Icons.account_balance_wallet,
              color: primaryTwo,
            ),
            SizedBox(height: 16),
            ModernSummaryCard(
              title: 'Interest Earned',
              subtitle: 'Your earned interest',
              amount: '\$1,234.56',
              icon: Icons.trending_up,
              color: primaryColor,
            ),
            SizedBox(height: 16),
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
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: primaryTwo.withOpacity(0.1),
                        child:
                            Icon(Icons.bar_chart, color: primaryTwo, size: 28),
                      ),
                      SizedBox(width: 16),
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
                            SizedBox(height: 4),
                            Text(
                              'Total investments made by the group',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'UGX 3,005,000',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: primaryTwo,
                              ),
                            ),
                            Text(
                              '\$13.50',
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
            SizedBox(height: 16),
            ModernSummaryCard(
              title: 'Total Group Interest',
              subtitle: 'Total interest earned by the group',
              amount: totalGroupInterest,
              usdEquivalent: '\$130.50',
              icon: Icons.group,
              color: primaryTwo,
              actionButton: ElevatedButton.icon(
                onPressed: () => _showPayoutInterestForm(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                ),
                icon: Icon(Icons.payment, color: Colors.black, size: 18),
                label: Text(
                  'Pay Out',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Investment List',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryTwo,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'All deposits coming in from members are automatically put on a unit trust / mutual fund investment plan. These are investments that you might make elsewhere',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            ...investments
                .map((investment) => ModernInvestmentCard(
                      investment: investment,
                      onAddInterest: (String newInterest) {
                        setState(() {
                          investment['interest'] = newInterest;
                        });
                      },
                      onCashOut: (String cashOutAmount) {
                        setState(() {
                          // Placeholder: Reduce investment amount
                          double currentAmount = double.parse(
                              investment['amount']
                                  .replaceAll('UGX ', '')
                                  .replaceAll(',', ''));
                          double cashOut = double.parse(cashOutAmount);
                          if (cashOut <= currentAmount) {
                            investment['amount'] =
                                'UGX ${(currentAmount - cashOut).toStringAsFixed(0)}';
                          }
                        });
                      },
                    ))
                .toList(),
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
        title: Text('Add New Investment'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(
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
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
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
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
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
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                setState(() {
                  investments.add({
                    'id': investments.length + 1,
                    'name': name!,
                    'amount': 'UGX $amount',
                    'interest': 'UGX $interest',
                    'date': DateTime.now().toIso8601String().split('T')[0],
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Investment added successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryTwo),
            child: Text('Add', style: TextStyle(color: white)),
          ),
        ],
      ),
    );
  }

  void _showPayoutInterestForm(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String? amount;
    String? password;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pay Out Group Interest'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Payout Amount (UGX)',
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
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
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
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                setState(() {
                  double currentInterest = double.parse(totalGroupInterest
                      .replaceAll('UGX ', '')
                      .replaceAll(',', ''));
                  double payoutAmount = double.parse(amount!);
                  if (payoutAmount <= currentInterest) {
                    totalGroupInterest =
                        'UGX ${(currentInterest - payoutAmount).toStringAsFixed(0)}';
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Interest payout processed successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryTwo),
            child: Text('Payout', style: TextStyle(color: white)),
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
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: white.withOpacity(0.2),
                    child: Icon(icon, color: white, size: 28),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: white.withOpacity(0.8),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          amount,
                          style: TextStyle(
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
                SizedBox(height: 16),
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
              padding: EdgeInsets.all(16),
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
                  SizedBox(height: 8),
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
                  SizedBox(height: 16),
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
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        icon: Icon(Icons.money, color: Colors.black, size: 18),
                        label: Text(
                          'Cash Out',
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showAddInterestForm(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTwo,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        icon: Icon(Icons.add, color: white, size: 18),
                        label: Text(
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
                  decoration: InputDecoration(
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
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
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
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                onAddInterest('UGX $interestAmount');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Interest added to ${investment['name']} successfully')),
                );
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
        title: Text(
          'Cash Out from ${investment['name']}',
          style: TextStyle(
            color: primaryTwo,
            fontSize: 14,
          ),
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(
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
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
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
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                onCashOut(cashOutAmount!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Cash out from ${investment['name']} successful')),
                );
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
