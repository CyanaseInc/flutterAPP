import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/screens/home/home.dart';
import 'package:cyanase/helpers/api_helper.dart';

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
  bool _isSaving = false;

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
      _isSaving = true;
    });

    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);

      if (userProfile.isEmpty) {
        throw Exception('No user profile found');
      }

      final token = userProfile.first['token'] as String;
      final userId =
          userProfile.first['id'] as String; // Current user's ID (creator)

      // Prepare the data for the POST request
      final Map<String, dynamic> groupData = {
        'name': groupName,
        'description': _groupDescriptionController.text.trim(),
        'profile_pic': _groupImage?.path ?? '',
        'type': 'group',
        'created_by': userId,
        'participants': widget.selectedContacts
            .map((contact) => {
                  'user_id': contact['id'],
                  'role': contact['id'] == userId
                      ? 'admin'
                      : 'member', // Creator as admin
                })
            .toList()
          ..add({
            'user_id': userId,
            'role': 'admin'
          }), // Ensure creator is included
      };

      // Make the POST request to create the group
      final response = await ApiService.NewGroup(token, groupData);

      if (response['success'] == true) {
        final groupId = response['data']['groupId'];

        // Insert the group into the local SQLite database
        await _dbHelper.insertGroup({
          'id': groupId,
          'name': groupName,
          'description': _groupDescriptionController.text.trim(),
          'profile_pic': _groupImage?.path ?? '',
          'type': 'group',
          'created_at': DateTime.now().toIso8601String(),
          'created_by': userId, // Use actual user ID
          'last_activity': DateTime.now().toIso8601String(),
          'settings': '',
        });

        // Insert the creator as an admin explicitly
        await _dbHelper.insertParticipant({
          'group_id': groupId,
          'user_id': userId,
          'role': 'admin', // Creator is admin
          'joined_at': DateTime.now().toIso8601String(),
          'muted': 0,
        });

        // Save other participants to the SQLite database
        for (final contact in widget.selectedContacts) {
          final contactId = contact['id'];
          if (contactId == null || contactId == userId)
            continue; // Skip creator (already added)

          await _dbHelper.insertParticipant({
            'group_id': groupId,
            'user_id': contactId,
            'role': 'member', // All others are members
            'joined_at': DateTime.now().toIso8601String(),
            'muted': 0,
          });
        }

        // Navigate to the home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group created successfully!')),
        );
      } else {
        throw Exception(
            'Failed to create group: No group ID returned from API');
      }
    } catch (e) {
      print("Error creating group: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to create group: ${e.toString()}")),
      );
    } finally {
      setState(() {
        _isSaving = false;
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
                ? CircularProgressIndicator(color: white)
                : Icon(Icons.check, color: white),
            onPressed: _isSaving ? null : _saveGroup,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
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
