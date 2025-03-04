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

      // Fetch goals from the API
      final response = await ApiService.getAllUserGoals(token);

      // Check if the response is successful
      if (response.statusCode == 200) {
        // Decode the response body into a Map<String, dynamic>
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

        // Extract the 'goal' list from the response
        if (responseBody.containsKey('goal') && responseBody['goal'] is List) {
          final List<dynamic> goalList = responseBody['goal'] as List<dynamic>;
          final List<Map<String, dynamic>> fetchedGoals = goalList
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
      } else {
        throw Exception('Failed to fetch goals: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
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

    return Column(
      children: goals.map((goal) => _buildGoalCard(goal)).toList(),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    double progress = 0.0;
    if (goal['deposit'] != null && goal['deposit'].isNotEmpty) {
      final deposits = (goal['deposit'] as List)
          .map((d) => double.tryParse(d.toString()) ?? 0.0);
      final totalDeposits = deposits.reduce((a, b) => a + b);
      progress = totalDeposits / (goal['goal_amount'] as num);
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
                        image: NetworkImage(goal['goal_picture'] as String),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) =>
                            const AssetImage('assets/default_goal.jpg'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      goal['goal_name'] as String,
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
                'Goal: ${(goal['goal_amount'] as num).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                'Period: ${goal['goal_period']} years',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Created: ${goal['created']}',
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
