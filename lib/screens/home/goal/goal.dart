import 'package:cyanase/helpers/web_db.dart';
import 'package:flutter/material.dart';
import 'goal_screen.dart'; // Import the modified GoalScreen
import 'add_goal.dart'; // Ensure this is implemented
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'dart:convert';

class GoalsTab extends StatefulWidget {
  const GoalsTab({Key? key}) : super(key: key);

  @override
  _GoalsTabState createState() => _GoalsTabState();
}

class _GoalsTabState extends State<GoalsTab> {
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
    return Scaffold(
      backgroundColor: white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GoalScreen(
                goals: goals,
                isLoading: isLoading,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddGoalScreen()),
          ).then((_) {
            // Refresh goals after adding a new one
            fetchGoalData();
          });
        },
        backgroundColor: primaryTwo,
        child: const Icon(
          Icons.add,
          color: primaryColor,
        ),
      ),
    );
  }
}
