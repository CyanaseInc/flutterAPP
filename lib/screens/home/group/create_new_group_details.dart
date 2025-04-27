import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/screens/home/home.dart';
import 'package:cyanase/helpers/api_helper.dart';

class GroupDetailsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedContacts;

  const GroupDetailsScreen({required this.selectedContacts, super.key});

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
        const SnackBar(content: Text('Please enter a group name')),
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
      final userId = userProfile.first['id'] as String; // Current user's ID
      final userName = userProfile.first['name'] as String? ??
          'Creator'; // Fallback for creator's name

      // Prepare the data for the POST request
      final Map<String, dynamic> groupData = {
        'name': groupName,
        'description': _groupDescriptionController.text.trim(),
        'profile_pic': _groupImage?.path ?? '',
        'type': 'group',
        'created_by': userId,
        'participants': [
          ...widget.selectedContacts
              .map((contact) => {
                    'user_id': contact['id'].toString(),
                    'role':
                        contact['id'].toString() == userId ? 'admin' : 'member',
                    'is_approved': true,
                    'is_denied': false,
                  })
              .toList(),
          {
            'user_id': userId,
            'role': 'admin',
            'is_approved': true,
            'is_denied': false,
            'invited_by': userId,
          }
        ]
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
          'created_by': userId,
          'last_activity': DateTime.now().toIso8601String(),
          'settings': '',
        });

        // Insert the creator as an admin
        await _dbHelper.insertParticipant({
          'group_id': groupId,
          'user_id': userId,
          'user_name': userName,
          'role': 'admin',
          'joined_at': DateTime.now().toIso8601String(),
          'muted': 0,
          'is_admin': 1,
          'is_approved': 1,
          'is_denied': 0,
        });

        // Save other participants to the SQLite database
        for (final contact in widget.selectedContacts) {
          final contactId = contact['id'].toString();
          if (contactId == userId) continue; // Skip creator (already added)

          await _dbHelper.insertParticipant({
            'group_id': groupId,
            'user_id': contactId,
            'user_name': contact['name'] ?? 'Unknown',
            'role': 'member',
            'joined_at': DateTime.now().toIso8601String(),
            'muted': 0,
            'is_admin': 0,
            'is_approved': 1,
            'is_denied': 0,
          });
        }

        // Navigate to the home screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group created successfully!')),
          );
        }
      } else {
        throw Exception(
            'Failed to create group: No group ID returned from API');
      }
    } catch (e) {
      print("Error creating group: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create group: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "New Group",
          style: TextStyle(color: white, fontSize: 20),
        ),
        backgroundColor: primaryTwo,
        iconTheme: const IconThemeData(color: white),
        actions: [
          IconButton(
            icon: _isSaving
                ? const CircularProgressIndicator(color: white)
                : const Icon(Icons.check, color: white),
            onPressed: _isSaving ? null : _saveGroup,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _groupImage != null
                        ? FileImage(_groupImage!)
                        : const AssetImage('assets/images/default_group.png')
                            as ImageProvider,
                    child: _groupImage == null
                        ? Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Group Name',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryTwo,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 20),
              const Text(
                'Group Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryTwo,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _groupDescriptionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 20),
              const Text(
                'Selected Members:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryTwo,
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.selectedContacts.length,
                itemBuilder: (context, index) {
                  final contact = widget.selectedContacts[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundImage: contact['profilePic'] != null &&
                              contact['profilePic'].isNotEmpty
                          ? NetworkImage(contact['profilePic'])
                          : const AssetImage('assets/images/avatar.png')
                              as ImageProvider,
                      child: contact['profilePic'] == null ||
                              contact['profilePic'].isEmpty
                          ? const Icon(Icons.person, color: white)
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
