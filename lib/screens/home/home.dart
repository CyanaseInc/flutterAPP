import 'package:cyanase/helpers/loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/theme.dart';
import './personal/personal.dart';
import './group/group.dart';
import './goal/goal.dart';
import './group/new_group.dart';
import '../settings/settings.dart';
import '../auth/login_with_passcode.dart';
import '../auth/set_three_code.dart'; // Ensure this matches your actual file name
import 'package:cyanase/helpers/hash_numbers.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/get_currency.dart';

class HomeScreen extends StatefulWidget {
  final bool? passcode;
  final String? email; // Made email nullable since it wasn't required before

  const HomeScreen({
    super.key, // Modern Flutter key convention
    this.passcode,
    this.email,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _currentTabTitle = 'Cyanase';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_updateTabTitle);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAndHashContacts();
      _initSubscriptionCheck();
    });
  }

  void _fetchAndHashContacts() async {
    try {
      await fetchAndHashContacts();
    } catch (e) {
      // Handle the error silently (e.g., log to a file or retry later)
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
          _currentTabTitle = 'Saving Groups';
          _isSearching = false;
          break;
        case 2:
          _currentTabTitle = 'My Goals';
          _isSearching = false;
          break;
        default:
          _currentTabTitle = 'Cyanase';
          _isSearching = false;
      }
    });
  }

  Future<void> _initSubscriptionCheck() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);

      if (userProfile.isNotEmpty) {
        final token = userProfile.first['token'] as String;

        // Check subscription status first
        final subscriptionResponse = await ApiService.subscriptionStatus(token);

        if (subscriptionResponse['status'] == 'pending') {
          // Show subscription reminder and wait for it to complete
          await _showSubscriptionReminder();
        }

        // Check passcode status
        if (widget.passcode == false || widget.passcode == null) {
          _showPasscodeCreationModal();
        }
      }
    } catch (e) {
      print('Error during initialization: $e');
    }
  }

  Future<void> _showSubscriptionReminder() {
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Subscription Reminder',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryTwo,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your subscription fees are due. Please ensure payment of UGX 20,500 per year to continue enjoying our services.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showPhoneNumberInput();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTwo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Pay Now',
                  style: TextStyle(fontSize: 16, color: primaryColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPhoneNumberInput() {
    TextEditingController phoneController = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 16.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter Your Phone Number',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryTwo,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            String phoneNumber = phoneController.text.trim();
                            if (phoneNumber.isNotEmpty) {
                              setState(() => isLoading = true);
                              _processPayment(phoneNumber, setState);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTwo,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(width: 20, height: 20, child: Loader())
                        : const Text(
                            'Proceed to Pay',
                            style: TextStyle(fontSize: 16, color: primaryColor),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _processPayment(String phoneNumber, StateSetter setState) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);

      if (userProfile.isNotEmpty) {
        final token = userProfile.first['token'] as String;
        final userCountry = userProfile.first['country'] as String;

        final currencyCode = CurrencyHelper.getCurrencyCode(userCountry);
        final response =
            await ApiService.subscriptionPay(token, phoneNumber, currencyCode);

        if (response['status'] == 'pending') {
          _showSubscriptionReminder();
        }
      }
    } catch (e) {
      print('Error: $e');
    }

    // Fixed: Added missing isLoading variable
    Navigator.pop(context);
  }

  void _showPasscodeCreationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryTwo.withOpacity(0.95),
              primaryTwoLight.withOpacity(0.95),
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 40,
                  color: white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Secure Your Account!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                'Add a passcode for quick and secure access to your Cyanase account. It takes just a moment!',
                style: TextStyle(
                  fontSize: 16,
                  color: white.withOpacity(0.9),
                  height: 1.5,
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
                        email: widget.email ?? '', // Handle null case
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Create Now',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryTwo,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Maybe Later',
                  style: TextStyle(
                    color: white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_updateTabTitle);
    _tabController.dispose();
    _searchController.dispose();
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
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                PersonalTab(tabController: _tabController),
                GroupsTab(),
                GoalsTab(),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(width: 2.0, color: primaryTwo),
                insets: const EdgeInsets.symmetric(horizontal: 16.0),
              ),
              labelColor: primaryTwo,
              unselectedLabelColor: primaryTwoLight.withOpacity(0.6),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 14,
              ),
              tabs: [
                Tab(
                  icon: _buildTabIcon(
                    iconPath: 'assets/icons/person.svg',
                    isActive: _tabController.index == 0,
                  ),
                  text: 'Personal',
                ),
                Tab(
                  icon: _buildTabIcon(
                    iconPath: 'assets/icons/groups.svg',
                    isActive: _tabController.index == 1,
                  ),
                  text: 'Groups',
                ),
                Tab(
                  icon: _buildTabIcon(
                    iconPath: 'assets/icons/goal-icon.svg',
                    isActive: _tabController.index == 2,
                  ),
                  text: 'Goals',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabIcon({
    required String iconPath,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive ? primaryTwoLight.withOpacity(0.2) : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: SvgPicture.asset(
        iconPath,
        color: isActive ? primaryTwo : primaryTwoLight.withOpacity(0.6),
        width: 24,
        height: 24,
      ),
    );
  }

  Widget _profile() {
    return Container(
        padding: const EdgeInsets.all(8.0),
        child: const CircleAvatar(
            // backgroundImage: NetworkImage(userAvatarUrl),
            backgroundColor: primaryTwo,
            foregroundColor: Colors.white,
            child: Text('AH')));
  }

  List<Widget> _buildAppBarActions() {
    if (_tabController.index == 1) {
      return [
        IconButton(
          icon: const Icon(Icons.more_vert, color: primaryTwo),
          onPressed: () {
            _showMenu(context);
          },
        ),
      ];
    } else {
      return [
        IconButton(
          icon: const Icon(Icons.more_vert, color: primaryTwo),
          onPressed: () {
            _showMenu(context);
          },
        ),
      ];
    }
  }

  void _showMenu(BuildContext context) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 80, 10, 0),
      items: [
        const PopupMenuItem(
          value: 'settings',
          child: Text('Settings'),
        ),
        const PopupMenuItem(
          value: 'new_group_investment',
          child: Text('New Group'),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Text('Logout'),
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
            builder: (context) => NewGroupScreen(),
          ),
        );
      } else if (value == 'logout') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NumericLoginScreen(),
          ),
        );
      }
    });
  }
}
