import 'package:cyanase/helpers/loader.dart';
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

  const GroupInfoPage({
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
  bool _requirePaymentToJoin = false;
  double _paymentAmount = 0.0;
  Map<String, dynamic> _groupDetails = {};
  String _totalBalance = '0.00';
  String _myContributions = '0.00';
  List<GroupSavingGoal> groupGoals = [];
  String _currencySymbol = '\$';
  bool _isAdmin = false; // Track if the user is an admin
  bool isAdminMode = false;
  @override
  void initState() {
    super.initState();
    _loadGroupDetails();
  }

  Future<void> _loadGroupDetails() async {
    setState(() => _isLoading = false);
    await _fetchGroupDetails();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchGroupDetails() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);

      if (userProfile.isEmpty) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final token = userProfile.first['token'] as String;
      final userId = userProfile.first['id'] as String?;
      final userCountry = userProfile.first['country'] as String;
      final currency = CurrencyHelper.getCurrencyCode(userCountry);

      final response = await ApiService.getGroupDetails(
        token: token,
        groupId: widget.groupId,
      );

      if (response['success'] == true) {
        final data = response['data'] ?? {};
        final contributions = data['contributions'] ?? {};

        final participantList =
            (data['members']?['participant_list'] as List?) ?? [];
        final userParticipant = participantList.firstWhere(
          (participant) => participant['user_id'] == userId,
          orElse: () => null,
        );

        if (userParticipant != null) {
          setState(() {
            _isAdmin = userParticipant['role'] == 'admin';
          });
        }

        setState(() {
          _currencySymbol = currency;
          _groupDetails = data;
          _requirePaymentToJoin = data['requirePaymentToJoin'] ?? false;
          isAdminMode = data['restrict_messages_to_admins'] ?? false;
          _paymentAmount = (data['pay_amount'] as num?)?.toDouble() ?? 0.0;
          _totalBalance = _formatCurrency(
              (contributions['group_total'] as num?)?.toDouble() ?? 0.0);
          _myContributions = _formatCurrency(
              (contributions['my_total'] as num?)?.toDouble() ?? 0.0);

          groupGoals = (data['goals'] as List? ?? []).map((goal) {
            return GroupSavingGoal.fromJson(goal, userId!); // Pass userId
          }).toList();
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load group details');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load group details: ${e.toString()}'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _loadGroupDetails,
          ),
        ),
      );
      setState(() {
        _totalBalance = _formatCurrency(0.0);
        _myContributions = _formatCurrency(0.0);
        groupGoals = [];
        _isAdmin = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    return '$_currencySymbol ${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: _isLoading
          ? const Center(child: Loader())
          : ListView(
              children: [
                GroupHeader(
                  groupName: _groupDetails['group_name'] ?? widget.groupName,
                  profilePic: widget.profilePic,
                  groupId: widget.groupId,
                  description:
                      _groupDetails['group_description'] ?? widget.description,
                  totalBalance: _totalBalance,
                  myContributions: _myContributions,
                ),
                const SizedBox(height: 10),
                GroupSavingGoalsSection(
                  groupGoals: groupGoals,
                  groupId: widget.groupId,
                  totalBalance: _totalBalance,
                  myContributions: _myContributions,
                  currencySymbol: '$_currencySymbol',
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
                            inviteCode: _groupDetails['invite_info']
                                    ?['invite_code'] ??
                                '',
                            groupId: widget.groupId.toString(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Show GroupSettings only if user is admin
                if (_isAdmin)
                  GroupSettings(
                    groupId: widget.groupId,
                    isAdminMode: isAdminMode,
                    initialRequirePayment: _requirePaymentToJoin,
                    initialPaymentAmount: _paymentAmount,
                    initialLoanSettings: _groupDetails['loan_settings'] ?? {},
                    onPaymentSettingChanged:
                        (newRequirePayment, newAmount) async {
                      setState(() {
                        _requirePaymentToJoin = newRequirePayment;
                        _paymentAmount = newAmount;
                      });
                    },
                  ),
                GroupMembers(
                  groupId: widget.groupId,
                  isGroup: true,
                  name: _groupDetails['group_name'] ?? widget.groupName,
                  members:
                      (_groupDetails['members']?['participant_list'] as List?)
                              ?.cast<Map<String, dynamic>>() ??
                          [], // Pass participant_list
                ),
                DangerZone(
                  groupId: widget.groupId,
                  groupName: _groupDetails['group_name'] ?? widget.groupName,
                ),
              ],
            ),
    );
  }
}
