import 'package:cyanase/helpers/loader.dart';
import 'package:cyanase/helpers/web_db.dart';
import 'package:cyanase/screens/pay/flutterwave.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/get_currency.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'dart:math';

class DepositHelper extends StatefulWidget {
  final String? selectedFundClass;
  final String? selectedOption;
  final String? depositCategory;
  final String? selectedFundManager;
  final int? selectedOptionId;
  final String? detailText;
  const DepositHelper(
      {super.key,
      this.selectedFundClass,
      this.selectedOption,
      this.selectedFundManager,
      this.selectedOptionId,
      this.detailText,
      this.depositCategory});

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
  void initState() {
    super.initState();
    _getNumber(); // Fetch data when the widget initializes
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

// Helper method to generate a unique reference_id
  String _generateReferenceId() {
    return '${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _getNumber() async {
    try {
      // final dbHelper = DatabaseHelper();
      // final db = await dbHelper.database;
      // final userProfile = await db.query('profile', limit: 1);
      await WebSharedStorage.init();
      var existingProfile = WebSharedStorage();

      final token = existingProfile.getCommon('token');
      final userPhone = existingProfile.getCommon('phone_number');

      // final userPhone = userProfile.first['phone_number'] as String;
      setState(() {
        phonenumber = userPhone;
        // Data has been fetched, stop loading
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Removed white background

      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(), // Allows scrolling left & right
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
    print(method);
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
            // widget.detailText!,
            'hey',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
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

  void submitDepositor() async {
    if (depositAmount == null || depositAmount! <= 0 || phonenumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid amount and phone number')),
      );
    }
    String referenceID() {
      Random random = Random();

      String rand() {
        return random.nextInt(36).toRadixString(
            36); // Generate a random value and convert to base 36
      }

      String ref() {
        return rand() + rand() + rand(); // To make it longer
      }

      return ref();
    }

    setState(() {
      _isSubmitting = true; // Show full-screen preloader
    });

    try {
      // final dbHelper = DatabaseHelper();
      // final db = await dbHelper.database;
      // final userProfile = await db.query('profile', limit: 1);
      // final token = userProfile.first['token'] as String;
      // final userCountry = userProfile.first['country'] as String; // e.g., "UG"
      await WebSharedStorage.init();
      var existingProfile = WebSharedStorage();

      final token = existingProfile.getCommon('token');
      final userCountry = existingProfile.getCommon('country');

      final currency = CurrencyHelper.getCurrencyCode(userCountry);

      // Generate a unique reference and reference_id
      final reference = _generateReference();
      final referenceId = _generateReferenceId();

      // Prepare requestData
      final requestData = {
        "payment_means": _selectedMethod == 'Online' ? 'online' : 'online',
        "deposit_category": widget.depositCategory,
        "deposit_amount": depositAmount!.toString(),
        "currency": currency,
        "investment_id": widget.selectedOptionId ?? "",
        "investment_option": widget.selectedOption ?? "",
        "account_type": "basic",
        "reference": reference,
        "reference_id": referenceId,
        "phone_number": phonenumber,
      };
      print(requestData);
      var amount = requestData['deposit_amount'] as String;

      double getFee() {
        var fee = ((1.4 / 100) * int.parse(amount)).toStringAsFixed(2);
        var result = double.parse(fee);
        return result;
      }

      double relCharge() {
        var fee = (2.5 / 100) * int.parse(amount);
        fee = fee + getFee();
        return fee;
      }

      double getTotalDeposit2() {
        var totalDeposit = getFee() + int.parse(amount) + relCharge();
        return totalDeposit;
      }

      var phone = {
        "msisdn": requestData['phone_number'],
      };
      var data = {
        "account_no": "REL6AEDF95B5A",
        "reference": requestData['reference'],
        "msisdn": requestData['phone_number'],
        "currency": requestData['currency'],
        "amount": getTotalDeposit2(),
        "description": "Payment Request."
      };
      // validate phone number
      final validatePhone = await ApiService.validatePhone(token, phone);
      if (validatePhone['success'] == true) {
        // proceed to request payment
        final requestPayment = await ApiService.requestPayment(token, data);
        if (requestPayment['success'] == true) {
          // get transaction
          final authPayment = await ApiService.getTransaction(token, data);
          if (authPayment['success'] == true) {
            //deposit
            final response = await ApiService.investDeposit(token, requestData);
            if (response['success'] == true) {
              String message = response['message'];
              // If successful, navigate to the success screen
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            } else {
              String message = response['message'];
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            }
          } else {
            String message = authPayment['message'];
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
        } else {
          String message = requestPayment['message'];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      } else {
        String message = validatePhone['message'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to submit deposit. Please try again.')),
      );
    } finally {
      setState(() {
        _isSubmitting = false; // Hide preloader
      });
    }
  }

  Widget _buildMMOption() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight, // Ensures scrolling
            ),
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
                          color: primaryTwo),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Enter how much you want to deposit',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 320,
                      child: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: primaryColor, width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.phone_android,
                                  size: 35, color: primaryTwo),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      phonenumber,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'This number will be used for deposits.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      softWrap: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _textField('Enter Amount'),

                    /// **Submit Button**
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : submitDepositor,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isSubmitting ? Colors.grey : primaryTwo,
                            foregroundColor: white,
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
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight, // Ensures scrolling
            ),
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
        child: TextField(
          keyboardType: TextInputType.number,
          onChanged: (value) {
            setState(() {
              depositAmount = value.isNotEmpty ? double.parse(value) : null;
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
        ));
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
