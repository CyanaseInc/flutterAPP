import 'package:flutter/material.dart';
import '../../theme/theme.dart'; // Import your theme file for primaryTwo color
import './personal/personal.dart';
import './group/group.dart';
import './goal/goal.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSubscriptionReminder();
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
                  // Handle payment navigation
                  Navigator.pop(context);
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
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryTwo,
        titleSpacing: 16,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cyanase',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 25,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {
                _showMenu(context);
              },
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicator: UnderlineTabIndicator(
            borderSide:
                BorderSide(width: 4.0, color: Colors.white), // Highlight
            insets: EdgeInsets.symmetric(horizontal: 16.0), // Add spacing
          ),
          labelColor: Colors.white,
          unselectedLabelColor:
              Colors.white.withOpacity(0.6), // Dim inactive tabs
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(icon: Icon(Icons.group_work), text: 'Personal'),
            Tab(icon: Icon(Icons.chat_bubble), text: 'Groups'),
            Tab(icon: Icon(Icons.flag), text: 'Goals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PersonalTab(),
          GroupsTab(),
          GoalsTab(),
        ],
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 80, 10, 0),
      items: [
        PopupMenuItem(
          child: const Text('Settings'),
          value: 'settings',
        ),
        PopupMenuItem(
          child: const Text('New Group'),
          value: 'new_group_investment',
        ),
      ],
    ).then((value) {
      if (value == 'settings') {
        print("Settings selected");
      } else if (value == 'new_group_investment') {
        print("New Group Investment selected");
      }
    });
  }
}
