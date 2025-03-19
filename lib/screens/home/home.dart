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
import 'package:cyanase/helpers/hash_numbers.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/get_currency.dart';

class HomeScreen extends StatefulWidget {
  final bool? passcode;
  final String? email;
  final String? name;
  final String? picture; // Made email nullable since it wasn't required before

  const HomeScreen(
      {super.key, // Modern Flutter key convention
      this.passcode,
      this.email,
      this.name,
      this.picture});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final String? email1 = '';
  final String? name1 = '';
  String? picture1 = '';
  late TabController _tabController;
  String _currentTabTitle = 'Cyanase';
  bool _isSearching = false;
  String Phonenumber = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSyncingContacts = false;
  bool processing = false;
  double _syncProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_updateTabTitle);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initApp();
    });
    getLocalStorage();
  }

  Future<void> _initApp() async {
    // final dbHelper = DatabaseHelper();
    // final existingContacts = await dbHelper.getContacts();

    // if (existingContacts.isEmpty) {
    //   setState(() {
    //     _isSyncingContacts = true;
    //     _syncProgress = 0.0;
    //   });
    //   await _syncContactsForNewUser();
    //   setState(() {
    //     _isSyncingContacts = false;
    //   });
    // }

    // _fetchAndHashContacts();
    _initSubscriptionCheck();
    _getNumber();
  }

  Future<void> _syncContactsForNewUser() async {
    try {
      setState(() => _syncProgress = 0.2);
      final fetchedContacts = await fetchAndHashContacts();

      setState(() => _syncProgress = 0.5);
      final registeredContacts = await getRegisteredContacts(fetchedContacts);

      setState(() => _syncProgress = 0.8);
      final dbHelper = DatabaseHelper();
      await dbHelper.insertContacts(registeredContacts);

      setState(() => _syncProgress = 1.0);
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome aboard! Contacts synced successfully.'),
            backgroundColor: primaryTwo,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _syncProgress = 0.0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Oops! Failed to sync contacts: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: white,
              onPressed: () => _initApp(),
            ),
          ),
        );
      }
    }
  }

  void _fetchAndHashContacts() async {
    try {
      await fetchAndHashContacts();
    } catch (e) {
      // Handle silently
    }
  }

  Future<void> _getNumber() async {
    try {
      // final dbHelper = DatabaseHelper();
      // final db = await dbHelper.database;
      // final userProfile = await db.query('profile', limit: 1);
      // final userPhone = userProfile.first['phone_number'] as String;
      await WebSharedStorage.init();
      var existingProfile = WebSharedStorage();
      final userPhone = existingProfile.getCommon('phone_number');
      setState(() {
        Phonenumber = userPhone;
      });
    } catch (e) {
      print('Error: $e');
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
      // final dbHelper = DatabaseHelper();
      // final db = await dbHelper.database;
      // final userProfile = await db.query('profile', limit: 1);
      await WebSharedStorage.init();
      var existingProfile = WebSharedStorage();

      // if (userProfile.isNotEmpty) {
      if (existingProfile.getCommon('token') != '') {
        // final token = userProfile.first['token'] as String;
        final token = existingProfile.getCommon('token');

        final subscriptionResponse = await ApiService.subscriptionStatus(token);
        print(subscriptionResponse);
        if (subscriptionResponse['status'] == 'pending') {
          await _showSubscriptionReminder();
        }

        if (widget.passcode == false || widget.passcode == null) {
          _showPasscodeCreationModal();
        }
      }
    } catch (e) {
      print('Error during initialization: $e');
    }
  }

  void getLocalStorage() async {
    try {
      // final dbHelper = DatabaseHelper();
      // final db = await dbHelper.database;
      // final userProfile = await db.query('profile', limit: 1);

      await WebSharedStorage.init();
      var existingProfile = WebSharedStorage();

      setState(() {
        picture1 = existingProfile.getCommon('picture');
      });
    } catch (e) {}
    ;
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
                  decoration: TextDecoration.none, // Explicitly no underline
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your subscription fees are due. Please ensure payment of UGX 20,500 per year to continue enjoying our services.',
                style: TextStyle(
                  decoration: TextDecoration.none, // Explicitly no underline
                ),
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
                  style: TextStyle(
                    fontSize: 16,
                    color: primaryColor,
                    decoration: TextDecoration.none, // Explicitly no underline
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPhoneNumberInput() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Scaffold(
            body: Padding(
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
                'Confirm Your Phone Number',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryTwo,
                  decoration: TextDecoration.none, // Explicitly no underline
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.phone_android,
                        size: 35, color: primaryTwo),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Phonenumber,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              decoration: TextDecoration
                                  .none, // Explicitly no underline
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'This number will be used for deposits.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color.fromARGB(255, 30, 30, 30),
                              decoration: TextDecoration
                                  .none, // Explicitly no underline
                            ),
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: processing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTwo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: processing
                    ? const SizedBox(height: 20, width: 20, child: Loader())
                    : const Text('Proceed to Pay'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    decoration: TextDecoration.none, // Explicitly no underline
                  ),
                ),
              ),
            ],
          ),
        ));
      },
    );
  }

  void _processPayment() async {
    setState(() {
      processing = true;
    });
    try {
      // final dbHelper = DatabaseHelper();
      // final db = await dbHelper.database;
      // final userProfile = await db.query('profile', limit: 1);
      await WebSharedStorage.init();
      var existingProfile = WebSharedStorage();

      // if (userProfile.isNotEmpty) {
      if (existingProfile.getCommon('token') != '') {
        // final token = userProfile.first['token'] as String;
        // final userCountry = userProfile.first['country'] as String;
        final token = existingProfile.getCommon('token');
        final userCountry = existingProfile.getCommon('country');
        final phoneNumber = existingProfile.getCommon('phone_number');

        final currencyCode = CurrencyHelper.getCurrencyCode(userCountry);

        // Generate a unique reference and reference_id
        final reference = 'REF-${DateTime.now().millisecondsSinceEpoch}';

        final referenceId = '${DateTime.now().millisecondsSinceEpoch}';

        // Prepare requestData
        final requestData = {
          "deposit_amount": '20500',
          "currency": 'UGX',
          "reference": reference,
          "reference_id": referenceId,
          "phone_number": phoneNumber,
          'tx_ref': "CYANASESUB01-v1"
        };
        var phone = {
          "msisdn": requestData['phone_number'],
        };
        var data = {
          "account_no": "REL6AEDF95B5A",
          "reference": requestData['reference'],
          "msisdn": requestData['phone_number'],
          "currency": requestData['currency'],
          "amount": '20500',
          "description": "Payment Request."
        };
        // validate phone number
        final validatePhone = await ApiService.validatePhone(token, phone);
        if (validatePhone['success'] == true) {
          // proceed to request payment
          final requestPayment = await ApiService.requestPayment(token, data);
          if (requestPayment['success'] == true) {
            // get transaction
            final authPayment = await ApiService.getTransaction(token, data);
            if (authPayment['success'] == true) {
              //deposit
              final response =
                  await ApiService.subscriptionPay(token, requestData);
              if (response['success'] == true) {
                String message = response['message'];
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              } else {
                String message = response['message'];
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              }
            } else {
              String message = authPayment['message'];
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            }
          } else {
            String message = requestPayment['message'];
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
        } else {
          String message = validatePhone['message'];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to subscribe. Please try again.')),
      );
    } finally {
      setState(() {
        processing = false;
      });
    }
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
              color: Colors.grey.withValues(alpha: 0.3),
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
                  color: primaryTwo.withValues(alpha: 0.1),
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
                  decoration: TextDecoration.none, // Explicitly no underline
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                'Add a passcode for quick and secure access to your Cyanase account. It takes just a moment!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.5,
                  decoration: TextDecoration.none, // Explicitly no underline
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: white,
                    decoration: TextDecoration.none, // Explicitly no underline
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
                    decoration: TextDecoration.none, // Explicitly no underline
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
                    GroupsTab(),
                    const GoalsTab(),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: const UnderlineTabIndicator(
                    borderSide: BorderSide(width: 2.0, color: primaryTwo),
                    insets: EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                  labelColor: primaryTwo,
                  unselectedLabelColor: primaryTwoLight.withValues(alpha: 0.6),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    decoration: TextDecoration.none, // Explicitly no underline
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                    decoration: TextDecoration.none, // Explicitly no underline
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
          // Add the syncing contacts overlay here
          if (_isSyncingContacts)
            Container(
              color: Colors.black
                  .withValues(alpha: 0.5), // Matches bottom sheet overlay
              child: Center(
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.3),
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
                          color: primaryTwo.withValues(alpha: 0.1),
                        ),
                        child: SvgPicture.asset(
                          'assets/icons/groups.svg', // Replace with your app logo
                          width: 60,
                          height: 60,
                          colorFilter: const ColorFilter.mode(
                              Colors.blue, BlendMode.clear),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Setting Up Your Cyanase',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryTwo,
                          decoration:
                              TextDecoration.none, // Explicitly no underline
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Syncing your contacts to connect you with friends.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          decoration:
                              TextDecoration.none, // Explicitly no underline
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
                          decoration:
                              TextDecoration.none, // Explicitly no underline
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

  Widget _buildTabIcon({
    required String iconPath,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive
            ? primaryTwoLight.withValues(alpha: 0.2)
            : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: SvgPicture.asset(
        iconPath,
        color: isActive ? primaryTwo : primaryTwoLight.withValues(alpha: 0.6),
        width: 24,
        height: 24,
      ),
    );
  }

  Widget _profile() {
    final picture = widget.picture;
    print(picture);
    return IconButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SettingsPage(),
        ),
      ),
      padding: const EdgeInsets.all(8.0),
      icon: CircleAvatar(
        radius: 30,
        backgroundImage: picture != null
            ? NetworkImage(picture)
            : const AssetImage("assets/images/avatar.png")
                as ImageProvider, // Default image
      ),
    );
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
          child: Text(
            'Settings',
            style: TextStyle(
                decoration: TextDecoration.none), // Explicitly no underline
          ),
        ),
        const PopupMenuItem(
          value: 'new_group_investment',
          child: Text(
            'New Group',
            style: TextStyle(
                decoration: TextDecoration.none), // Explicitly no underline
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Text(
            'Logout',
            style: TextStyle(
                decoration: TextDecoration.none), // Explicitly no underline
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
}
