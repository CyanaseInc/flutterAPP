import 'package:cyanase/helpers/endpoints.dart';
import 'package:cyanase/helpers/web_db.dart';
import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/get_currency.dart';
import 'dart:convert';

class SampleGoals extends StatefulWidget {
  final VoidCallback onGoalTap;

  const SampleGoals({required this.onGoalTap, Key? key}) : super(key: key);

  @override
  _SampleGoalsState createState() => _SampleGoalsState();
}

class _SampleGoalsState extends State<SampleGoals> {
  bool isLoading = true;
  List<Map<String, dynamic>> goals = [];
  String currency = '';

  @override
  void initState() {
    super.initState();
    fetchGoalData();
  }

  Future<void> fetchGoalData() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);

      if (userProfile.isEmpty) {
        throw Exception('No user profile found');
      }

      final token = userProfile.first['token'] as String;
      final userCountry = userProfile.first['country'] as String;
      final currencyCode = CurrencyHelper.getCurrencyCode(userCountry);

      setState(() {
        currency = currencyCode;
      });

      // Fetch goals from the API
      final Map<String, dynamic> response =
          await ApiService.getAllUserGoals(token);

      // Check if response contains goals, regardless of success field
      if (response.containsKey('goal') && response['goal'] is List) {
        final List<dynamic> goalList = response['goal'] as List<dynamic>;
        final List<Map<String, dynamic>> fetchedGoals = goalList
            .take(2) // Limit to the first two goals
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        setState(() {
          goals = fetchedGoals;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching goals: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load goals: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (goals.isEmpty) {
      return const Center(
        child: Text(
          'No goals found',
          style: TextStyle(fontSize: 16, color: primaryTwo),
        ),
      );
    }

    return ListView(
      children: goals.map((goal) => _buildGoalCard(goal)).toList(),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {

    
    double progress = 0.0;
    if (goal['deposit'] != null && (goal['deposit'] as List).isNotEmpty) {
      final deposits = (goal['deposit'] as List)
          .map((d) => double.tryParse(d.toString()) ?? 0.0)
          .toList();
      final totalDeposits = deposits.reduce((a, b) => a + b);
      final goalAmount = (goal['goal_amount'] as num?)?.toDouble() ?? 1.0;
      if (goalAmount > 0) {
        progress = totalDeposits / goalAmount;
      }
    }

    return GestureDetector(
      onTap: widget.onGoalTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      image: DecorationImage(
                        image: NetworkImage(ApiEndpoints.server + '/' + (goal['goal_picture'] as String? ?? '')),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) =>
                            const AssetImage('assets/default_goal.jpg'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal['goal_name'] as String? ?? 'Unnamed Goal',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created ${goal['created']?.toString() ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Goal Amount',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$currency ${(goal['goal_amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryTwo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[200],
                  color: primaryTwo,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Period',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${goal['goal_period']?.toString() ?? 'N/A'} years',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
