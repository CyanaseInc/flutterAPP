import 'package:cyanase/helpers/loader.dart';
import 'package:flutter/material.dart';
import 'group_header.dart';
import 'group_settings.dart';
import 'group_members.dart';
import 'danger_zone.dart';
import 'group_manager.dart';
import 'invite.dart';
import 'group_saving_goal.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/get_currency.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this import

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

class _GroupInfoPageState extends State<GroupInfoPage> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _requirePaymentToJoin = false;
  double _paymentAmount = 0.0;
  Map<String, dynamic> _groupDetails = {};
  String _totalBalance = '0.00';
  String _interestEarned = '0.00';
  String _myContributions = '0.00';
  List<GroupSavingGoal> groupGoals = [];
  String _currencySymbol = '\$';
  bool _isAdmin = false;
  bool isAdminMode = false;
  bool _allowWithdraw = false;
  String _currentProfilePic = '';
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _currentProfilePic = widget.profilePic;
    _tabController = TabController(length: 2, vsync: this);
    _loadGroupDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleProfilePicChanged(String newProfilePic) {
    setState(() {
      _currentProfilePic = newProfilePic;
    });
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

        if (userParticipant != null && mounted) {
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
          _interestEarned = _formatCurrency(
              (contributions['my_interest'] as num?)?.toDouble() ?? 0.0);
          _myContributions = _formatCurrency(
              (contributions['my_total'] as num?)?.toDouble() ?? 0.0);
          groupGoals = (data['goals'] as List? ?? []).map((goal) {
            return GroupSavingGoal.fromJson(goal, userId!);
          }).toList();
          _allowWithdraw = data['is_withdraw'] ?? false;
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
        _allowWithdraw = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    return '$_currencySymbol ${amount.toStringAsFixed(2)}';
  }

  void _updateWithdrawSetting(bool newValue) {
    setState(() {
      _allowWithdraw = newValue;
    });
  }

  // Function to show the Finance Management Modal
 // Function to show the Finance Management Modal
void _showFinanceManagementModal() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with solid primaryTwo color
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryTwo,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 50,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Advanced Finance Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
  'Get the complete Admin experience on desktop',
  style: TextStyle(
    color: Colors.grey[700],
    fontSize: 14,
    height: 1.5,
  ),
  textAlign: TextAlign.center,
),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.public,
                            color: Colors.blue[700],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'invest.cyanase.app',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Features list
                    _buildFeatureRow(Icons.auto_graph, 'Investment Tracking'),
                    _buildFeatureRow(Icons.account_balance, 'Loan Management'),
                    _buildFeatureRow(Icons.analytics, 'Advanced Analytics'),
                    _buildFeatureRow(Icons.report, 'Detailed Reports'),
                    
                    const SizedBox(height: 25),
                    
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close modal first
                              // Then navigate to traditional finance page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GroupFinancePage(
                                    groupId: widget.groupId,
                                  ),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              side: BorderSide(color: Colors.grey[300]!),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Start in App'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              const url = 'https://invest.cyanase.app';
                              if (await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(Uri.parse(url));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Could not launch $url'),
                                  ),
                                );
                              }
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryTwo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Open Url'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: primaryTwo,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: _isLoading
          ? const Center(child: Loader())
          : Column(
              children: [
                const SizedBox(height: 40),
                GroupHeader(
                  groupName: _groupDetails['group_name'] ?? widget.groupName,
                  profilePic: _currentProfilePic,
                  groupId: widget.groupId,
                  description:
                      _groupDetails['group_description'] ?? widget.description,
                  totalBalance: _totalBalance,
                  myContributions: _myContributions,
                  initialLoanSettings: _groupDetails['loan_settings'] ?? {},
                  isAdmin: _isAdmin,
                  allowWithdraw: _allowWithdraw,
                  groupLink: _groupDetails['invite_info']?['invite_code'] ?? '',
                  onProfilePicChanged: _handleProfilePicChanged,
                ),
                const SizedBox(height: 10),
                
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: primaryTwo,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: primaryTwo,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: 'Group goals'),
                      Tab(text: 'Manage group'),
                    ],
                  ),
                ),
                
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGoalsTab(),
                      _buildManageTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildGoalsTab() {
    return ListView(
      children: [
        GroupSavingGoalsSection(
          groupGoals: groupGoals,
          groupId: widget.groupId,
          totalBalance: _totalBalance,
          myContributions: _myContributions,
          currencySymbol: '$_currencySymbol',
          isAdmin: _isAdmin,
        ),
      ],
    );
  }

  Widget _buildManageTab() {
    return ListView(
      children: [
        Container(
          color: white,
          margin: const EdgeInsets.only(top: 8.0),
          child: ListTile(
            title: const Text(
              'Finance Management',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'Manage group Investments and Loans',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showFinanceManagementModal, // Updated to show modal
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
            subtitle: const Text(
              'Share invite link with friends',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
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
        if (_isAdmin)
          GroupSettings(
            groupId: widget.groupId,
            isAdminMode: isAdminMode,
            initialRequireSubscription:
                _groupDetails['requireSubscription'] ?? false,
            initialSubscriptionAmount:
                (_groupDetails['subscription_amount'] as num?)
                        ?.toDouble() ??
                    0.0,
            initialRequirePayment: _requirePaymentToJoin,
            initialPaymentAmount: _paymentAmount,
            initialLoanSettings: _groupDetails['loan_settings'] ?? {},
            initialIsWithdraw: _allowWithdraw,
            onPaymentSettingChanged:
                (bool newRequirePayment, double newAmount) async {
              setState(() {
                _requirePaymentToJoin = newRequirePayment;
                _paymentAmount = newAmount;
              });
            },
            onWithdrawSettingChanged: _updateWithdrawSetting,
          ),
        GroupMembers(
          groupId: widget.groupId,
          isGroup: true,
          name: _groupDetails['group_name'] ?? widget.groupName,
          members:
              (_groupDetails['members']?['participant_list'] as List?)
                      ?.cast<Map<String, dynamic>>() ??
                  [],
        ),
        DangerZone(
          groupId: widget.groupId,
          groupName: _groupDetails['group_name'] ?? widget.groupName,
        ),
      ],
    );
  }
}