import 'package:flutter/material.dart';
import 'group_header.dart';
import 'group_settings.dart';
import 'group_members.dart';
import 'danger_zone.dart';
import 'group_stat.dart';
import 'invite.dart';
import 'group_saving_goal.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/get_currency.dart';

class GroupInfoPage extends StatefulWidget {
  final String groupName;
  final String profilePic;
  final int groupId;
  final String description;

  GroupInfoPage({
    Key? key,
    required this.groupName,
    required this.profilePic,
    required this.groupId,
    required this.description,
  }) : super(key: key);

  @override
  _GroupInfoPageState createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  bool _isLoading = false;
  Map<String, dynamic> _groupDetails = {};
  String _totalBalance = '0.00'; // Default without symbol
  String _myContributions = '0.00'; // Default without symbol
  List<GroupSavingGoal> groupGoals = [];
  String _currencySymbol = '\$'; // Default symbol, updated dynamically

  @override
  void initState() {
    super.initState();
    _loadGroupDetails();
  }

  Future<void> _loadGroupDetails() async {
    setState(() => _isLoading = true);
    await _fetchGroupDetails();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchGroupDetails() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);

      if (userProfile.isEmpty) {
        throw Exception('User profile not found');
      }

      final token = userProfile.first['token'] as String;
      final userCountry = userProfile.first['country'] as String;
      final currency = CurrencyHelper.getCurrencyCode(userCountry);

      // Set the dynamic currency symbol
      setState(() {
        _currencySymbol = currency;
      });

      final response = await ApiService.getGroupDetails(
        token: token,
        groupId: widget.groupId,
      );
      print('response $response');
      // Initialize default values
      double totalDeposits = 0.0;
      double myTotal = 0.0;
      List<Map<String, dynamic>> goals = [];
      Map<String, dynamic> data = {};

      if (response['success'] == true) {
        data = response['data'] ?? {};
        final contributions = data['my_contributions'] ?? {};

        // Safely parse numeric values with null checks
        totalDeposits =
            (data['total_group_deposits'] as num?)?.toDouble() ?? 0.0;
        myTotal = (contributions['total'] as num?)?.toDouble() ?? 0.0;
        goals = List<Map<String, dynamic>>.from(data['group_goals'] ?? []);
      } else {
        throw Exception(response['message'] ?? 'Failed to load group details');
      }

      setState(() {
        _groupDetails = data;
        _totalBalance = _formatCurrency(totalDeposits);
        _myContributions = _formatCurrency(myTotal);
        groupGoals = goals
            .map((goal) => GroupSavingGoal(
                  goalId: goal['goal_id'] as int?,
                  goalName: goal['goal_name'] as String? ?? 'Unnamed Goal',
                  goalAmount:
                      (goal['target_amount'] as num?)?.toDouble() ?? 0.0,
                  currentAmount:
                      (goal['current_amount'] as num?)?.toDouble() ?? 0.0,
                  startDate: goal['start_date'] as String?,
                  endDate: goal['end_date'] as String?,
                  status: goal['status'] as String? ?? 'inactive',
                ))
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load group details: ${e.toString()}'),
          duration: Duration(seconds: 3),
        ),
      );
      setState(() {
        _totalBalance = _formatCurrency(0.0);
        _myContributions = _formatCurrency(0.0);
        groupGoals = [];
      });
    }
  }

  // Helper function to format currency with dynamic symbol
  String _formatCurrency(double amount) {
    return '$_currencySymbol ${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: ListView(
        children: [
          GroupHeader(
            groupName: _groupDetails['group_name'] ?? widget.groupName,
            profilePic: widget.profilePic,
            groupId: widget.groupId,
            description: widget.description,
            totalBalance: _totalBalance,
            myContributions: _myContributions,
          ),
          Container(
            color: white,
            margin: const EdgeInsets.only(top: 8.0),
            child: ListTile(
              title: const Text(
                'Invite to group',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InviteScreen(
                      groupName:
                          _groupDetails['group_name'] ?? widget.groupName,
                      profilePic: widget.profilePic,
                      groupId: widget.groupId.toString(),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            color: white,
            margin: const EdgeInsets.only(top: 8.0),
            child: ListTile(
              title: const Text(
                'Group finance info',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupFinancePage(
                      groupId: widget.groupId,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          GroupSavingGoalsSection(
            groupGoals: groupGoals,
            groupId: widget.groupId,
            totalBalance: '', // Empty since it's already in GroupHeader
            myContributions: '', // Empty since it's already in GroupHeader
          ),
          GroupSettings(groupId: widget.groupId),
          GroupMembers(
              groupId: widget.groupId, isGroup: true, name: widget.groupName),
          DangerZone(
            groupId: widget.groupId,
            groupName: _groupDetails['group_name'] ?? widget.groupName,
          ),
        ],
      ),
    );
  }
}
