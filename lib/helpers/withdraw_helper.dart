import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/get_currency.dart';
import 'package:cyanase/helpers/loader.dart';

import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:flutter/services.dart';
import 'package:cyanase/helpers/subscription_helper.dart';
import 'package:cyanase/helpers/xcel_payment_helper.dart';

class WithdrawHelper extends StatefulWidget {
  final String withdrawType;
  final String withdrawDetails;
  final String? investmentId;
  final int? groupId;
  final int? goalId;
  final VoidCallback? onWithdrawProcessed;

  const WithdrawHelper({
    required this.withdrawType,
    required this.withdrawDetails,
    this.groupId,
    this.goalId,
    this.investmentId,
    this.onWithdrawProcessed,
    Key? key,
  }) : super(key: key);

  @override
  _WithdrawHelperState createState() => _WithdrawHelperState();
}

class _WithdrawHelperState extends State<WithdrawHelper> {
  String? withdrawMethod;
  String? phoneNumber;
  String? bankDetails;
  double? withdrawAmount;
  SubscriptionQuote? _subscriptionQuote;
  int currentStep = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _getNumber();
  }

  void nextStep() {
    setState(() {
      currentStep++;
    });
  }

  void previousStep() {
    setState(() {
      currentStep--;
    });
  }

  String _generateReference() {
    // Generate a timestamp-based reference with only valid characters
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'WD_${timestamp.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '')}';
  }

  double _calculateTotalAmount(double amount) {
    final fee = ((1 / 100) * amount).toStringAsFixed(2);
    return amount + double.parse(fee);
  }

  final DatabaseHelper _dbHelper = DatabaseHelper();
  Future<void> _getNumber() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      final userPhone = userProfile.first['phone_number'] as String;
      setState(() {
        phoneNumber = userPhone;
      });
    } catch (e) {
      
    }
  }

  Future<void> _processPayment(
    BuildContext sheetContext,
    VoidCallback onPayStart,
    VoidCallback onPayEnd,
  ) async {
    if (!mounted) return;
    final hostContext = context;

    onPayStart();

    try {
      final db = await _dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isEmpty) {
        throw Exception('User profile not found');
      }

      final token = userProfile.first['token'] as String;
      var quote = _subscriptionQuote;
      if (quote == null) {
        final statusResp = await ApiService.subscriptionStatus(token);
        quote = parseSubscriptionQuote(statusResp);
      }
      final msisdn = phoneNumber ?? '';
      final reference = 'CYSUB${DateTime.now().millisecondsSinceEpoch}';

      final paymentData = {
        "reference": reference,
        "amount": quote.amount,
        "currency": quote.currency,
        "msisdn": msisdn,
        "type": "cyanase_subscription",
        "description": "Annual Subscription Payment",
      };

      final requestPayment =
          await ApiService.requestPayment(token, paymentData);

      if (!requestPayment['success']) {
        final msg = requestPayment['message']?.toString().trim();
        throw Exception(
          msg != null && msg.isNotEmpty ? msg : 'Payment request failed',
        );
      }

      final authPayment = await finalizeMobileMoneyPayment(
        context: sheetContext,
        token: token,
        requestPayment: requestPayment,
      );

      if (!mounted) return;
      Navigator.pop(sheetContext);

      final success = authPayment['success'] == true;
      final message = authPayment['message']?.toString() ??
          (success ? 'Subscription payment successful' : 'Payment not completed');

      ScaffoldMessenger.of(hostContext).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Your subscription is now active.'
                : message,
          ),
          duration: Duration(seconds: success ? 4 : 6),
        ),
      );

      if (success) {
        Navigator.of(hostContext).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(hostContext).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      onPayEnd();
    }
  }

  void _showPhoneNumberInput() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        var paying = false;
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
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
                              formatPhoneNumber(phoneNumber!),
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
                    onPressed: paying
                        ? null
                        : () => _processPayment(
                              sheetContext,
                              () => setSheetState(() => paying = true),
                              () => setSheetState(() => paying = false),
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTwo,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: paying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(white),
                            ),
                          )
                        : const Text(
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
                    onPressed:
                        paying ? null : () => Navigator.pop(sheetContext),
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
            );
          },
        );
      },
    );
  }

  Future<void> _showSubscriptionReminder(SubscriptionQuote quote) async {
    final price = formatSubscriptionPrice(quote.amount);
    final currency = quote.currency;
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
                'Pay now',
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

  Future<Map<String, dynamic>> _processWithdraw({
    required String token,
    required Map<String, dynamic> requestData,
  }) async {
    switch (widget.withdrawType) {
      case 'goal':
        return await ApiService.goalWithdraw(token, requestData);
      case 'group_goal_withdraw':
        
        return await ApiService.groupGoalWithdraw(token, requestData);
      case 'portfolio':
        return await ApiService.withdraw(token, requestData);
      case 'Group_deposit_withdraw':
        return await ApiService.withdrawRequest(token, requestData);
      case 'group_user_withdraw':
        return await ApiService.userWithdrawRequest(token, requestData);
      case 'user_goals':
        return await ApiService.withdraw(token, requestData);
      case 'group_subscription_withdraw':
        return await ApiService.groupSubscriptionWithdraw(token, requestData);
      default:
        return {'error': 'Invalid withdraw type'};
    }
  }

  Future<void> submitWithdrawal() async {
    if (withdrawAmount == null ||
        withdrawAmount! <= 0 ||
        withdrawMethod == null ||
        (withdrawMethod == 'bank' &&
            (bankDetails == null || bankDetails!.isEmpty))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid amount and details'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isEmpty) {
        throw Exception('User profile not found');
      }
      final token = userProfile.first['token'] as String;
      final name = userProfile.first['name'] as String? ?? '';

      final userCountry = userProfile.first['country'] as String? ?? 'Unknown';
      final currency = CurrencyHelper.getCurrencyCode(userCountry);

      final subscriptionResponse = await ApiService.subscriptionStatus(token);
      if (subscriptionResponse['status'] == 'pending') {
        final quote = parseSubscriptionQuote(subscriptionResponse);
        setState(() {
          _subscriptionQuote = quote;
        });
        _showSubscriptionReminder(quote);
        throw Exception('Please complete your subscription payment first');
      }

      final paymentData = {
        'account_no': 'REL6AEDF95B5A',
        'payment_means':
            withdrawMethod == 'mobile_money' ? 'mobile_money' : 'bank',
        'reference': _generateReference(),
        'msisdn': phoneNumber,
        "charge_amount":
            _calculateTotalAmount(withdrawAmount!).toStringAsFixed(2),
        'bank_details': withdrawMethod == 'bank' ? bankDetails : null,
        'currency': currency,
        'amount': withdrawAmount,
        'description': 'Withdrawal Request',
        'tx_ref': 'CYANASE-WITHDRAW-${DateTime.now().millisecondsSinceEpoch}',
        'type': widget.withdrawType,
        'group_id': widget.groupId,
        'goal_id': widget.goalId,
        'beneficiary_name': name,
        'investment_id': widget.investmentId,
      };

      final response = await _processWithdraw(
        token: token,
        requestData: paymentData,
      );

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Payment request failed');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Withdrawal request submitted successfully'),
        ),
      );

      // Call the onWithdrawProcessed callback if provided
      if (widget.onWithdrawProcessed != null) {
        widget.onWithdrawProcessed!();
      }

      Navigator.pop(context); // Close the withdraw dialog
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (currentStep == 0) buildWithdrawMethodStep(),
          if (currentStep == 1) _buildOption(withdrawMethod),
          if (currentStep == 2) buildConfirmStep(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (currentStep > 0)
                ElevatedButton(
                  onPressed: _isSubmitting ? null : previousStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: primaryTwo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Back',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              if (currentStep < 2)
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          if (currentStep == 0 && withdrawMethod != null) {
                            nextStep();
                          } else if (currentStep == 1 &&
                              withdrawAmount != null &&
                              withdrawAmount! > 0) {
                            nextStep();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTwo,
                    foregroundColor: white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Next',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              if (currentStep == 2)
                ElevatedButton(
                  onPressed: _isSubmitting ? null : submitWithdrawal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTwo,
                    foregroundColor: white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: Loader(),
                        )
                      : const Text('Confirm',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildWithdrawMethodStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Select a method to proceed with your withdrawal',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            GestureDetector(
              onTap: _isSubmitting
                  ? null
                  : () {
                      setState(() {
                        withdrawMethod = 'mobile_money';
                      });
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: withdrawMethod == 'mobile_money'
                      ? LinearGradient(
                          colors: [
                            primaryTwo.withOpacity(0.1),
                            primaryTwo.withOpacity(0.2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: withdrawMethod == 'mobile_money' ? null : primaryLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: withdrawMethod == 'mobile_money'
                        ? primaryTwo
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.phone_android,
                      size: 36,
                      color: withdrawMethod == 'mobile_money'
                          ? primaryTwo
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mobile Money',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: withdrawMethod == 'mobile_money'
                                  ? primaryTwo
                                  : Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fast and secure transfers to your mobile wallet',
                            style: TextStyle(
                              fontSize: 12,
                              color: withdrawMethod == 'mobile_money'
                                  ? primaryTwo.withOpacity(0.8)
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (withdrawMethod == 'mobile_money')
                      Icon(
                        Icons.check_circle,
                        color: primaryTwo,
                        size: 24,
                      ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: _isSubmitting
                  ? null
                  : () {
                      setState(() {
                        withdrawMethod = 'bank';
                      });
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: withdrawMethod == 'bank'
                      ? LinearGradient(
                          colors: [
                            primaryTwo.withOpacity(0.1),
                            primaryTwo.withOpacity(0.2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: withdrawMethod == 'bank' ? null : primaryLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: withdrawMethod == 'bank'
                        ? primaryTwo
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance,
                      size: 36,
                      color: withdrawMethod == 'bank'
                          ? primaryTwo
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bank Transfer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: withdrawMethod == 'bank'
                                  ? primaryTwo
                                  : Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Direct deposit to your bank account',
                            style: TextStyle(
                              fontSize: 12,
                              color: withdrawMethod == 'bank'
                                  ? primaryTwo.withOpacity(0.8)
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (withdrawMethod == 'bank')
                      Icon(
                        Icons.check_circle,
                        color: primaryTwo,
                        size: 24,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOption(String? method) {
    if (method == 'mobile_money') {
      return buildMobileMoneyStep();
    } else {
      return buildBankDetailsStep();
    }
  }

  Widget buildMobileMoneyStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mobile Money Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primaryLight,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.phone, size: 24, color: primaryTwo),
                  const SizedBox(width: 12),
                  Text(
                    phoneNumber ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryTwo,
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
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'Amount',
            filled: true,
            fillColor: primaryLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          onChanged: (value) {
            setState(() {
              withdrawAmount = double.tryParse(value);
            });
          },
          enabled: !_isSubmitting,
        ),
      ],
    );
  }

  Widget buildBankDetailsStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const Text(
        //   'Bank Details',
        //   style: TextStyle(
        //     fontSize: 16,
        //     fontWeight: FontWeight.w600,
        //     color: Colors.grey,
        //   ),
        // ),
        const Text(
          'Send a request to our email at support@cyanase.com',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        // const SizedBox(height: 16),
        // TextField(
        //   decoration: InputDecoration(
        //     labelText: 'Bank Details (e.g., Account Number, Bank Name)',
        //     filled: true,
        //     fillColor: primaryLight,
        //     border: OutlineInputBorder(
        //       borderRadius: BorderRadius.circular(12),
        //       borderSide: BorderSide.none,
        //     ),
        //   ),
        //   keyboardType: TextInputType.text,
        //   onChanged: (value) {
        //     setState(() {
        //       bankDetails = value;
        //     });
        //   },
        //   enabled: !_isSubmitting,
        // ),
        // const SizedBox(height: 16),
        // TextField(
        //   decoration: InputDecoration(
        //     labelText: 'Amount',
        //     filled: true,
        //     fillColor: primaryLight,
        //     border: OutlineInputBorder(
        //       borderRadius: BorderRadius.circular(12),
        //       borderSide: BorderSide.none,
        //     ),
        //   ),
        //   keyboardType: const TextInputType.numberWithOptions(decimal: true),
        //   inputFormatters: [
        //     FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        //   ],
        //   onChanged: (value) {
        //     setState(() {
        //       withdrawAmount = double.tryParse(value);
        //     });
        //   },
        //   enabled: !_isSubmitting,
        // ),
      ],
    );
  }

  Widget buildConfirmStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primaryLight,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.withdrawDetails,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryTwo,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Amount: ${withdrawAmount?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                withdrawMethod == 'mobile_money'
                    ? 'To: Mobile Money ($phoneNumber)'
                    : 'To: Bank ($bankDetails)',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Please review the details above',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

// Helper function to format phone number
String formatPhoneNumber(String phone) {
  if (phone.length < 10) return phone;
  return '${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6)}';
}
