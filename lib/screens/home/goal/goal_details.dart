import 'package:country_picker/country_picker.dart';
import 'package:cyanase/helpers/endpoints.dart';
import 'package:cyanase/helpers/get_currency.dart';
import 'package:cyanase/helpers/web_db.dart';
import 'package:cyanase/helpers/withdraw_helper.dart';

import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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
  String? _goalPicture;
  String? _tempGoalPicture;
  bool _isSubmitting = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    editableGoalData = Map.from(widget.goalData);
    _nameController = TextEditingController(
      text: editableGoalData['goal_name'] as String? ?? 'Unnamed Goal',
    );
    _goalPicture = "/${editableGoalData['goal_picture']}" as String?;
    _tempGoalPicture = ApiEndpoints.server +'/'+ _goalPicture!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
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

      // First upload the image if it's a new one
      if (_tempGoalPicture != null && !_tempGoalPicture!.startsWith('http')) {
        final imageFile = File(_tempGoalPicture!);
        final imageResponse = await ApiService.EditGoal(token, data, imageFile);

        if (imageResponse['success'] == true) {
          setState(() {
            _goalPicture = _tempGoalPicture;
            editableGoalData['goal_picture'] = _tempGoalPicture;
          });
        } else {
          throw Exception(
              'Failed to upload image: ${imageResponse['message']}');
        }
      } else {
        // If no new image, just update the goal name
        final response = await ApiService.EditGoal(token, data, null);
        if (response['success'] == true) {
          setState(() {
            editableGoalData['goal_name'] = _nameController.text;
            // Preserve the existing image path if no new image was uploaded
            editableGoalData['goal_picture'] = _goalPicture;
          });
        } else {
          throw Exception('Failed to update goal: ${response['message']}');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal saved successfully!')),
      );
      Navigator.pop(context, editableGoalData);
    } catch (e) {
      print('Error in _saveChanges: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save changes: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> deleteGoal() async {
    setState(() => _isDeleting = true);
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);

      if (userProfile.isEmpty) {
        throw Exception('No user profile found');
      }
      
      final token = userProfile.first['token'] as String?;
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final goalId = editableGoalData['goal_id'];
      if (goalId == null) {
        throw Exception('Invalid goal ID');
      }
      
      final data = {
        'goal_id': goalId.toString(),
      };
      
      final response = await ApiService.DeleteGoal(token, data);
      
      if (response != null && response['success'] == true) {
        Navigator.pop(context, {'deleted': true});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal deleted')),
        );
      } else {
        throw Exception(response?['message'] ?? 'Failed to delete goal');
      }
    } catch (e) {
      print('Error in deleting goal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check your connection')),
      );
    } finally {
      setState(() => _isDeleting = false);
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
              Navigator.pop(context); // Close the confirmation dialog
              setState(() => _isDeleting = true); // Show preloader
              deleteGoal();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _tempGoalPicture = pickedFile.path;
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
      totalDeposits =
          double.tryParse(editableGoalData['deposit'][0].toString()) ?? 0.0;
    }
    final goalAmount =
        double.tryParse(editableGoalData['goal_amount'].toString()) ?? 0.0;
    final progress =
        goalAmount > 0 ? (totalDeposits / goalAmount).clamp(0.0, 1.0) : 0.0;

    final hasImage = _tempGoalPicture != null && _tempGoalPicture!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Goal Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: primaryTwo,
        foregroundColor: white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Goal Image and Name Section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: hasImage
                                  ? (_tempGoalPicture!.startsWith('http')
                                          ? NetworkImage(_tempGoalPicture!)
                                          : FileImage(File(_tempGoalPicture!)))
                                      as ImageProvider
                                  : const AssetImage('assets/images/goal.png'),
                              fit: BoxFit.cover,
                            ),
                            border: Border.all(
                              color: primaryTwo.withOpacity(0.7),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _updatePicture,
                              customBorder: const CircleBorder(),
                              child: Stack(
                                children: [
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: primaryTwo,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        size: 14,
                                        color: white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Goal Name',
                              labelStyle: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: primaryTwo,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Progress Section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Progress',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: primaryTwo,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Stack(
                              children: [
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: progress,
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: primaryTwo,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Saved: $totalDeposits / $goalAmount',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Action Buttons
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryTwo,
                              foregroundColor: white,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Save Changes'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                                builder: (BuildContext context) {
                                  return Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Withdraw from ${widget.goalData['goal_name']}",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: primaryTwo,
                                          ),
                                        ),
                                        WithdrawHelper(
                                          withdrawType: "user_goals",
                                          withdrawDetails:
                                              'user goals ${widget.goalData['goal_name']}',
                                          goalId: widget.goalData['goal_id'],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: white,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Withdraw All Funds'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _deleteGoal,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              minimumSize: const Size(double.infinity, 48),
                              side: BorderSide(
                                color: Colors.red.withOpacity(0.7),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Delete Goal'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isSubmitting || _isDeleting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isDeleting ? 'Deleting goal...' : 'Saving changes...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Loader extends StatelessWidget {
  const Loader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
    );
  }
}
