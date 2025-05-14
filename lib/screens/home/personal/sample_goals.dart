import 'package:cyanase/helpers/web_db.dart';
import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';
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

      await WebSharedStorage.init();
      // var existingProfile = WebSharedStorage();
      // final token = existingProfile.getCommon('token');

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
        print('Fetched goals: $goals');
      } else {
        setState(() {
          isLoading = false;
        });
        print('No goals found in response or invalid format');
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
      final goalAmount = (goal['goal_amount'] as num?)?.toDouble() ??
          1.0; // Avoid division by zero
      if (goalAmount > 0) {
        progress = totalDeposits / goalAmount;
      }
    }

    return GestureDetector(
      onTap: widget.onGoalTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image:
                            NetworkImage(goal['goal_picture'] as String? ?? ''),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) =>
                            const AssetImage('assets/default_goal.jpg'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      goal['goal_name'] as String? ?? 'Unnamed Goal',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[300],
                color: primaryTwo,
              ),
              const SizedBox(height: 8),
              Text(
                'Goal: ${(goal['goal_amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                'Period: ${goal['goal_period']?.toString() ?? 'N/A'} years',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Created: ${goal['created']?.toString() ?? 'N/A'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
