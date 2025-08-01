import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/get_currency.dart';
import 'package:cyanase/helpers/loader.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/helpers/database_helper.dart';

class PayHelper extends StatefulWidget {
  final String amount;

  final int groupId;
  final VoidCallback onBack;
  final String paymentType;
  final String userId;
  final VoidCallback onPaymentSuccess;
  const PayHelper({
    Key? key,
    required this.amount,
    required this.groupId,
    required this.onBack,
    required this.paymentType,
    required this.userId,
    required this.onPaymentSuccess,
  }) : super(key: key);

  @override
  _PayHelperState createState() => _PayHelperState();
}

class _PayHelperState extends State<PayHelper> {
  bool _isProcessingPayment = false;

  Future<String> fetchUserPhoneNumber() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isEmpty) {
        throw Exception('User profile not found');
      }
      final phone = userProfile.first['phone_number'] as String;
      if (phone.isEmpty) {
        throw Exception('Phone number not found in profile');
      }
      return phone;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching phone number: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      rethrow; // Rethrow to let FutureBuilder handle the error
    }
  }

  double _calculateTotalAmount(double amount) {
    final fee = ((70 / 100) * amount).toStringAsFixed(2);

    return double.parse(fee);
  }

  Future<void> _processPayment() async {
    if (double.tryParse(widget.amount) == null ||
        double.parse(widget.amount) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid payment amount'),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    // Show loading dialog

    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      if (userProfile.isEmpty) {
        throw Exception('User profile not found');
      }

      final token = userProfile.first['token'] as String;
      final userCountry = userProfile.first['country'] as String? ?? 'Unknown';
      final currencyCode = CurrencyHelper.getCurrencyCode(userCountry);
      final reference = 'SUB-${DateTime.now().millisecondsSinceEpoch}';
      final referenceId = DateTime.now().millisecondsSinceEpoch.toString();
      final phoneNumber = userProfile.first['phone_number'] as String;

      final paymentData = {
        "account_no":
            "REL6AEDF95B5A", // TODO: Replace with dynamic account number if applicable
        "reference": "CYANASE-SUB-$reference",
        "internal_reference": reference,
        "amount": widget.amount,
        "currency": currencyCode,
        "reference_id": referenceId,
        "msisdn": phoneNumber,
        "tx_ref": "CYANASE-SUB-$reference",
        "type": widget.paymentType,
        "description": "Annual Subscription Payment",
      };

      final requestPayment =
          await ApiService.requestPayment(token, paymentData);

      if (!requestPayment['success']) {
        throw Exception(requestPayment['message'] ?? 'Payment request failed');
      }
      
      // Wait for transaction status (adjust delay as needed)
      await Future.delayed(const Duration(seconds: 25));
      final authPayment = await ApiService.getTransaction(
        token,
        requestPayment,
      );

      final internalRef = authPayment['transaction']['internal_reference'];
  
      if (authPayment['success']=='success') {
        final data = {
          "group_id": widget.groupId,
          "msisdn": phoneNumber,
          "internal_reference": internalRef,
          "amount": _calculateTotalAmount(double.parse(widget.amount)),
          "charge_amount": widget.amount,
          "type": widget.paymentType,
        };
        final groupSubcription = await ApiService.groupSbscription(token, data);


        if (groupSubcription['success']) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment processed successfully!'),
                duration: Duration(seconds: 5),
              ),
            );
            widget.onPaymentSuccess();
            Navigator.of(context).pop(); // Close PayHelper
          }
        }
      } else {
        throw Exception(
            authPayment['message'] ?? 'Transaction verification failed');
      }
    } catch (e) {
      if (mounted) {
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process payment, check your balance and try again'),
            duration: const Duration(seconds: 8),
          ),
        );
        Navigator.of(context).pop(); // Close loading dialog
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: FutureBuilder<String>(
        key: UniqueKey(), // Ensure FutureBuilder rebuilds on retry
        future: fetchUserPhoneNumber(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: primaryTwo),
                SizedBox(height: 16),
                Text(
                  'Fetching phone number...',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            );
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryTwo,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Unable to fetch phone number. Please try again.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isProcessingPayment
                      ? null
                      : () {
                          setState(() {
                            // Trigger rebuild of FutureBuilder
                          });
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
                  child: const Text(
                    'Retry',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isProcessingPayment ? null : widget.onBack,
                  child: const Text(
                    'Back',
                    style: TextStyle(fontSize: 16, color: primaryTwo),
                  ),
                ),
              ],
            );
          }
          final phoneNumber = snapshot.data!;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Pay Group Subscription',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryTwo,
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
                        const Icon(Icons.phone_android,
                            size: 24, color: primaryTwo),
                        const SizedBox(width: 12),
                        Text(
                          phoneNumber,
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
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Amount: ${widget.amount}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primaryTwo,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _isProcessingPayment ? null : widget.onBack,
                    child: const Text(
                      'Back',
                      style: TextStyle(fontSize: 16, color: primaryTwo),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isProcessingPayment ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTwo,
                      foregroundColor:
                          white, // Fixed: Replaced primaryColor with white
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: _isProcessingPayment
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: Loader(),
                          )
                        : const Text(
                            'Pay',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
