import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:intl/intl.dart';

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
                subtitle: 'Total loans ongoing',
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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FintechSummaryCard(
                title: 'Interest from loan',
                subtitle: 'Interest earned from paid loans',
                amount: summary['total_group_interest_from_loans']?['amount'] ??
                    'UGX 0',
                usdEquivalent: summary['total_group_interest_from_loans']
                        ?['usd_equivalent'] ??
                    '\$0.00',
                icon: Icons.account_balance,
                color: Colors.white,
                borderColor: primaryTwo,
                textColor: primaryTwo,
                iconColor: primaryTwo,
              ),
            ),
            const SizedBox(height: 16),
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
                        .asMap()
                        .entries
                        .map((entry) => FintechLoanCard(
                              loan: entry.value,
                              index: entry.key,
                            ))
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
  final Color? borderColor;
  final Color? textColor;
  final Color? iconColor;

  const FintechSummaryCard({
    required this.title,
    required this.subtitle,
    required this.amount,
    this.usdEquivalent,
    required this.icon,
    required this.color,
    this.borderColor,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: borderColor != null
              ? BorderSide(color: borderColor!, width: 2)
              : BorderSide.none,
        ),
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
                  backgroundColor: iconColor != null
                      ? iconColor!.withOpacity(0.3)
                      : white.withOpacity(0.3),
                  child: Icon(
                    icon,
                    color: iconColor ?? white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textColor ?? white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor != null
                              ? textColor!.withOpacity(0.85)
                              : white.withOpacity(0.85),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        amount,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor ?? white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (usdEquivalent != null)
                        Text(
                          usdEquivalent!,
                          style: TextStyle(
                            fontSize: 10,
                            color: textColor != null
                                ? textColor!.withOpacity(0.7)
                                : white.withOpacity(0.7),
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
  final int index;

  const FintechLoanCard({required this.loan, required this.index});

  @override
  Widget build(BuildContext context) {
    final loanAmount = (loan['loanAmount'] as num?)?.toDouble() ?? 0.0;
    final phoneNumber = loan['phone_number'];
    final repaymentAmount =
        (loan['repaymentAmount'] as num?)?.toDouble() ?? 0.0;
    final interestRate = loanAmount > 0
        ? ((repaymentAmount - loanAmount) / loanAmount) * 100
        : 0.0;
    final daysLeft = (loan['daysLeft'] as num?)?.toInt() ?? 0;
    final progress = (loan['progress'] as num?)?.toDouble() ?? 0.0;
    final createdAt = loan['created_at'] != null
        ? DateTime.tryParse(loan['created_at'] as String) ?? DateTime.now()
        : DateTime.now().subtract(Duration(days: daysLeft + 60));
    final repaymentPeriod = (loan['repayment_period'] as num?)?.toInt() ?? 60;
    final dueDate = createdAt.add(Duration(days: repaymentPeriod));
    final amountPaid = loan['amount_paid'] != null
        ? (loan['amount_paid'] as num?)?.toDouble() ?? 0.0
        : progress * repaymentAmount;
    final outstandingBalance = loan['outstanding_balance'] != null
        ? (loan['outstanding_balance'] as num?)?.toDouble() ?? 0.0
        : repaymentAmount - amountPaid;

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
              loan['member'] ?? 'Unknown Member',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: primaryTwo,
                letterSpacing: 0.3,
              ),
            ),
            subtitle: Text(
              '$phoneNumber',
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
                    _buildDetailRow(
                      'Loan Amount',
                      NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0)
                          .format(loanAmount),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Repayment Amount',
                      NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0)
                          .format(repaymentAmount),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Interest Rate',
                      '${interestRate.toStringAsFixed(2)}%',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Issue Date',
                      DateFormat('MMM dd, yyyy').format(createdAt),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Due Date',
                      DateFormat('MMM dd, yyyy').format(dueDate),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Days Left',
                      '$daysLeft days',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Amount Paid',
                      NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0)
                          .format(amountPaid),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Outstanding Balance',
                      NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0)
                          .format(outstandingBalance),
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
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      color: primaryTwo,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}% Repaid',
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            letterSpacing: 0.2,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: primaryTwo,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

double parseCurrencyAmount(String amountStr) {
  final cleanAmount = amountStr
      .replaceAll(RegExp(r'[A-Z]{3}\s*'), '')
      .replaceAll(' ', '')
      .replaceAll(',', '');
  return double.parse(cleanAmount);
}
