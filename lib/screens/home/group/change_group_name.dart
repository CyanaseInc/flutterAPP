import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:cyanase/helpers/database_helper.dart';
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

  @override
  void initState() {
    super.initState();
    _loadGroupDetails();
  }

  Future<void> _loadGroupDetails() async {
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> result = await db.query(
      'groups',
      columns: ['name', 'description'],
      where: 'id = ?',
      whereArgs: [widget.groupId],
    );
    if (result.isNotEmpty) {
      setState(() {
        _nameController.text = result.first['name'];
        _descriptionController.text = result.first['description'] ?? '';
      });
    }
  }

  Future<void> _updateGroupDetails() async {
    String newName = _nameController.text.trim();
    String newDescription = _descriptionController.text.trim();

    if (newName.isEmpty) return;

    Database db = await _dbHelper.database;
    await db.update(
      'groups',
      {
        'name': newName,
        'description': newDescription,
      },
      where: 'id = ?',
      whereArgs: [widget.groupId],
    );

    Navigator.pop(context, {
      'name': newName,
      'description': newDescription,
    }); // Return the new name and description
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit group',
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
              ),
              maxLines: 3, // Allow multiple lines for description
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _updateGroupDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTwo, // Blue background color
                  foregroundColor: Colors.white, // White text color
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12), // Padding
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
