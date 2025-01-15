import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/theme/theme.dart';
import '';

class GroupDetailsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedContacts;

  GroupDetailsScreen({required this.selectedContacts});

  @override
  _GroupDetailsScreenState createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  File? _groupImage;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _groupImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    // Save group data to SQLite database
    final groupId = await _dbHelper.insertGroup({
      'name': groupName,
      'description': '', // Add description if needed
      'profile_pic': _groupImage?.path ?? '', // Save image path if available
      'type': 'group', // Default type
      'created_at': DateTime.now().toIso8601String(),
      'created_by': 'current_user_id', // Replace with actual user ID
      'last_activity': DateTime.now().toIso8601String(),
      'settings': '', // Add settings if needed
    });

    // Save participants to the SQLite database
    for (final contact in widget.selectedContacts) {
      // Ensure each contact has a valid ID
      final userId = contact['id'];
      if (userId == null) {
        print('Error: Contact does not have a valid ID: $contact');
        continue;
      }

      await _dbHelper.insertParticipant({
        'group_id': groupId,
        'user_id': userId, // Ensure this is not null
        'role': 'member', // Default role
        'joined_at': DateTime.now().toIso8601String(),
        'muted': false,
      });
    }

    // Navigate back to the previous screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatList(),
      ),
    );

    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Group created successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "New Group",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        backgroundColor: primaryTwo,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: Colors.white),
            onPressed: _saveGroup,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _groupImage != null
                    ? FileImage(_groupImage!)
                    : AssetImage('assets/images/default_group.png')
                        as ImageProvider,
                child: _groupImage == null
                    ? Icon(Icons.camera_alt, size: 40, color: Colors.grey[300])
                    : null,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Selected Members:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryTwo,
              ),
              textAlign: TextAlign.left,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.selectedContacts.length,
                itemBuilder: (context, index) {
                  final contact = widget.selectedContacts[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: contact['profilePic'] != null &&
                              contact['profilePic']!.isNotEmpty
                          ? NetworkImage(contact['profilePic']!)
                          : AssetImage('assets/images/avatar.png')
                              as ImageProvider,
                      child: contact['profilePic'] == null ||
                              contact['profilePic']!.isEmpty
                          ? Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    title: Text(contact['name'] ?? 'Unknown'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
