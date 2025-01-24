import 'package:flutter/material.dart';
import 'goal_screen.dart'; // Ensure this is implemented
import 'add_goal.dart'; // Ensure this is implemented
import 'package:cyanase/theme/theme.dart';

class GoalsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white, // Set the background color to white
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GoalScreen(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Add Goal screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddGoalScreen(), // Replace with the correct screen
            ),
          );
        },
        child: Icon(
          Icons.add,
          color: primaryColor, // Set the plus sign to white
        ),
        backgroundColor: primaryTwo, // Background color of the button
      ),
    );
  }
}

// Stub for AddGoalScreen to avoid errors. Replace with your actual implementation.
