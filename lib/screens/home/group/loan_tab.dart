import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';

class LoansTab extends StatelessWidget {
  // Sample loan data (replace with API data)
  final List<Map<String, dynamic>> loans = [
    {
      'member': 'John Doe',
      'loanAmount': 5000000,
      'daysLeft': 45,
      'repaymentAmount': 5500000,
      'progress': 0.4, // 40% repaid
    },
    {
      'member': 'Jane Smith',
      'loanAmount': 3000000,
      'daysLeft': 30,
      'repaymentAmount': 3300000,
      'progress': 0.6, // 60% repaid
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: Colors.white, // Changed from gradient to solid white
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: FintechSummaryCard(
                title: 'Ongoing Loans',
                subtitle: 'Total loans currently being repaid',
                amount: 'UGX 5,000',
                usdEquivalent: '\$130.50',
                icon: Icons.money_off,
                color: primaryTwo, // Changed from gradient to solid color
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: FintechSummaryCard(
                title: ' Loans Before Interest',
                subtitle: 'Sum of all outstanding loans before',
                amount: 'UGX 8,000,000',
                usdEquivalent: '\$2,000',
                icon: Icons.account_balance,
                color: primaryColor, // Changed from gradient to solid color
              ),
            ),
            SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Loan Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryTwo,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(height: 12),
            ...loans.map((loan) => FintechLoanCard(loan: loan)).toList(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class FintechSummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final String? usdEquivalent;
  final IconData icon;
  final Color color; // Changed from gradientColors to single color

  const FintechSummaryCard({
    required this.title,
    required this.subtitle,
    required this.amount,
    this.usdEquivalent,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.15),
        child: Container(
          decoration: BoxDecoration(
            color: color, // Changed from gradient to solid color
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                offset: Offset(-5, -5),
                blurRadius: 10,
              ),
              BoxShadow(
                color: primaryTwo.withOpacity(0.2),
                offset: Offset(5, 5),
                blurRadius: 10,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: white.withOpacity(0.3),
                  child: Icon(icon, color: white, size: 32),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: white.withOpacity(0.85),
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        amount,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (usdEquivalent != null)
                        Text(
                          usdEquivalent!,
                          style: TextStyle(
                            fontSize: 10,
                            color: white.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
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
    );
  }
}

class FintechLoanCard extends StatelessWidget {
  final Map<String, dynamic> loan;

  const FintechLoanCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                offset: Offset(-3, -3),
                blurRadius: 8,
              ),
              BoxShadow(
                color: primaryTwo.withOpacity(0.15),
                offset: Offset(3, 3),
                blurRadius: 8,
              ),
            ],
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: primaryTwo.withOpacity(0.1),
              child: Icon(Icons.person, color: primaryTwo, size: 24),
            ),
            title: Text(
              loan['member'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: primaryTwo,
                letterSpacing: 0.3,
              ),
            ),
            subtitle: Text(
              'Loan: UGX ${loan['loanAmount'].toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                letterSpacing: 0.2,
              ),
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
                          'Days Left',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            letterSpacing: 0.2,
                          ),
                        ),
                        Text(
                          '${loan['daysLeft']} days',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryTwo,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Repayment Amount',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            letterSpacing: 0.2,
                          ),
                        ),
                        Text(
                          'UGX ${loan['repaymentAmount'].toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryTwo,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Repayment Progress',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: loan['progress'],
                      backgroundColor: Colors.grey[200],
                      color: primaryTwo,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${(loan['progress'] * 100).toStringAsFixed(0)}% Repaid',
                      style: TextStyle(
                        fontSize: 12,
                        color: primaryTwo,
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
    );
  }
}
