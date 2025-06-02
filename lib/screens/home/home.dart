import 'package:cyanase/helpers/endpoints.dart';
import 'package:cyanase/helpers/loader.dart';
import 'package:cyanase/helpers/web_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/theme.dart';
import './personal/personal.dart';
import './group/group.dart';
import './goal/goal.dart';
import './group/new_group.dart';
import '../settings/settings.dart';
import '../auth/login_with_passcode.dart';
import '../auth/set_three_code.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:cyanase/helpers/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cyanase/screens/home/group/chat_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool? passcode;
  final String? email;
  final String? name;
  final String? picture;

  const HomeScreen({
    super.key,
    this.passcode,
    this.email,
    this.name,
    this.picture,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String? picture1;
  late TabController _tabController;
  String _currentTabTitle = 'Cyanase';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isSyncingContacts = false;
  double _syncProgress = 0.0;
  int _totalUnreadCount = 0;
  Timer? _unreadCheckTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_updateTabTitle);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initApp();
      _checkUnreadMessages();
      _startUnreadCheckTimer();
      _setupNotificationHandler();
    });
  }

  Future<void> _initApp() async {
    if (widget.passcode == false || widget.passcode == null) {
      _showPasscodeCreationModal();
    }
    await _checkAndSyncContacts();
  }

  Future<void> _checkAndSyncContacts() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final contacts = await db.query('contacts');
      if (contacts.isEmpty && mounted) {
        setState(() {
          _isSyncingContacts = true;
          _syncProgress = 0.0;
        });
        await _syncContacts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check contacts: $e'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _checkAndSyncContacts,
            ),
          ),
        );
      }
    }
  }

  Future<void> _syncContacts() async {
    try {
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
      if (mounted) {
        setState(() {
          _isSyncingContacts = false;
          _syncProgress = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts synced successfully!')),
        );
      }
    } catch (e) {
      print('Sync error: $e');
      if (mounted) {
        setState(() {
          _isSyncingContacts = false;
          _syncProgress = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync contacts: $e'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _syncContacts,
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

  void _updateTabTitle() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          _currentTabTitle = 'Cyanase';
          _isSearching = false;
          break;
        case 1:
          _currentTabTitle = 'Saving groups';
          _isSearching = false;
          break;
        case 2:
          _currentTabTitle = 'My goals';
          _isSearching = false;
          break;
        default:
          _currentTabTitle = 'Cyanase';
          _isSearching = false;
      }
    });
  }

  // void getLocalStorage() async {
  //   try {
  //     await WebSharedStorage.init();
  //     var existingProfile = WebSharedStorage();
  //     setState(() {
  //       picture1 =
  //     });
  //   } catch (e) {
  //     print('Error getting local storage: $e');
  //   }
  // }

  void _showPasscodeCreationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryTwo.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 40,
                  color: primaryTwo,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Secure Your Account!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryTwo,
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                'Add a passcode for quick and secure access to your Cyanase account.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.5,
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SetCodeScreen(
                        email: widget.email ?? '',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTwo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Create Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: white,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Maybe Later',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startUnreadCheckTimer() {
    _unreadCheckTimer?.cancel();
    _unreadCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkUnreadMessages();
    });
  }

  void _setupNotificationHandler() {
    print('🔵 [HomeScreen] Setting up notification handler');
    // Initialize notification service
    NotificationService().initialize().then((_) {
      print('🔵 [HomeScreen] Notification service initialized');
      // Set up notification tap handler
      NotificationService().setNotificationTapHandler((response) {
        print('🔵 [HomeScreen] Notification tapped');
        print('🔵 [HomeScreen] Payload: ${response.payload}');
        _handleNotificationTap(response);
      });
      print('🔵 [HomeScreen] Notification tap handler set up');
    }).catchError((error) {
      print('🔴 [HomeScreen] Error initializing notification service: $error');
    });
  }

  void _handleNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;

    try {
      final payload = jsonDecode(response.payload!);
      final groupId = payload['groupId'];
      final messageId = payload['messageId'];

      if (groupId != null) {
        // Switch to groups tab
        _tabController.animateTo(1);
        
        // Navigate to the specific chat
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MessageChatScreen(
                name: 'Group Chat', // You might want to fetch the actual group name
                profilePic: '',
                groupId: int.parse(groupId),
                description: '',
                isAdminOnlyMode: false,
                isCurrentUserAdmin: false,
                allowSubscription: false,
                hasUserPaid: true,
                subscriptionAmount: '0',
              ),
            ),
          );
        });
      }
    } catch (e) {
      print('Error handling notification tap: $e');
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_updateTabTitle);
    _tabController.dispose();
    _searchController.dispose();
    _unreadCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: white,
        leading: _profile(),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search groups...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
                style: const TextStyle(color: Colors.black),
                onChanged: (value) {},
              )
            : Text(
                _currentTabTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryTwo,
                  fontSize: 25,
                ),
              ),
        automaticallyImplyLeading: false,
        actions: _buildAppBarActions(),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    PersonalTab(tabController: _tabController),
                    GroupsTab(
                      onUnreadCountChanged: updateUnreadCount,
                    ),
                    const GoalsTab(),
                  ],
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
                              primaryTwo, BlendMode.srcIn),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Setting Up Your Cyanase',
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
                        'Syncing your contacts to connect you with friends.',
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
      bottomNavigationBar: Container(
        color: primaryTwo,
        width: double.infinity,
        height: 70,
        child: TabBar(
          controller: _tabController,
          indicator: const BoxDecoration(),
          labelColor: primaryLight,
          unselectedLabelColor: Colors.white,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
            decoration: TextDecoration.none,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
            decoration: TextDecoration.none,
          ),
          tabs: [
            Tab(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),
                  SvgPicture.asset(
                    'assets/icons/person.svg',
                    color: _tabController.index == 0 ? primaryLight : Colors.white,
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(height: 2),
                  const Text('Invest'),
                ],
              ),
            ),
            Tab(
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 4),
                      SvgPicture.asset(
                        'assets/icons/groups.svg',
                        color: _tabController.index == 1 ? primaryLight : Colors.white,
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(height: 2),
                      const Text('Groups'),
                    ],
                  ),
                  if (_totalUnreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryTwo, width: 2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _totalUnreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),
                  SvgPicture.asset(
                    'assets/icons/goal-icon.svg',
                    color: _tabController.index == 2 ? primaryLight : Colors.white,
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(height: 2),
                  const Text('Goals'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profile() {
    final picture = widget.picture != null
        ? ApiEndpoints.server + '/' + widget.picture!
        : "assets/images/avatar.png";
    return IconButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SettingsPage(),
        ),
      ),
      padding: const EdgeInsets.all(8.0),
      icon: CircleAvatar(
        radius: 20,
        backgroundImage: widget.picture != null
            ? NetworkImage(picture) as ImageProvider
            : const AssetImage("assets/images/avatar.png"),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      IconButton(
        icon: const Icon(Icons.more_vert, color: primaryTwo),
        onPressed: () {
          _showMenu(context);
        },
      ),
    ];
  }

  void _showMenu(BuildContext context) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 80, 10, 0),
      items: [
        const PopupMenuItem(
          value: 'settings',
          child: Text(
            'Settings',
            style: TextStyle(decoration: TextDecoration.none),
          ),
        ),
        const PopupMenuItem(
          value: 'new_group_investment',
          child: Text(
            'New Group',
            style: TextStyle(decoration: TextDecoration.none),
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Text(
            'Logout',
            style: TextStyle(decoration: TextDecoration.none),
          ),
        ),
      ],
    ).then((value) {
      if (value == 'settings') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SettingsPage(),
          ),
        );
      } else if (value == 'new_group_investment') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NewGroupScreen(),
          ),
        );
      } else if (value == 'logout') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NumericLoginScreen(),
          ),
        );
      }
    });
  }

  void updateUnreadCount(int count) {
    if (mounted) {
      setState(() {
        _totalUnreadCount = count;
      });
    }
  }

  Future<void> _checkUnreadMessages() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      
      final unreadMessages = await db.query(
        'messages',
        where: 'isMe = 0 AND status = ?',
        whereArgs: ['unread'],
      );
      
      if (mounted) {
        setState(() {
          _totalUnreadCount = unreadMessages.length;
        });
      }
    } catch (e) {
      print('Error checking unread messages: $e');
    }
  }
}
