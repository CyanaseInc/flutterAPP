import 'package:cyanase/helpers/loader.dart';
import 'package:cyanase/helpers/web_db.dart';
import 'package:cyanase/screens/pay/flutterwave.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/get_currency.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'dart:math';
import 'package:flutter/services.dart';

class DepositHelper extends StatefulWidget {
  final String? selectedFundClass;
  final String? selectedOption;
  final String? depositCategory;
  final String? selectedFundManager;
  final int? selectedOptionId;
  final String? detailText;
  final int groupId;
  const DepositHelper(
      {super.key,
      this.selectedFundClass,
      this.selectedOption,
      this.selectedFundManager,
      this.selectedOptionId,
      this.detailText,
      this.depositCategory,
      required this.groupId});

  @override
  _DepositScreenState createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositHelper> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  String? _selectedMethod;
  String phonenumber = '';
  bool _isSubmitting = false;
  double? depositAmount = 0;

  @override
  void initState() {
    super.initState();
    _getNumber();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String _generateReference() {
    return 'REF-${DateTime.now().millisecondsSinceEpoch}';
  }

  String _generateReferenceId() {
    return '${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _getNumber() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      final userPhone = userProfile.first['phone_number'] as String;
      setState(() {
        phonenumber = userPhone;
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<Map<String, dynamic>> _processDeposit({
    required String token,
    required Map<String, dynamic> requestData,
  }) async {
    switch (widget.depositCategory) {
      case 'personal_invest':
        return await ApiService.investDeposit(token, requestData);
      case 'group_deposit':
        return await ApiService.groupDeposit(token, requestData);
      default:
        throw Exception('Invalid deposit category: ${widget.depositCategory}');
    }
  }

  double _calculateTotalAmount(double amount) {
    final fee = ((1 / 100) * amount).toStringAsFixed(2);

    return double.parse(fee) + amount;
  }

  void submitDepositor() async {
    if (depositAmount == null || depositAmount! <= 0 || phonenumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter valid amount and phone number')),
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
      final token = userProfile.first['token'] as String;
      final userCountry = userProfile.first['country'] as String;
      final currency = CurrencyHelper.getCurrencyCode(userCountry);

      final requestData = {
        "payment_means": _selectedMethod == 'Online' ? 'online' : 'online',
        "deposit_category": widget.depositCategory,
        "deposit_amount": depositAmount!.toStringAsFixed(2),
        "currency": currency,
        "investment_id": widget.selectedOptionId?.toString() ?? "",
        "investment_option": widget.selectedOption ?? "",
        "account_type": "basic",
        "reference": _generateReference(),
        "reference_id": _generateReferenceId(),
        "phone_number": phonenumber,
        "type": widget.depositCategory,
      };

      final paymentData = {
        "account_no": "REL6AEDF95B5A",
        "reference": requestData['reference'],
        "msisdn": requestData['phone_number'],
        "currency": requestData['currency'],
        "amount": _calculateTotalAmount(depositAmount!).toStringAsFixed(2),
        "description": "Payment Request",
        "tx_ref":
            "CYANASE-${widget.depositCategory}-${DateTime.now().millisecondsSinceEpoch}",
        "type": "${widget.depositCategory}_deposit",
      };

      final requestPayment =
          await ApiService.requestPayment(token, paymentData);

      if (requestPayment['success'] == true) {
        await Future.delayed(const Duration(seconds: 25));
        final authPayment =
            await ApiService.getTransaction(token, requestPayment);
        final internalRef = authPayment['transaction']['internal_reference'];

        final myData = {
          "group_id": widget.groupId,
          "msisdn": phonenumber,
          "internal_reference": internalRef,
          "amount": depositAmount,
          "charge_amount":
              _calculateTotalAmount(depositAmount!).toStringAsFixed(2),
        };

        if (authPayment['success'] == true) {
          final response = await _processDeposit(
            token: token,
            requestData: myData,
          );
          print('my reponse is $response');
          if (response['success'] == true) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response['message'])),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response['message'])),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(authPayment['message'])),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(requestPayment['message'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit deposit: ${e.toString()}')),
      );
      print('Failed to submit deposit: ${e.toString()}');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentStep = index;
          });
        },
        children: [
          _buildChooseDepositMethod(),
          _buildOption(_selectedMethod),
          _buildSuccessScreen(),
        ],
      ),
    );
  }

  Widget _buildOption(String? method) {
    if (method == 'Mobile Money') {
      return _buildMMOption();
    } else {
      return _buildBankOption();
    }
  }

  Widget _buildChooseDepositMethod() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Choose Deposit Method',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: primaryTwo),
          ),
          const SizedBox(height: 10),
          const Text(
            'Let us know how you want to deposit',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          _depositOption('Mobile Money', Icons.phone_android),
          const SizedBox(height: 10),
          _depositOption('Bank Transfer', Icons.account_balance),
        ],
      ),
    );
  }

  Widget _depositOption(String method, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
        _nextStep();
      },
      child: SizedBox(
        width: 320,
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            child: Row(
              children: [
                Icon(icon, size: 30),
                const SizedBox(width: 10),
                Text(
                  method,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMMOption() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Padding(padding: EdgeInsets.only(top: 8)),
                    const Text(
                      'Deposit via Mobile Money',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryTwo,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Enter how much you want to deposit',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
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
                              const Icon(Icons.phone,
                                  size: 24, color: primaryTwo),
                              const SizedBox(width: 12),
                              Text(
                                phonenumber,
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
                    const SizedBox(height: 10),
                    _textField('Enter Amount'),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : submitDepositor,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isSubmitting ? Colors.grey : primaryTwo,
                            foregroundColor: primaryLight,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20, width: 20, child: Loader())
                              : const Text('Submit'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBankOption() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: const IntrinsicHeight(
              child: Center(
                  child: FlutterPay(
                amount: 0,
                name: '',
                data: '',
                email: '',
                currency: '',
              )),
            ),
          ),
        );
      },
    );
  }

  Widget _textField(String label) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      child: TextFormField(
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        onChanged: (value) {
          setState(() {
            depositAmount =
                value.isNotEmpty ? double.tryParse(value) ?? 0.0 : null;
          });
        },
        decoration: InputDecoration(
          labelText: label,
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: primaryColor),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: primaryLight),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/web.png',
            width: 120,
            height: 100,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          const Text(
            'Deposit Successful!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }
}
