import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

/// Primary balance card on the Invest home tab.
class PortfolioHeroCard extends StatelessWidget {
  final String currency;
  final String networthLocal;
  final String networthForeign;
  final String depositLocal;
  final String depositForeign;
  final VoidCallback? onPortfolioTap;

  const PortfolioHeroCard({
    super.key,
    required this.currency,
    required this.networthLocal,
    required this.networthForeign,
    required this.depositLocal,
    required this.depositForeign,
    this.onPortfolioTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryTwo, Color(0xFF1A1E42)],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryTwo.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.12),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -50,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: white.withOpacity(0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.45),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 14,
                              color: primaryColor,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Portfolio value',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (onPortfolioTap != null)
                        TextButton.icon(
                          onPressed: onPortfolioTap,
                          icon: const Icon(
                            Icons.pie_chart_outline,
                            size: 16,
                            color: white,
                          ),
                          label: const Text(
                            'Details',
                            style: TextStyle(
                              color: white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _amountRow(currency, networthLocal, 34),
                  const SizedBox(height: 4),
                  Text(
                    '≈ \$ $networthForeign USD',
                    style: TextStyle(
                      color: white.withOpacity(0.72),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    height: 1,
                    color: white.withOpacity(0.12),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _statChip(
                          label: 'Total invested',
                          value: depositLocal,
                          currency: currency,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: white.withOpacity(0.15),
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      Expanded(
                        child: _statChip(
                          label: 'USD equivalent',
                          value: depositForeign,
                          currency: '\$',
                          prefixOnly: true,
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

  Widget _amountRow(String currency, String amount, double size) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$currency ',
            style: TextStyle(
              fontSize: size * 0.45,
              fontWeight: FontWeight.w600,
              color: white.withOpacity(0.85),
            ),
          ),
          TextSpan(
            text: amount,
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w700,
              color: white,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip({
    required String label,
    required String value,
    required String currency,
    bool prefixOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: white.withOpacity(0.65),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          prefixOnly ? '\$ $value' : '$currency $value',
          style: const TextStyle(
            color: white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Growth / returns summary below the hero card.
class NetworthInsightCard extends StatelessWidget {
  final String currency;
  final String networthLocal;
  final String networthForeign;
  final double? growthPercent;

  const NetworthInsightCard({
    super.key,
    required this.currency,
    required this.networthLocal,
    required this.networthForeign,
    this.growthPercent,
  });

  String get _growthLabel {
    if (growthPercent == null) return '—';
    final p = growthPercent!;
    final sign = p >= 0 ? '+' : '';
    return '$sign${p.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    final pct = growthPercent ?? 0;
    final isUp = pct >= 0;
    final badgeBg =
        isUp ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final badgeFg =
        isUp ? const Color(0xFF2E7D32) : const Color(0xFFC62828);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: surfaceMutedBorder.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: primaryTwo.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: primaryTwo,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Investment growth',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$currency $networthLocal',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: primaryTwo,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUp ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                      color: badgeFg,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _growthLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: badgeFg,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '≈ \$ $networthForeign',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
