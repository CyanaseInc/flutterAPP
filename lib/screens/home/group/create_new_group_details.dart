import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/screens/home/home.dart';

class GroupDetailsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedContacts;

  GroupDetailsScreen({required this.selectedContacts});

  @override
  _GroupDetailsScreenState createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController =
      TextEditingController();
  File? _groupImage;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isSaving = false; // To handle loading state

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

    setState(() {
      _isSaving = true; // Show loading indicator
    });

    try {
      // Insert the group into the database
      final groupId = await _dbHelper.insertGroup({
        'name': groupName,
        'description':
            _groupDescriptionController.text.trim(), // Add description
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
          continue;
        }

        // Insert the participant into the participants table
        await _dbHelper.insertParticipant({
          'group_id': groupId,
          'user_id': userId, // Use the ID from the contacts table
          'role': 'member', // Default role
          'joined_at': DateTime.now().toIso8601String(),
          'muted':
              0, // Use 0 for false, 1 for true (SQLite does not support bool directly)
        });
      }

      // Navigate to the group chat screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(),
        ),
      );

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group created successfully!')),
      );
    } catch (e) {
      print("Error creating group: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to create group: ${e.toString()}")),
      );
    } finally {
      setState(() {
        _isSaving = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "New Group",
          style: TextStyle(color: white, fontSize: 20),
        ),
        backgroundColor: primaryTwo,
        iconTheme: IconThemeData(color: white),
        actions: [
          IconButton(
            icon: _isSaving
                ? CircularProgressIndicator(color: white) // Show loader
                : Icon(Icons.check, color: white),
            onPressed:
                _isSaving ? null : _saveGroup, // Disable button when saving
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Centered Profile Picture
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _groupImage != null
                        ? FileImage(_groupImage!)
                        : AssetImage('assets/images/default_group.png')
                            as ImageProvider,
                    child: _groupImage == null
                        ? Icon(Icons.camera_alt,
                            size: 40, color: Colors.grey[300])
                        : null,
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Left-Aligned Group Name
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Group Name',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryTwo,
                  ),
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _groupNameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
                textAlign: TextAlign.left,
              ),
              SizedBox(height: 20),
              // Left-Aligned Group Description
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Group Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryTwo,
                  ),
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _groupDescriptionController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
                textAlign: TextAlign.left,
              ),
              SizedBox(height: 20),
              // Left-Aligned Selected Members
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Selected Members:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryTwo,
                  ),
                ),
              ),
              SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: widget.selectedContacts.length,
                itemBuilder: (context, index) {
                  final contact = widget.selectedContacts[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundImage: contact['profilePic'] != null &&
                              contact['profilePic']!.isNotEmpty
                          ? NetworkImage(contact['profilePic']!)
                          : AssetImage('assets/images/avatar.png')
                              as ImageProvider,
                      child: contact['profilePic'] == null ||
                              contact['profilePic']!.isEmpty
                          ? Icon(Icons.person, color: white)
                          : null,
                    ),
                    title: Text(
                      contact['name'] ?? 'Unknown',
                      textAlign: TextAlign.left,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
