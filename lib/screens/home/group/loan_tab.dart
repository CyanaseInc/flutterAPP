import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';

class LoansTab extends StatelessWidget {
  final int groupId;
  final Map<String, dynamic> loansData;

  const LoansTab({Key? key, required this.groupId, required this.loansData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final summary = loansData['summary'] ?? {};
    final loans = List<Map<String, dynamic>>.from(loansData['loans'] ?? []);

    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FintechSummaryCard(
                title: 'Ongoing Loans',
                subtitle: 'Total loans currently being repaid',
                amount: summary['ongoing_loans']?['amount'] ?? 'UGX 0',
                usdEquivalent:
                    summary['ongoing_loans']?['usd_equivalent'] ?? '\$0.00',
                icon: Icons.money_off,
                color: primaryTwo,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FintechSummaryCard(
                title: 'Loans Before Interest',
                subtitle: 'Sum of all outstanding loans before',
                amount: summary['loans_before_interest']?['amount'] ?? 'UGX 0',
                usdEquivalent: summary['loans_before_interest']
                        ?['usd_equivalent'] ??
                    '\$0.00',
                icon: Icons.account_balance,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
            const SizedBox(height: 12),
            loans.isEmpty
                ? const Center(
                    child: Text(
                      'No loans available',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : Column(
                    children: loans
                        .map((loan) => FintechLoanCard(loan: loan))
                        .toList(),
                  ),
            const SizedBox(height: 24),
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
  final Color color;

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
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.15),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                offset: const Offset(-5, -5),
                blurRadius: 10,
              ),
              BoxShadow(
                color: primaryTwo.withOpacity(0.2),
                offset: const Offset(5, 5),
                blurRadius: 10,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: white.withOpacity(0.3),
                  child: Icon(icon, color: white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: white.withOpacity(0.85),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        amount,
                        style: const TextStyle(
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                offset: const Offset(-3, -3),
                blurRadius: 8,
              ),
              BoxShadow(
                color: primaryTwo.withOpacity(0.15),
                offset: const Offset(3, 3),
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
              style: const TextStyle(
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
                padding: const EdgeInsets.all(16),
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
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryTwo,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryTwo,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Repayment Progress',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: loan['progress'],
                      backgroundColor: Colors.grey[200],
                      color: primaryTwo,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(loan['progress'] * 100).toStringAsFixed(0)}% Repaid',
                      style: const TextStyle(
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
