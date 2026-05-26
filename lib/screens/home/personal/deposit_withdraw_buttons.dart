import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import '../../../theme/theme.dart';
import 'package:cyanase/helpers/invest_navigation.dart';
import '../componets/investment_withdraw.dart';

class DepositWithdrawButtons extends StatelessWidget {
  const DepositWithdrawButtons({super.key});

  static const double buttonHeight = 48;
  static const double _buttonHeight = buttonHeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Invest',
            icon: Icons.add_rounded,
            filled: true,
            onPressed: () => ensureInvestAllowed(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            label: 'Withdraw',
            icon: Icons.arrow_outward_rounded,
            filled: false,
            onPressed: () {
              final route = Platform.isIOS
                  ? CupertinoPageRoute(builder: (_) => Withdraw())
                  : MaterialPageRoute(builder: (_) => Withdraw());
              Navigator.push(context, route);
            },
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: filled ? primaryTwo : primaryTwo),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: filled ? primaryTwo : primaryTwo,
          ),
        ),
      ],
    );

    if (filled) {
      return SizedBox(
        height: DepositWithdrawButtons._buttonHeight,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [primaryColor, Color(0xFFE5A800)],
                ),
              ),
              child: Center(child: child),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: DepositWithdrawButtons._buttonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTwo,
          backgroundColor: white,
          padding: EdgeInsets.zero,
          minimumSize: const Size.fromHeight(
            DepositWithdrawButtons._buttonHeight,
          ),
          side: BorderSide(color: primaryTwo.withOpacity(0.28), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: child,
      ),
    );
  }
}
