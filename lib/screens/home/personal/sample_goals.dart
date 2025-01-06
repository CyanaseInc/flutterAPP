import 'package:flutter/material.dart';
import '../../../theme/theme.dart'; // Assuming your theme file has primaryTwo defined

class SampleGoals extends StatelessWidget {
  final List<Map<String, dynamic>> goals = [
    {'name': 'Vacation Savings', 'progress': 0.7, 'amountSaved': '\$7,000'},
    {'name': 'Emergency Fund', 'progress': 0.5, 'amountSaved': '\$5,000'},
    {'name': 'New Car Fund', 'progress': 0.2, 'amountSaved': '\$2,000'},
  ];

  final VoidCallback onGoalTap;

  SampleGoals({required this.onGoalTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: goals.map((goal) => _buildGoalCard(goal)).toList(),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    return GestureDetector(
      onTap: onGoalTap, // Navigate to the Goals tab on tap
      child: Card(
        margin: const EdgeInsets.only(bottom: 16.0),
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: goal['progress'],
                backgroundColor: Colors.grey[300],
                color: primaryTwo,
              ),
              const SizedBox(height: 8),
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
      ),
    );
  }
}
