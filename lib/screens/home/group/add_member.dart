import 'dart:async';
import 'dart:convert';
import 'package:cyanase/helpers/loader.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:http/http.dart' as http;

class AddGroupMembersScreen extends StatefulWidget {
  final int groupId;

  AddGroupMembersScreen({required this.groupId});

  @override
  _AddGroupMembersScreenState createState() => _AddGroupMembersScreenState();
}

class _AddGroupMembersScreenState extends State<AddGroupMembersScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _allContacts = [];
  List<Map<String, dynamic>> _onlineContacts =
      []; // Separate list for online results
  Set<String> _selectedContactIds = Set<String>();
  List<Map<String, dynamic>> _selectedContacts = [];
  List<String> _existingMembers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isOnlineSearching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final contacts = await _dbHelper.getContacts();
      final participants = await _dbHelper.getParticipants(widget.groupId);
      final existingMemberIds =
          participants.map((p) => p['user_id'].toString()).toList();

      setState(() {
        _allContacts = contacts;
        _existingMembers = existingMemberIds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    }
  }

  void _toggleSelection(Map<String, dynamic> contact) {
    setState(() {
      String contactId = contact['id'].toString();
      if (_selectedContactIds.contains(contactId)) {
        _selectedContactIds.remove(contactId);
        _selectedContacts.removeWhere((c) => c['id'].toString() == contactId);
      } else {
        _selectedContactIds.add(contactId);
        _selectedContacts.add(contact);
      }
    });
  }

  Future<void> _addMembersToGroup() async {
    if (_selectedContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one contact')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      for (final contact in _selectedContacts) {
        await _dbHelper.insertParticipant({
          'group_id': widget.groupId,
          'user_id': contact['id'],
          'role': 'member',
          'joined_at': DateTime.now().toIso8601String(),
          'muted': 0,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Members added successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add members: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchOnline(String query) async {
    if (query.isEmpty) {
      setState(() {
        _onlineContacts.clear();
        _isOnlineSearching = false;
      });
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: 800), () async {
      setState(() {
        _isOnlineSearching = true;
        _onlineContacts.clear(); // Clear previous results
      });

      try {
        final response = await http.post(
          Uri.parse('https://fund.cyanase.app/app/search.php'),
          body: {'query': query},
        );

        if (response.statusCode == 200) {
          final List<dynamic> onlineContacts = jsonDecode(response.body);
          setState(() {
            _onlineContacts = onlineContacts
                .map((c) => {
                      'id': c['id'],
                      'name': c['name'],
                      'phone_number': c['phone_number'],
                      'profilePic': c['profilePic'] ?? '',
                    })
                .toList();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No contacts found'),
              duration: Duration(seconds: 3), // Custom duration (3 seconds)
            ),
          );
        }
      } catch (e) {
        print(e);
      } finally {
        setState(() {
          _isOnlineSearching = false;
        });
      }
    });
  }

  List<Map<String, dynamic>> _filterLocalContacts(String query) {
    return _allContacts.where((contact) {
      final name = contact['name']?.toLowerCase() ?? '';
      final phone = contact['phone_number']?.toLowerCase() ?? '';
      return name.contains(query.toLowerCase()) ||
          phone.contains(query.toLowerCase());
    }).toList();
  }

  List<Map<String, dynamic>> get _combinedContacts {
    final localFiltered = _filterLocalContacts(_searchController.text);
    final onlineFiltered = _onlineContacts.where((onlineContact) {
      return !localFiltered
          .any((localContact) => localContact['id'] == onlineContact['id']);
    }).toList();
    return [...localFiltered, ...onlineFiltered];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text("Add Members", style: TextStyle(color: white, fontSize: 20)),
        backgroundColor: primaryTwo,
        iconTheme: IconThemeData(color: white),
        actions: [
          IconButton(
            icon: _isLoading
                ? SizedBox(width: 24, height: 24, child: Loader())
                : Icon(Icons.check, color: white),
            onPressed: _isLoading ? null : _addMembersToGroup,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedContacts.isNotEmpty)
            Container(
              height: 100,
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedContacts.length,
                itemBuilder: (context, index) {
                  final contact = _selectedContacts[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            CircleAvatar(
                              backgroundImage:
                                  contact['profilePic']?.isNotEmpty == true
                                      ? NetworkImage(contact['profilePic'])
                                      : AssetImage('assets/images/avatar.png')
                                          as ImageProvider,
                              radius: 30,
                            ),
                            SizedBox(height: 4),
                            Text(contact['name']?.split(' ').first ?? 'Unknown',
                                style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _toggleSelection(contact),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (query) {
                if (_debounce?.isActive ?? false) _debounce?.cancel();
                _debounce = Timer(Duration(milliseconds: 500), () {
                  setState(() {
                    // Trigger rebuild to show loading or clear old results
                  });
                  if (_filterLocalContacts(query).isEmpty) {
                    _searchOnline(query);
                  }
                });
              },
            ),
          ),
          if (_isOnlineSearching) Loader(),
          SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? Center(child: Loader())
                : ListView.builder(
                    itemCount: _combinedContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _combinedContacts[index];
                      final contactId = contact['id'].toString();
                      final isSelected =
                          _selectedContactIds.contains(contactId);
                      final isAlreadyMember =
                          _existingMembers.contains(contactId);
                      if (isAlreadyMember) return SizedBox.shrink();

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              contact['profilePic']?.isNotEmpty == true
                                  ? NetworkImage(contact['profilePic'])
                                  : AssetImage('assets/images/avatar.png')
                                      as ImageProvider,
                        ),
                        title: Text(contact['name'] ?? 'Unknown'),
                        subtitle:
                            Text(contact['phone_number'] ?? 'No phone number'),
                        trailing: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected ? primaryTwo : Colors.grey,
                        ),
                        onTap: () => _toggleSelection(contact),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
