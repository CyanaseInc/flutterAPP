import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/screens/home/componets/investment_deposit.dart';
import 'package:cyanase/screens/home/personal/personal_investment_policy_screen.dart';
import 'package:flutter/material.dart';

/// Checks Django investment-policy completeness, then opens [Deposit].
Future<void> ensureInvestAllowed(
  BuildContext context, {
  int? initialInvestmentClassId,
  int? initialInvestmentOptionId,
}) async {
  try {
    final db = await DatabaseHelper().database;
    final rows = await db.query('profile', limit: 1);
    if (rows.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to invest')),
        );
      }
      return;
    }
    final token = (rows.first['token'] as String?)?.trim() ?? '';
    if (token.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to invest')),
        );
      }
      return;
    }

    Map<String, dynamic> status;
    try {
      status = await ApiService.getInvestmentPolicyStatus(token);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not verify investment profile: $e')),
        );
      }
      return;
    }

    var complete = status['complete'] == true;
    if (!complete) {
      if (!context.mounted) return;
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => const PersonalInvestmentPolicyScreen(),
        ),
      );
      if (saved != true) return;
      if (!context.mounted) return;
      try {
        status = await ApiService.getInvestmentPolicyStatus(token);
        complete = status['complete'] == true;
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not verify investment profile: $e')),
          );
        }
        return;
      }
      if (!complete) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Your investment profile is still incomplete. Please fill all fields.',
              ),
            ),
          );
        }
        return;
      }
    }

    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => Deposit(
          initialInvestmentClassId: initialInvestmentClassId,
          initialInvestmentOptionId: initialInvestmentOptionId,
        ),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start invest flow: $e')),
      );
    }
  }
}
