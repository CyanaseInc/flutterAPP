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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String? picture1;
  late TabController _tabController;
  String _currentTabTitle = 'Cyanase';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isSyncingContacts = false;
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
    if (widget.passcode == false || widget.passcode == null) {
      _showPasscodeCreationModal();
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

  void getLocalStorage() async {
    try {
      await WebSharedStorage.init();
      var existingProfile = WebSharedStorage();
      setState(() {
        picture1 = existingProfile.getCommon('picture');
      });
    } catch (e) {
      print('Error getting local storage: $e');
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
                    color:
                        _tabController.index == 0 ? primaryLight : Colors.white,
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(height: 2),
                  const Text('Invest'),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),
                  SvgPicture.asset(
                    'assets/icons/groups.svg',
                    color:
                        _tabController.index == 1 ? primaryLight : Colors.white,
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(height: 2),
                  const Text('Groups'),
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
                    color:
                        _tabController.index == 2 ? primaryLight : Colors.white,
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
    final picture = widget.picture ?? picture1;
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
        backgroundImage: picture != null && picture.isNotEmpty
            ? NetworkImage(picture)
            : const AssetImage("assets/images/avatar.png") as ImageProvider,
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
}
