import 'package:cyanase/helpers/endpoints.dart';
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
import './transactions_screen.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:url_launcher/url_launcher.dart'; // Added
import 'package:flutter/gestures.dart';

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
  String? _currentPicture;
  late TabController _tabController;
  String _currentTabTitle = 'Cyanase';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isSyncingContacts = false;
  double _syncProgress = 0.0;
  int _totalUnreadCount = 0;
  Timer? _unreadCheckTimer;
  int _notificationCount = 0;
  bool _isLoadingNotifications = false;

  @override
  void initState() {
    super.initState();
    _currentPicture = widget.picture;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_updateTabTitle);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initApp();
      _checkUnreadMessages();
      _startUnreadCheckTimer();
      _setupNotificationHandler();
      _getProfilePicture();
      _fetchNotificationCount();
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
        // Show disclosure and get consent before syncing
        bool? consentGiven = await _showContactAccessDisclosure();
        if (consentGiven == true) {
          setState(() {
            _isSyncingContacts = true;
            _syncProgress = 0.0;
          });
          await _syncContacts();
        } else {
          // Handle case where user denies consent
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    'Contact access is required to find friends on Cyanase for savings groups.'),
                action: SnackBarAction(
                  label: 'Retry',
                  onPressed: _checkAndSyncContacts,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSyncingContacts = false;
          _syncProgress = 0.0;
        });
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

Future<bool?> _showContactAccessDisclosure() async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // Prevent dismissing by tapping outside
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        backgroundColor: white,
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 400), // Responsive width
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon for visual appeal
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryTwo.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  'assets/icons/groups.svg', // Use an appropriate icon from your assets
                  width: 40,
                  height: 40,
                  colorFilter: const ColorFilter.mode(primaryTwo, BlendMode.srcIn),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              const Text(
                'Access Your Contacts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryTwo,
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Description
              const Text(
                'Cyanase needs access to your contacts to find friends already on Cyanase, so you can create savings groups together. Your contacts are not uploaded or stored.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.4,
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Privacy Policy Link
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: 'See our ',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    decoration: TextDecoration.none,
                  ),
                  children: [
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        fontSize: 14,
                        color: primaryTwo,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: primaryTwo,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          const url = 'https://www.cyanase.app/privacy-policy'; // Replace with your actual privacy policy URL
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open Privacy Policy')),
                            );
                          }
                        },
                    ),
                    const TextSpan(text: ' for details.'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    foregroundColor: Colors.grey[600],
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Deny',
                    style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                    ),
                  ),
                  ),
                  ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTwo,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Allow',
                    style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: white,
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
  );
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

  Future<List<Map<String, String>>> fetchAndHashContacts() async {
    List<Map<String, String>> contactsWithHashes = [];
    PermissionStatus permissionStatus = await Permission.contacts.request();
    if (permissionStatus != PermissionStatus.granted) {
      throw Exception("Permission to access contacts denied");
    }
    setState(() {
      _syncProgress = 0.3;
    });
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
            // Log error if needed, but continue processing other contacts
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

  void _updateProfilePicture(String? newPicture) {
    setState(() {
      _currentPicture = newPicture;
    });
  }

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
    NotificationService().initialize().then((_) {
      NotificationService().setNotificationTapHandler((response) {
        _handleNotificationTap(response);
      });
    }).catchError((error) {
      // Handle error if needed
    });
  }

  void _handleNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;

    try {
      final payload = jsonDecode(response.payload!);
      final groupId = payload['groupId'];
      final messageId = payload['messageId'];

      if (groupId != null) {
        _tabController.animateTo(1);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MessageChatScreen(
                name: 'Group Chat',
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
      // Handle error if needed
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
    return IconButton(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SettingsPage(
              onProfileUpdate: _updateProfilePicture,
            ),
          ),
        );
      },
      padding: const EdgeInsets.all(8.0),
      icon: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.transparent,
        backgroundImage: _currentPicture != null && _currentPicture!.isNotEmpty
            ? NetworkImage(ApiEndpoints.server + '/' + _currentPicture!) as ImageProvider
            : const AssetImage("assets/images/avatar.png"),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: primaryTwo),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionsScreen(),
                ),
              );
            },
          ),
          if (_isLoadingNotifications)
            const Positioned(
              right: 8,
              top: 8,
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              ),
            )
          else if (_notificationCount > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  '$_notificationCount',
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
      // Handle error if needed
    }
  }

  Future<void> _getProfilePicture() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isNotEmpty && mounted) {
        setState(() {
          _currentPicture = userProfile.first['profile_pic'] as String?;
        });
      }
    } catch (e) {
      // Handle error if needed
    }
  }

  Future<void> _fetchNotificationCount() async {
    setState(() {
      _isLoadingNotifications = true;
    });
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isNotEmpty) {
        final token = userProfile.first['token'] as String;
        final count = await ApiService.fetchNotificationCount(token);
        if (mounted) {
          setState(() {
            _notificationCount = count;
          });
        }
      }
    } catch (e) {
      // Handle error if needed
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNotifications = false;
        });
      }
    }
  }
}