// lib/screens/settings/invite.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/providers/provider.dart';

class ReferralPage extends StatefulWidget {
  const ReferralPage({Key? key}) : super(key: key);

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  bool _isWithdrawing = false;

  String _getReferralUrl(String inviteCode) {
    return 'https://cyanase.com/referral/$inviteCode';
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final inviteCode = currencyProvider.inviteCode;
    final referralUrl = _getReferralUrl(inviteCode);
    
    final currentBalance = currencyProvider.currentBalance;
    final totalEarnings = currencyProvider.totalEarnings;
    final totalWithdrawals = currencyProvider.totalWithdrawals;
    final totalInvitations = currencyProvider.totalInvitations;
    final financialCurrencySymbol = currencyProvider.financialCurrencySymbol ?? 
                                   currencyProvider.currencySymbol;
    final bonusBreakdown = currencyProvider.bonusBreakdown;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Earnings Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: primaryTwo,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header Stats with Withdraw Button
          Container(
            padding: const EdgeInsets.all(20),
            color: primaryTwo,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatHeader(
                      'Total Earnings',
                      '$financialCurrencySymbol${totalEarnings.toStringAsFixed(2)}',
                      Colors.white,
                    ),
                    _buildStatHeader(
                      'Current Balance',
                      '$financialCurrencySymbol${currentBalance.toStringAsFixed(2)}',
                      Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isWithdrawing || currentBalance < 100 
                        ? null 
                        : () => _showWithdrawDialog(currentBalance, financialCurrencySymbol),
                    icon: _isWithdrawing 
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: primaryTwo,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.account_balance_wallet, size: 18),
                    label: Text(
                      _isWithdrawing 
                          ? 'Processing...' 
                          : currentBalance < 100
                              ? 'Min: ${financialCurrencySymbol}100 Required'
                              : 'Withdraw Funds',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryTwo,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Invitations Summary Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.groups, size: 18, color: primaryTwo),
                              const SizedBox(width: 8),
                              const Text(
                                'Invitation Summary',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Invitations',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                totalInvitations.toString(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTwo,
                                ),
                              ),
                            ],
                          ),
                      
                        ],
                      ),
                    ),
                  ),
                  
               
                  
                  // How It Works Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, size: 18, color: primaryTwo),
                              const SizedBox(width: 8),
                              const Text(
                                'How It Works',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildWorkStep(
                            1,
                            'Share your referral link with friends',
                          ),
                          _buildWorkStep(
                            2,
                            'Friends sign up using your link',
                          ),
                          _buildWorkStep(
                            3,
                            'Earn ${financialCurrencySymbol}5000 when they complete their first desposit',
                          ),
                          _buildWorkStep(
                            4,
                            'Additional ${financialCurrencySymbol}5000 when they create and subscribe to a group',
                          ),
                          _buildWorkStep(
                            5,
                            'Withdraw when balance reaches ${financialCurrencySymbol}10000 minimum',
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _shareInviteLink(referralUrl),
                              icon: const Icon(Icons.share, size: 16),
                              label: const Text('Share Referral Link'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                side: BorderSide(color: primaryTwo),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Notes Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb, size: 18, color: primaryTwo),
                              const SizedBox(width: 8),
                              const Text(
                                'Important Notes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildNoteItem(
                            'Instant Payout',
                            'Bonuses are credited immediately when requirements are met',
                          ),
                          _buildNoteItem(
                            'No Limits',
                            'Invite unlimited friends - no cap on earnings',
                          ),
                          _buildNoteItem(
                            'Real Cash',
                            'All earnings are withdrawable real money',
                          ),
                          _buildNoteItem(
                            '24/7 Support',
                            'Contact support anytime for assistance',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatHeader(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: primaryTwo,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatBonusType(String type) {
    switch (type) {
      case 'invite': return 'Invitation Bonus';
      case 'signup': return 'Signup Bonus';
      case 'promo': return 'Promotional Bonus';
      case 'group': return 'Group Bonus';
      default: return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  void _showWithdrawDialog(double currentBalance, String currencySymbol) {
    final controller = TextEditingController();
    double amount = currentBalance >= 100 ? 100 : currentBalance;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Withdraw Funds',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Available: $currencySymbol${currentBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '$currencySymbol ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (v) {
                      if (mounted) {
                        setState(() {
                          amount = double.tryParse(v) ?? 0;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    value: amount.clamp(100, currentBalance),
                    min: 100,
                    max: currentBalance,
                    divisions: ((currentBalance - 100) / 10).floor(),
                    label: '$currencySymbol${amount.toStringAsFixed(2)}',
                    onChanged: (v) {
                      if (mounted) {
                        setState(() {
                          amount = v;
                          controller.text = v.toStringAsFixed(2);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (amount >= 100 && amount <= currentBalance) {
                          Navigator.pop(context);
                          _processWithdrawal(amount, currencySymbol);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTwo,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Confirm Withdrawal',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processWithdrawal(double amount, String currencySymbol) async {
    setState(() => _isWithdrawing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isWithdrawing = false);
    _showSuccessSnackbar('Withdrawal of $currencySymbol${amount.toStringAsFixed(2)} requested successfully.');
  }

  void _shareInviteLink(String referralUrl) {
    final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
    final inviteCode = currencyProvider.inviteCode;
    final currencySymbol = currencyProvider.currencySymbol;
    
    final msg = '''
Join Cyanase using my referral code: $inviteCode


$referralUrl
''';
    Share.share(msg);
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}