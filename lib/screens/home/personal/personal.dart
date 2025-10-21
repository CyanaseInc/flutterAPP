//import 'package:cyanase/helpers/web_db.dart';
import 'package:cyanase/helpers/loader.dart';
import 'package:cyanase/screens/home/personal/conversion.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/theme.dart';
import './sample_goals.dart';
import './portifolio.dart';
import './card.dart';
import './deposit_withdraw_buttons.dart';
import './fund_manager.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/get_currency.dart';
import 'package:cyanase/helpers/subscription_helper.dart';

class PersonalTab extends StatefulWidget {
  final TabController tabController;

  const PersonalTab({Key? key, required this.tabController}) : super(key: key);

  @override
  _PersonalTabState createState() => _PersonalTabState();
}

class _PersonalTabState extends State<PersonalTab> {
  double _totalDepositUGX = 0.0;
  double _totalDepositUSD = 0.0;
  double _totalNetworthy = 0.0;
  double _totalNetworthyUSD = 0.0;
  String currency = '';
  String Phonenumber = '';
  String SubscriptionFee = '';
  bool processing = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _initTab();
  }

  Future<void> _initTab() async {
    await _checkAndShowSubscriptionModal();
    await _getNumber();
    await _getDepositNetworth();
  }

  Future<void> _getNumber() async {
    try {
      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isEmpty) {
        throw Exception('User profile not found');
      }
      final userPhone = userProfile.first['phone_number'] as String;

      setState(() {
        Phonenumber = userPhone;
      });
    } catch (e) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load profile data')),
      );
    }
  }

  Future<void> _checkAndShowSubscriptionModal() async {
    try {
      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isEmpty) return;

      final token = userProfile.first['token'] as String;
      final subscriptionResponse = await ApiService.subscriptionStatus(token);

      if (subscriptionResponse['status'] == 'pending') {
        _showSubscriptionReminder();
      }
    } catch (e) {
      
    }
  }

  Future<void> _showSubscriptionReminder() async {
    final price = subscriptionPrices[currency]?.toStringAsFixed(2) ?? '20,500';
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.star_border,
              size: 48,
              color: primaryTwo,
            ),
            const SizedBox(height: 16),
            const Text(
              'Subscribe',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryTwo,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'All cyanase users are required to pay $currency $price/year in subscription fees. Save smarter, achieve your goals!',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showPhoneNumberInput();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTwo,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Subscribe Now',
                style: TextStyle(
                  fontSize: 16,
                  color: primaryColor,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Maybe Later',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhoneNumberInput() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Confirm Payment Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryTwo,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 24, color: primaryTwo),
                      const SizedBox(width: 12),
                      Text(
                        formatPhoneNumber(Phonenumber),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryTwo,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Payment will be processed using this number',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: processing ? null : () => _processPayment(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTwo,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Confirm Payment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: white,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(BuildContext context) async {
    setState(() => processing = true);

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Loader(),
                SizedBox(height: 16),
                Text(
                  'Processing Payment ....',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryTwo,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isEmpty) {
        throw Exception('User profile not found');
      }

      final token = userProfile.first['token'] as String;
      final userCountry = userProfile.first['country'] as String;
      final currencyCode = CurrencyHelper.getCurrencyCode(userCountry);
      final reference = 'SUB-${DateTime.now().millisecondsSinceEpoch}';
      final referenceId = DateTime.now().millisecondsSinceEpoch.toString();

      final amount = subscriptionPrices[currencyCode] ?? 20500.0;
      final paymentData = {
        "account_no": "REL6AEDF95B5A",
        "reference": "CYANASE-SUB-${DateTime.now().millisecondsSinceEpoch}",
        'internal_reference': reference,
        "amount": amount,
        "currency": currencyCode,
        "reference_id": referenceId,
        "msisdn": Phonenumber,
        "tx_ref": "CYANASE-SUB-${DateTime.now().millisecondsSinceEpoch}",
        "type": "cyanase_subscription",
        "description": "Annual Subscription Payment",
      };

      final requestPayment =
          await ApiService.requestPayment(token, paymentData);

      if (!requestPayment['success']) {
        throw Exception(requestPayment['message']);
      }
// Wait for 30 seconds before checking transaction status
      await Future.delayed(const Duration(seconds: 25));
      final authPayment =
          await ApiService.getTransaction(token, requestPayment);
      // Close loading dialog
      
      Navigator.pop(context);

      // Show result dialog
      _showPaymentResultDialog(
          context, authPayment['success'], authPayment['message']);

    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error dialog
      _showPaymentResultDialog(context, false, e.toString());
    } finally {
      setState(() => processing = false);
    }
  }

  void _showPaymentResultDialog(
      BuildContext context, bool success, String message) {
    // First, close any loading dialog that might be open
    Navigator.pop(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error_outline,
                size: 48,
                color: success ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                success ? 'Payment Successful!' : 'Payment Failed',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryTwo,
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                success
                    ? 'Your subscription is now active. Enjoy all premium features!'
                    : message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close result dialog
                  if (success) {
                    // Close all modals and bottom sheets by popping until we reach the main screen
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTwo,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal:
                        32, // Increased horizontal padding for wider button
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  success ? 'Continue' : 'Try Again',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              if (!success) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close result dialog
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String formatNumberWithCommas(double number) {
    final formatter = NumberFormat('#,###');
    return formatter.format(number);
  }

  Future<void> _getDepositNetworth() async {
    try {
      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);

      if (userProfile.isNotEmpty) {
        final token = userProfile.first['token'] as String;
        final userCountry = userProfile.first['country'] as String;
        final currencyCode = CurrencyHelper.getCurrencyCode(userCountry);

        final response = await ApiService.depositNetworth(token);
        final userTrack = await ApiService.userTrack(token);
        final totalNet = response['data']['net_worth'];
        
  
        if (userTrack['success'] == true) {
          double totalDeposit = 0;
          double totalWithdraw = 0;
          
          for (var track in userTrack['data']) {
            totalDeposit += track['deposit_amount'] + track['opening_balance'];
            totalWithdraw += track['closing_balance'];

          }
          var conversion = Conversion(currencyCode.toLowerCase(),
              totalWithdraw < 0 ? totalWithdraw * -1 : totalWithdraw, 'usd');
          var result = await conversion.executeConversion();
          var depositConversion = Conversion(currencyCode.toLowerCase(),
              totalDeposit < 0 ? totalDeposit * -1 : totalDeposit, 'usd');
          var depositUSD = await depositConversion.executeConversion();
          setState(() {
            _totalDepositUGX = totalDeposit;
            _totalDepositUSD = double.parse(depositUSD);
            _totalNetworthy = totalNet;
            _totalNetworthyUSD = double.parse(result);
            currency = currencyCode;
          });
        }
      }
    } catch (e) {
      
    }
  }

  @override
 @override
@override
Widget build(BuildContext context) {
  return SingleChildScrollView(
    physics: const ClampingScrollPhysics(),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Portfolio(currency: currency),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryTwo),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'My Portfolio',
                style: TextStyle(
                  color: primaryTwo,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TotalDepositsCard(
            depositLocal: formatNumberWithCommas(_totalDepositUGX),
            depositForeign: formatNumberWithCommas(_totalDepositUSD),
            currency: currency,
          ),
          const SizedBox(height: 10),
          DepositWithdrawButtons(),
          const SizedBox(height: 10),
          NetworthCard(
            networthLocal: formatNumberWithCommas(_totalNetworthy),
            currency: currency,
            networthForeign: formatNumberWithCommas(_totalNetworthyUSD),
          ),
          const SizedBox(height: 20),
          const Text(
            'Investment options',
            style: TextStyle(
              color: primaryTwo,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          FundManagerSlider(),
          const SizedBox(height: 20),
          const Text(
            'My Goals',
            style: TextStyle(
              color: primaryTwo,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SampleGoals(
            onGoalTap: () {
              widget.tabController.animateTo(2);
            },
          ),
        ],
      ),
    ),
  );
}
}

// Helper function to format phone number
String formatPhoneNumber(String phone) {
  if (phone.length < 10) return phone;
  return '${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6)}';
}
