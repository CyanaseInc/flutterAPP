import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/theme.dart'; // Import your theme file for primaryTwo color
import './personal/personal.dart';
import './group/group.dart';
import './goal/goal.dart';
import './group/new_group.dart';
import '../settings/settings.dart';
import '../auth/login_with_passcode.dart';
import 'package:cyanase/helpers/hash_numbers.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _currentTabTitle = 'Cyanase'; // Default title
  bool _isSearching = false; // To toggle search bar visibility
  final TextEditingController _searchController =
      TextEditingController(); // Controller for search bar

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_updateTabTitle);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSubscriptionReminder();
      _fetchAndHashContacts(); // Call the async function here
    });
  }

  void _fetchAndHashContacts() async {
    await fetchAndHashContacts();
  }

  void _updateTabTitle() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          _currentTabTitle = 'Cyanase'; // Title for Personal tab
          _isSearching = false; // Disable search bar
          break;
        case 1:
          _currentTabTitle = 'Saving Groups'; // Title for Groups tab
          _isSearching =
              false; // Reset search bar state when switching to Groups tab
          break;
        case 2:
          _currentTabTitle = 'My Goals'; // Title for Goals tab
          _isSearching = false; // Disable search bar
          break;
        default:
          _currentTabTitle = 'Cyanase';
          _isSearching = false;
      }
    });
  }

  void _showSubscriptionReminder() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your subscription fees are due. Please ensure payment to continue enjoying our services.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Handle payment navigation
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
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_updateTabTitle); // Remove the listener
    _tabController.dispose();
    _searchController.dispose(); // Dispose the search controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: white,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search groups...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
                style: TextStyle(color: Colors.black),
                onChanged: (value) {
                  // Handle search input
                  print('Search query: $value');
                },
              )
            : Text(
                _currentTabTitle, // Dynamic title based on the selected tab
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
          // Fancy TabBar
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
                insets: EdgeInsets.symmetric(horizontal: 16.0),
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
      // Personal and Goals tabs
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
          child: Text('Settings'),
          value: 'settings',
        ),
        PopupMenuItem(
          child: const Text('New Group'),
          value: 'new_group_investment',
        ),
        PopupMenuItem(
          child: const Text('Logout'),
          value: 'logout',
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
