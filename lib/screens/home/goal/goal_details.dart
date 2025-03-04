import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart'; // Assuming your theme variables are here
import 'package:image_picker/image_picker.dart'; // For image picking
import 'dart:io'; // For File handling
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';

class GoalDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> goalData;

  const GoalDetailsScreen({
    Key? key,
    required this.goalData,
  }) : super(key: key);

  @override
  _GoalDetailsScreenState createState() => _GoalDetailsScreenState();
}

class _GoalDetailsScreenState extends State<GoalDetailsScreen> {
  late TextEditingController _nameController;
  late Map<String, dynamic> editableGoalData;
  String? _goalPicture; // Original picture URL or path
  String? _tempGoalPicture; // Temporary picture path for preview
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    editableGoalData = Map.from(widget.goalData); // Create a mutable copy
    _nameController = TextEditingController(
      text: editableGoalData['goal_name'] as String? ?? 'Unnamed Goal',
    );
    _goalPicture =
        editableGoalData['goal_picture'] as String?; // Original picture
    _tempGoalPicture = _goalPicture; // Initialize temp with original
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    editableGoalData['goal_name'] = _nameController.text;
    editableGoalData['goal_picture'] = _goalPicture;

    setState(() => _isSubmitting = true);

    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);

      if (userProfile.isEmpty) {
        throw Exception('No user profile found');
      }

      final token = userProfile.first['token'] as String;

      final data = {
        'goal_name': _nameController.text,
        'goal_id': editableGoalData['goal_id'],
      };

      File? goalImage;
      if (_goalPicture != null && !_goalPicture!.startsWith('http')) {
        goalImage = File(_goalPicture!);
      }
      print('data : $data');
      final response = await ApiService.EditGoal(token, data, goalImage);
      print('response : $response');
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal saved successfully!')),
        );

        // Return the updated goal data
        Navigator.pop(context, editableGoalData);
      }
    } catch (e) {
      print('Error in _saveChanges: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save changes: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _deleteGoal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text('Are you sure you want to delete this goal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, {'deleted': true}); // Indicate deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Goal deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Withdraw all funds
  void _withdrawFunds() {
    double totalDeposits = 0.0;
    if (editableGoalData['deposit'] != null &&
        (editableGoalData['deposit'] as List).isNotEmpty) {
      totalDeposits = (editableGoalData['deposit'] as List)
          .map((d) => double.tryParse(d.toString()) ?? 0.0)
          .reduce((a, b) => a + b);
    }

    if (totalDeposits > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Withdraw Funds'),
          content: Text('Withdraw $totalDeposits from this goal?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  editableGoalData['deposit'] = []; // Clear deposits
                });
                Navigator.pop(context); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Funds withdrawn')),
                );
              },
              child: const Text('Withdraw'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No funds to withdraw')),
      );
    }
  }

  // Method to update the picture (temp preview only)
  Future<void> _updatePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _tempGoalPicture = pickedFile.path; // Store temp path for preview
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image selected - Save to confirm')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalDeposits = 0.0;
    if (editableGoalData['deposit'] != null &&
        (editableGoalData['deposit'] as List).isNotEmpty) {
      totalDeposits = (editableGoalData['deposit'] as List)
          .map((d) => double.tryParse(d.toString()) ?? 0.0)
          .reduce((a, b) => a + b);
    }
    final goalAmount =
        (editableGoalData['goal_amount'] as num? ?? 0).toDouble();
    final progress =
        goalAmount > 0 ? (totalDeposits / goalAmount).clamp(0.0, 1.0) : 0.0;

    final hasImage = _tempGoalPicture != null && _tempGoalPicture!.isNotEmpty;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Goal Details'),
            backgroundColor: primaryTwo,
            foregroundColor: white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Goal Image and Name Row
                  Row(
                    children: [
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: _updatePicture, // Tap to change picture
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: hasImage
                                      ? (_tempGoalPicture!.startsWith('http')
                                              ? NetworkImage(_tempGoalPicture!)
                                              : FileImage(
                                                  File(_tempGoalPicture!)))
                                          as ImageProvider
                                      : AssetImage('assets/images/goal.png')
                                          as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                                border: Border.all(
                                  color: primaryTwo,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          // Edit Icon Overlay
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _updatePicture,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: primaryTwo,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Goal Name',
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Progress Info
                  Text(
                    'Progress: ${(progress * 100).toInt()}%',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: primaryTwo,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Saved: $totalDeposits / $goalAmount',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  // Action Buttons
                  ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : _saveChanges, // Disable when submitting
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTwo,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Save Changes',
                        style: TextStyle(color: white)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _withdrawFunds,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Withdraw All Funds',
                        style: TextStyle(color: white)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _deleteGoal,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Delete Goal'),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Loader overlay
        if (_isSubmitting)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: Loader(), // Custom Loader widget defined below
            ),
          ),
      ],
    );
  }
}

// Simple Loader widget
class Loader extends StatelessWidget {
  const Loader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
    );
  }
}
