import 'dart:async';
import 'dart:convert';
import 'package:cyanase/helpers/loader.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:http/http.dart' as http;
import 'package:cyanase/helpers/api_helper.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cyanase/helpers/chat_websocket_service.dart';
import 'package:share_plus/share_plus.dart'; // Added for sharing
import 'package:clipboard/clipboard.dart'; // Added for copying to clipboard

class AddGroupMembersScreen extends StatefulWidget {
  final int groupId;
  final bool isAdmin;
  final String groupLink;

  const AddGroupMembersScreen({
    required this.groupId,
    required this.groupLink,
    required this.isAdmin,
    super.key,
  });

  @override
  _AddGroupMembersScreenState createState() => _AddGroupMembersScreenState();
}

class _AddGroupMembersScreenState extends State<AddGroupMembersScreen>
    with TickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _allContacts = [];
  List<Map<String, dynamic>> _onlineContacts = [];
  Set<String> _selectedContactIds = <String>{};
  List<Map<String, dynamic>> _selectedContacts = [];
  List<String> _existingMembers = [];
  bool _isLoading = true;
  bool _isSyncingContacts = false;
  double _syncProgress = 0.0;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isOnlineSearching = false;
  AnimationController? _refreshAnimationController;
  AnimationController?
      _shareDialogAnimationController; // Added for dialog animation
  Animation<double>? _shareDialogScaleAnimation;

  @override
  void initState() {
    super.initState();
    _refreshAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _refreshAnimationController?.reset();
          if (_isSyncingContacts) {
            _refreshAnimationController?.forward();
          }
        }
      });

    // Initialize share dialog animation
    _shareDialogAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shareDialogScaleAnimation = CurvedAnimation(
      parent: _shareDialogAnimationController!,
      curve: Curves.easeOutBack,
    );

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

  Future<void> _refreshContacts() async {
    try {
      setState(() {
        _isSyncingContacts = true;
        _syncProgress = 0.0;
      });
      _refreshAnimationController?.forward();
      final db = await _dbHelper.database;
      await db.delete('contacts');
      setState(() {
        _syncProgress = 0.2;
      });
      final contacts = await fetchAndHashContacts();
      setState(() {
        _syncProgress = 0.5;
      });
      final registeredContacts = await getRegisteredContacts(contacts);
      setState(() {
        _syncProgress = 1.0;
      });
      await Future.delayed(const Duration(milliseconds: 500));
      final updatedContacts = await _dbHelper.getContacts();
      if (mounted) {
        setState(() {
          _allContacts = updatedContacts;
          _isSyncingContacts = false;
          _syncProgress = 0.0;
        });
        _refreshAnimationController?.stop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts refreshed successfully!')),
        );
      }
    } catch (e) {
      print('Sync error: $e');
      if (mounted) {
        setState(() {
          _isSyncingContacts = false;
          _syncProgress = 0.0;
        });
        _refreshAnimationController?.stop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh contacts: $e'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _refreshContacts,
            ),
          ),
        );
      }
    }
  }

  String normalizePhoneNumber(String phoneNumber, String regionCode) {
    try {
      phoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+256${phoneNumber.replaceFirst(RegExp(r'^0'), '')}';
      }
      if (!phoneNumber.startsWith('+256')) {
        throw Exception("Invalid country code for Uganda: $phoneNumber");
      }
      if (phoneNumber.length != 12) {
        throw Exception("Invalid phone number length: $phoneNumber");
      }
      final digits = phoneNumber.substring(4);
      if (!RegExp(r'^\d+$').hasMatch(digits)) {
        throw Exception("Invalid phone number format: $phoneNumber");
      }
      return phoneNumber;
    } catch (e) {
      return phoneNumber;
    }
  }

  Future<List<Map<String, String>>> fetchAndHashContacts() async {
    List<Map<String, String>> contactsWithHashes = [];
    PermissionStatus permissionStatus = await Permission.contacts.request();
    if (permissionStatus != PermissionStatus.granted) {
      throw Exception("Permission to access contacts denied");
    }
    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
    );
    for (var contact in contacts) {
      if (contact.phones.isNotEmpty) {
        for (var phone in contact.phones) {
          try {
            String normalizedNumber = normalizePhoneNumber(phone.number, 'UG');
            contactsWithHashes.add({
              'name': contact.displayName ?? 'Unknown',
              'phone': phone.number,
              'normalizedPhone': normalizedNumber,
            });
          } catch (e) {
            print('Error processing ${contact.displayName}: $e');
          }
        }
      }
    }
    return contactsWithHashes;
  }

  Future<List<Map<String, dynamic>>> getRegisteredContacts(
      List<Map<String, dynamic>> contacts) async {
    final String apiUrl = "https://fund.cyanase.app/app/get_my_contacts.php";
    List<String> phoneNumbers =
        contacts.map((contact) => contact['phone'] as String).toList();
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"phoneNumbers": phoneNumbers}),
    );
    if (response.statusCode == 200) {
      List<dynamic> registeredNumbersWithIds =
          jsonDecode(response.body)["registeredContacts"];
      List<Map<String, dynamic>> registeredContacts = contacts
          .where((contact) => registeredNumbersWithIds
              .any((registered) => registered['phoneno'] == contact['phone']))
          .map((contact) {
        var registered = registeredNumbersWithIds.firstWhere(
            (registered) => registered['phoneno'] == contact['phone']);
        return {
          'id': int.parse(registered['id'].toString()),
          'user_id': registered['id'].toString(),
          'name': contact['name'],
          'phone': contact['phone'],
          'profilePic': contact['profilePic'] ?? '',
          'is_registered': true,
        };
      }).toList();
      final dbHelper = DatabaseHelper();
      await dbHelper.insertContacts(registeredContacts);
      return registeredContacts;
    } else {
      throw Exception(
          "Failed to fetch registered contacts: ${response.statusCode}");
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
        const SnackBar(content: Text('Please select at least one contact')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);

      if (userProfile.isEmpty) throw Exception('No user profile found');
      final token = userProfile.first['token'] as String?;
      final userId = userProfile.first['id'] as String?;
      
      if (token == null || userId == null) {
        throw Exception('Invalid user profile data');
      }

      final Map<String, dynamic> requestData = {
        'groupid': widget.groupId.toString(),
        'participants': _selectedContacts.map((contact) {
          return {
            'user_id': contact['id'].toString(),
            'role': 'member',
            'is_approved': true,
            'is_denied': false
          };
        }).toList(),
      };

      final response = await ApiService.addMembers(token, requestData);

      if (response['success'] == true) {
        for (final contact in _selectedContacts) {
          try {
            // Database operations
            await _dbHelper.insertParticipant({
              'group_id': widget.groupId,
              'user_id': contact['id'],
              'role': 'member',
              'joined_at': DateTime.now().toIso8601String(),
              'muted': 0,
              'user_name': contact['name'] ?? 'Unknown',
            });

            await _dbHelper.insertNotification(
              groupId: widget.groupId,
              message: "${contact['name'] ?? 'A new member'} has joined the group",
              senderId: userId,
            );

            // WebSocket notification
            try {
              final wsMessage = {
                'type': 'send_message',
                'content': "${contact['name'] ?? 'A new member'} has joined the group",
                'sender_id': userId,
                'group_id': widget.groupId.toString(),
                'room_id': widget.groupId.toString(),
                'message_type': 'notification',
                'timestamp': DateTime.now().toIso8601String(),
                'status': 'sending'
              };
              
              if ( ChatWebSocketService.instance.isConnected) {
                await  ChatWebSocketService.instance.sendMessage(wsMessage);
              } else {
                print('WebSocket not connected, skipping notification');
              }
            } catch (wsError) {
              print('WebSocket error: $wsError');
              // Continue with other contacts even if WebSocket fails
            }
          } catch (e) {
            print('Error processing contact ${contact['id']}: $e');
            // Continue with other contacts even if one fails
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Members added successfully!')),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Server failed to add members: ${response['message']}');
      }
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
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      setState(() {
        _isOnlineSearching = true;
        _onlineContacts.clear();
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
            const SnackBar(
              content: Text('No contacts found'),
              duration: Duration(seconds: 3),
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

  // New method to show the share group link dialog
  void _showShareLinkDialog() {
    _shareDialogAnimationController?.forward();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ScaleTransition(
          scale: _shareDialogScaleAnimation!,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: white,
            contentPadding: const EdgeInsets.all(20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryTwo.withOpacity(0.1),
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/share.svg', // Ensure you have a share icon in assets
                    width: 40,
                    height: 40,
                    colorFilter: const ColorFilter.mode(
                      primaryTwo,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Share Group Link',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryTwo,
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Invite friends to join the group using this link:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!, width: 0.5),
                  ),
                  child: Text(
                    widget.groupLink,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontFamily: 'monospace',
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTwo,
                        foregroundColor: white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      onPressed: () {
                        FlutterClipboard.copy(widget.groupLink).then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Link copied to clipboard!')),
                          );
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Copy Link',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: primaryTwo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      onPressed: () {
                        Share.share(
                          'Join my group on Cyanase: ${widget.groupLink}',
                          subject: 'Join Our Group!',
                        );
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Share',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      _shareDialogAnimationController?.reverse();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _refreshAnimationController?.dispose();
    _shareDialogAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add Members",
          style: TextStyle(color: white, fontSize: 20),
        ),
        backgroundColor: primaryTwo,
        iconTheme: const IconThemeData(color: white),
        actions: [
          IconButton(
            icon: AnimatedBuilder(
              animation: _refreshAnimationController!,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _refreshAnimationController!.value * 2 * 3.14159,
                  child: const Icon(Icons.refresh, color: white),
                );
              },
            ),
            onPressed:
                _isSyncingContacts || _isLoading ? null : _refreshContacts,
          ),
          IconButton(
            icon: const Icon(Icons.link, color: white), // New share link button
            onPressed: _isLoading ? null : _showShareLinkDialog,
          ),
          IconButton(
            icon: _isLoading
                ? const SizedBox(width: 24, height: 24, child: Loader())
                : const Icon(Icons.check, color: white),
            onPressed: _isLoading ? null : _addMembersToGroup,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_selectedContacts.isNotEmpty)
                Container(
                  height: 100,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                                          : const AssetImage(
                                                  'assets/images/avatar.png')
                                              as ImageProvider,
                                  radius: 30,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  contact['name']?.split(' ').first ??
                                      'Unknown',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _toggleSelection(contact),
                                child: const CircleAvatar(
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
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (query) {
                    if (_debounce?.isActive ?? false) _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 500), () {
                      setState(() {});
                      if (_filterLocalContacts(query).isEmpty) {
                        _searchOnline(query);
                      }
                    });
                  },
                ),
              ),
              if (_isOnlineSearching) const Loader(),
              const SizedBox(height: 10),
              Expanded(
                child: _isLoading
                    ? const Center(child: Loader())
                    : ListView.builder(
                        itemCount: _combinedContacts.length,
                        itemBuilder: (context, index) {
                          final contact = _combinedContacts[index];
                          final contactId = contact['id'].toString();
                          final isSelected =
                              _selectedContactIds.contains(contactId);
                          final isAlreadyMember =
                              _existingMembers.contains(contactId);
                          if (isAlreadyMember) return const SizedBox.shrink();

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: contact['profilePic']
                                          ?.isNotEmpty ==
                                      true
                                  ? NetworkImage(contact['profilePic'])
                                  : const AssetImage('assets/images/avatar.png')
                                      as ImageProvider,
                            ),
                            title: Text(contact['name'] ?? 'Unknown'),
                            subtitle: Text(
                                contact['phone_number'] ?? 'No phone number'),
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
          if (_isSyncingContacts)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryTwo.withOpacity(0.1),
                        ),
                        child: SvgPicture.asset(
                          'assets/icons/groups.svg',
                          width: 60,
                          height: 60,
                          colorFilter: const ColorFilter.mode(
                            primaryTwo,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Refreshing Contacts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryTwo,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Syncing your contacts to find new friends.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 200,
                        child: LinearProgressIndicator(
                          value: _syncProgress,
                          backgroundColor: Colors.grey[300],
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(primaryTwo),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${(_syncProgress * 100).toInt()}% Complete',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
