// lib/screens/settings/invite.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cyanase/theme/theme.dart';

class ReferralPage extends StatefulWidget {
  final String inviteCode;
  final double totalEarnings;

  const ReferralPage({
    Key? key,
    required this.inviteCode,
    required this.totalEarnings,
  }) : super(key: key);

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  bool _isWithdrawing = false;

  // NEW: Correct referral URL
  String get _referralUrl => 'https://cyanase.com/referral/${widget.inviteCode}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Refer & Earn"),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        backgroundColor: primaryTwo,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          children: [
            _buildEarningsCard(),
            const SizedBox(height: 28),
            _buildHeroCard(),
            const SizedBox(height: 28),
            _buildInviteCard(),
            const SizedBox(height: 28),
            _buildShareCard(),
            const SizedBox(height: 28),
            _buildHowItWorksCard(),
          ],
        ),
      ),
    );
  }

  // ———————————————————————
  // 1. EARNINGS CARD
  // ———————————————————————
  Widget _buildEarningsCard() {
    return _premiumCard(
      topColor: primaryTwo,
      child: Column(
        children: [
          const Text(
            'Total Earnings',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black54),
          ),
          const SizedBox(height: 14),
          Text(
            '\$${widget.totalEarnings.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: primaryTwo,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Min withdrawal: \$100.00',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isWithdrawing ? null : () => _showWithdrawDialog(),
              icon: _isWithdrawing
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.account_balance_wallet, size: 15),
              label: Text(_isWithdrawing ? 'Processing...' : 'Withdraw Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTwo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
                shadowColor: primaryTwo.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ———————————————————————
  // 2. HERO ILLUSTRATION
  // ———————————————————————
  Widget _buildHeroCard() {
    return _premiumCard(
      topColor: secondaryColor,
      child: Column(
        children: const [
          Icon(Icons.card_giftcard_rounded, size: 68, color: primaryTwo),
          SizedBox(height: 18),
          Text(
            'Invite Friends,\nEarn Big Rewards',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          SizedBox(height: 10),
          Text(
            'You earn \$50 per friend. They get a bonus too!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ———————————————————————
  // 3. INVITE CODE CARD
  // ———————————————————————
  Widget _buildInviteCard() {
    return _premiumCard(
      topColor: primaryTwo,
      child: Column(
        children: [
          const Text(
            'Your Invite Code',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              color: primaryTwo.withOpacity(0.08),
              border: Border.all(color: primaryTwo.withOpacity(0.4), width: 2.5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: SelectableText(
              widget.inviteCode,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryTwo,
                letterSpacing: 5,
                fontFamily: 'RobotoMono',
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _copyToClipboard(),
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTwo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ———————————————————————
  // 4. SHARE CARD
  // ———————————————————————
  Widget _buildShareCard() {
    return _premiumCard(
      topColor: secondaryColor,
      hasBottomBorder: true,
      child: Column(
        children: [
          const Text(
            'Share With Friends',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _socialIcon(Icons.facebook, const Color(0xFF1877F2), () => _shareVia('facebook')),
              _socialIcon(Icons.email, const Color(0xFFEA4335), () => _shareVia('email')),
              _socialIcon(Icons.share, Colors.grey[700]!, _share),
            ],
          ),
        ],
      ),
    );
  }

  Widget _socialIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6)),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            icon == Icons.facebook ? 'Facebook' : icon == Icons.email ? 'Email' : 'More',
            style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ———————————————————————
  // 5. HOW IT WORKS
  // ———————————————————————
  Widget _buildHowItWorksCard() {
    return _premiumCard(
      topColor: primaryTwo,
      child: Column(
        children: [
          const Icon(Icons.emoji_events, size: 52, color: primaryTwo),
          const SizedBox(height: 16),
          const Text(
            'How It Works',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          const Text(
            '• Share your code with friends\n'
            '• They sign up → \n'
            '• You earn \$50 instantly\n'
            '• If they create an group → \n'
            '• You earn \$150 bonus instantly\n'
            '• Withdraw anytime after \$100',
            textAlign: TextAlign.left,
            style: TextStyle(color: Colors.black54, fontSize: 15, height: 1.7),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _shareInviteLink, // ← Now uses correct URL
              icon: const Icon(Icons.send_rounded, size: 20),
              label: const Text('Share Invite Link'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryTwo,
                side: BorderSide(color: primaryTwo, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ———————————————————————
  // PREMIUM CARD
  // ———————————————————————
  Widget _premiumCard({
    required Widget child,
    required Color topColor,
    bool hasBottomBorder = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: topColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
          if (hasBottomBorder) _dashedLine(),
        ],
      ),
    );
  }

  Widget _dashedLine() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: CustomPaint(
        size: const Size(double.infinity, 1),
        painter: _DashedLinePainter(),
      ),
    );
  }

  // ———————————————————————
  // WITHDRAW DIALOG
  // ———————————————————————
  void _showWithdrawDialog() {
    final controller = TextEditingController();
    double amount = 100;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Withdraw Earnings', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Balance: \$${widget.totalEarnings.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: InputDecoration(
                prefixText: '\$ ',
                labelText: 'Amount',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: primaryTwo, width: 2),
                ),
              ),
              onChanged: (v) => setState(() => amount = double.tryParse(v) ?? 0),
            ),
            const SizedBox(height: 16),
            Slider(
              value: amount.clamp(100, widget.totalEarnings),
              min: 100,
              max: widget.totalEarnings,
              divisions: ((widget.totalEarnings - 100) / 10).floor(),
              label: amount.toStringAsFixed(2),
              activeColor: primaryTwo,
              onChanged: (v) {
                setState(() {
                  amount = v;
                  controller.text = v.toStringAsFixed(2);
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (amount >= 100 && amount <= widget.totalEarnings) {
                Navigator.pop(context);
                _processWithdrawal(amount);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryTwo),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _processWithdrawal(double amount) async {
    setState(() => _isWithdrawing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isWithdrawing = false);
    _snack('Withdrawal of \$${amount.toStringAsFixed(2)} requested!');
  }

  // ———————————————————————
  // UTILS – SHARE (UPDATED)
  // ———————————————————————
  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.inviteCode));
    _snack('Code copied!');
  }

  void _shareVia(String platform) {
    final msg = 'Join Cyanase with my code **${widget.inviteCode}** and we both earn \$50!\n\n$_referralUrl';
    Share.share(msg);
  }

  void _share() => _shareVia('more');

  void _shareInviteLink() => _shareVia('more'); // ← Uses correct URL

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: primaryTwo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ———————————————————————
// DASHED LINE PAINTER
// ———————————————————————
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.5;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + 7, 0), paint);
      startX += 12;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}