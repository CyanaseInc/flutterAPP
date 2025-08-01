//import 'package:cyanase/helpers/web_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'goal_screen.dart'; // Import the modified GoalScreen
import 'add_goal.dart'; // Ensure this is implemented
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'dart:convert';
import 'dart:io';

class GoalsTab extends StatefulWidget {
  const GoalsTab({Key? key}) : super(key: key);

  @override
  _GoalsTabState createState() => _GoalsTabState();
}

class _GoalsTabState extends State<GoalsTab> {
  bool isLoading = true;
  List<Map<String, dynamic>> goals = [];
  double totalDeposit = 0.0;

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

      // await WebSharedStorage.init();
      // // var existingProfile = WebSharedStorage();
      // // final token = existingProfile.getCommon('token');

      // // Fetch goals from the API
      final Map<String, dynamic> response =
          await ApiService.getAllUserGoals(token);

          

      // Check if response contains goals, regardless of success field
      if (response.containsKey('goals') && response['goals'] is List) {
        final List<dynamic> goalList = response['goals'] as List<dynamic>;
        final List<Map<String, dynamic>> fetchedGoals = goalList
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        setState(() {
          goals = fetchedGoals;
          isLoading = false;
          totalDeposit = (response['total_deposit'] as num?)?.toDouble() ?? 0.0;
          // Optionally, store summary fields here if you want to use them
          // totalDeposit = response['total_deposit'];
          // totalWithdraw = response['total_withdraw'];
          // overallNet = response['overall_net'];
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
      
      if (Platform.isIOS) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to load goals'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load goals')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? CupertinoPageScaffold(
            backgroundColor: white,
            child: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: GoalScreen(
                          goals: goals,
                          isLoading: isLoading,
                          totalDeposit: totalDeposit,
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: CupertinoButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddGoalScreen()),
                        ).then((_) {
                          fetchGoalData();
                        });
                      },
                      padding: EdgeInsets.zero,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: primaryTwo,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.add,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : Scaffold(
            backgroundColor: white,
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: GoalScreen(
                      goals: goals,
                      isLoading: isLoading,
                      totalDeposit: totalDeposit,
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
