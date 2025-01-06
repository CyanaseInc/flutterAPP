import 'package:app/theme/theme.dart';
import 'package:flutter/material.dart';

class SampleGoals extends StatelessWidget {
  final List<Map<String, dynamic>> goals = [
    {'name': 'Vacation Savings', 'progress': 0.7, 'amountSaved': '\$7,000'},
    {'name': 'Emergency Fund', 'progress': 0.5, 'amountSaved': '\$5,000'},
    {'name': 'New Car Fund', 'progress': 0.2, 'amountSaved': '\$2,000'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row for Title Text and Button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title Text
              Text(
                'Savings Goals',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // "See More Goals" Button
              TextButton(
                onPressed: () {
                  // Handle "See More Goals" action
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8), // Adjust padding
                  backgroundColor:
                      Colors.transparent, // Make the background transparent
                  side: BorderSide(
                      color: primaryTwo,
                      width: 1), // Set border color and width
                ),
                child: Text(
                  'More goals',
                  style: TextStyle(
                    color: primaryTwo, // Set text color to primary color
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Goal Cards
        Expanded(
          child: ListView(
            children: goals.map((goal) => _buildGoalCard(goal)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goal['name'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: goal['progress'],
              backgroundColor: Colors.grey[300],
              color: Colors.green,
            ),
            SizedBox(height: 8),
            Text(
              'Amount Saved: ${goal['amountSaved']}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
