import 'package:cyanase/helpers/loader.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/withdraw_helper.dart';

class EditGroupGoalScreen extends StatefulWidget {
  final int goalId;
  final String goalName;
  final double currentAmount;
  final bool isAdmin;
  final int groupId;
  const EditGroupGoalScreen({
    Key? key,
    required this.goalId,
    required this.goalName,
    required this.currentAmount,
    required this.isAdmin,
    required this.groupId,
  }) : super(key: key);

  @override
  _EditGroupGoalScreenState createState() => _EditGroupGoalScreenState();
}

class _EditGroupGoalScreenState extends State<EditGroupGoalScreen> {
  late TextEditingController _nameController;
  late TextEditingController _withdrawController;
  bool _isRenaming = false;
  bool _isWithdrawing = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goalName);
    _withdrawController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _withdrawController.dispose();
    super.dispose();
  }

  Future<void> _renameGoal() async {
    if (_nameController.text.isEmpty) {
      _showSnackBar('Goal name cannot be empty', Colors.red);
      return;
    }

    if (_nameController.text == widget.goalName) {
      _showSnackBar('No changes to save', Colors.orange);
      return;
    }

    setState(() => _isRenaming = true);
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
        'goal_id': widget.goalId,
      };

      final response = await ApiService.EditGroupGoal(token, data);
      if (response['success'] == false) {
        _showSnackBar(
            'Failed to rename goal: ${response['message']}', Colors.red);
      } else {
        _showSnackBar('Goal name updated', Colors.green, Icons.check_circle);
        Navigator.pop(context, {
          'goalId': widget.goalId,
          'goalName': _nameController.text,
        });
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isRenaming = false);
      }
    }
  }

  Future<void> _submitWithdrawal() async {
    if (!widget.isAdmin) {
      _showSnackBar('Only group admins can withdraw funds', Colors.red);
      return;
    }

    final withdrawAmount = double.tryParse(_withdrawController.text) ?? 0.0;
    if (withdrawAmount <= 0) {
      _showSnackBar('Enter a valid withdrawal amount', Colors.red);
      return;
    }

    if (withdrawAmount > widget.currentAmount) {
      _showSnackBar('Withdrawal exceeds current amount', Colors.red);
      return;
    }

    setState(() => _isWithdrawing = true);
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: SingleChildScrollView(
            child: WithdrawHelper(
              withdrawType: 'group_goal_withdraw',
              withdrawDetails: 'Withdraw from ${widget.goalName}',
              goalId: widget.goalId,
              groupId: widget.groupId,
              onWithdrawProcessed: () {
                Navigator.pop(context, {
                  'goalId': widget.goalId,
                  'withdrawAmount': withdrawAmount,
                });
              },
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isWithdrawing = false);
      }
    }
  }

  Future<void> _deleteGoal() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Delete Goal', style: TextStyle(color: primaryTwo)),
        content: Text(
          'Are you sure you want to delete "${widget.goalName}"? All funds will be returned to contributors.',
          style: TextStyle(color: Colors.grey[800]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      try {
        final dbHelper = DatabaseHelper();
        final db = await dbHelper.database;
        final userProfile = await db.query('profile', limit: 1);

        if (userProfile.isEmpty) {
          throw Exception('No user profile found');
        }

        final data = {
          'goal_id': widget.goalId,
        };

        final token = userProfile.first['token'] as String;
        final response = await ApiService.DeleteGroupGoal(token, data);

        
        if (response['success'] == false) {
          _showSnackBar(
              'Failed to delete goal: ${response['message']}', Colors.red);
        } else {
          Navigator.pop(context, {'goalId': widget.goalId, 'deleted': true});
          _showSnackBar('Goal deleted', Colors.green, Icons.delete);
        }
      } finally {
        if (mounted) {
          setState(() => _isDeleting = false);
        }
      }
    }
  }

  void _showSnackBar(String message, Color color, [IconData? icon]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              SizedBox(width: 8),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Goal',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryTwo,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rename Goal',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryTwo),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Goal Name',
                        hintText: 'Enter new goal name',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: primaryTwo, width: 2),
                        ),
                        prefixIcon: Icon(Icons.edit, color: primaryTwo),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _isRenaming ? null : _renameGoal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTwo,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isRenaming
                            ? const SizedBox(
                                width: 20, height: 20, child: Loader())
                            : const Text('Save Name',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Withdraw Funds',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryTwo),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _withdrawController,
                      keyboardType: TextInputType.number,
                      enabled: widget.isAdmin,
                      decoration: InputDecoration(
                        labelText: 'Amount (UGX)',
                        hintText: widget.isAdmin
                            ? 'Enter amount to withdraw'
                            : 'Only admins can withdraw funds',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: primaryTwo, width: 2),
                        ),
                        prefixText: 'UGX ',
                        prefixIcon: Icon(Icons.money_off, color: primaryTwo),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Available: UGX ${widget.currentAmount.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: widget.isAdmin && !_isWithdrawing
                            ? _submitWithdrawal
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              widget.isAdmin ? primaryTwo : Colors.grey,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isWithdrawing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                widget.isAdmin
                                    ? 'Submit Withdrawal'
                                    : 'Admin Only',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delete Goal',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700]),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Permanently remove this goal and return funds to contributors.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _isDeleting ? null : _deleteGoal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isDeleting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Delete Goal',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                      fontSize: 16,
                      color: primaryTwo,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
