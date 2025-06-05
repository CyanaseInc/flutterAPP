import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/theme/theme.dart';

class ChangeGroupNameScreen extends StatefulWidget {
  final int groupId;

  const ChangeGroupNameScreen({Key? key, required this.groupId})
      : super(key: key);

  @override
  _ChangeGroupNameScreenState createState() => _ChangeGroupNameScreenState();
}

class _ChangeGroupNameScreenState extends State<ChangeGroupNameScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isAdmin = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserAndGroupDetails();
  }

  Future<void> _loadUserAndGroupDetails() async {
    Database db = await _dbHelper.database;

    List<Map<String, dynamic>> profileResult =
        await db.query('profile', limit: 1);

    _currentUserId = profileResult.first['id'] as String?;

    List<Map<String, dynamic>> participantResult = await db.query(
      'participants',
      columns: ['role'],
      where: 'group_id = ? AND user_id = ?',
      whereArgs: [widget.groupId, _currentUserId],
    );

    if (participantResult.isNotEmpty) {
      setState(() {
        _isAdmin = participantResult.first['role'] == 'admin';
      });
    }

    List<Map<String, dynamic>> groupResult = await db.query(
      'groups',
      columns: ['name', 'description'],
      where: 'id = ?',
      whereArgs: [widget.groupId],
    );
    if (groupResult.isNotEmpty) {
      setState(() {
        _nameController.text = groupResult.first['name'];
        _descriptionController.text = groupResult.first['description'] ?? '';
      });
    }
  }

  Future<void> _updateGroupDetails() async {
    if (!_isAdmin) return;

    String newName = _nameController.text.trim();
    String newDescription = _descriptionController.text.trim();

    if (newName.isEmpty) return;

    try {
      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isEmpty) {
        throw Exception('No user profile found');
      }
      final token = userProfile.first['token'] as String;

      // Prepare data map for EditGroup
      final Map<String, dynamic> groupData = {
        'name': newName,
        'description': newDescription,
        'groupid': widget.groupId.toString(),
      };

      // Call the API with positional arguments
      await ApiService.EditGroup(token, groupData);

      // Update local SQLite database
      await db.update(
        'groups',
        {
          'name': newName,
          'description': newDescription,
        },
        where: 'id = ?',
        whereArgs: [widget.groupId],
      );

      // Navigate back with updated data and force refresh
      Navigator.pop(context, {
        'name': newName,
        'description': newDescription,
        'refresh': true, // Add a flag to indicate refresh is needed
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update group: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Group',
          style: TextStyle(color: white),
        ),
        backgroundColor: primaryTwo,
        iconTheme: IconThemeData(color: white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group Name',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryTwo,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                enabled: _isAdmin,
                hintText: _isAdmin ? 'Enter new group name' : 'Admins only',
                hintStyle: TextStyle(
                  color: _isAdmin ? Colors.grey : Colors.grey.shade400,
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Group Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryTwo,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                enabled: _isAdmin,
                hintText: _isAdmin ? 'Enter new description' : 'Admins only',
                hintStyle: TextStyle(
                  color: _isAdmin ? Colors.grey : Colors.grey.shade400,
                ),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            if (!_isAdmin)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Only admins can edit group details.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            Center(
              child: ElevatedButton(
                onPressed: _isAdmin ? _updateGroupDetails : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTwo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 68, // Increased from 24 to 48 for wider button
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
