import 'package:cyanase/helpers/loader.dart';
//import 'package:cyanase/screens/pay/flutterwave.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/get_currency.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:flutter/services.dart';

class DepositHelper extends StatefulWidget {
  final String? selectedFundClass;
  final String? selectedOption;
  final String? depositCategory;
  final String? selectedFundManager;
  final int? selectedOptionId;
  final String? detailText;
  final int? groupId;
  final int? loanId;
  final int? goalId;
  const DepositHelper({
    super.key,
    this.selectedFundClass,
    this.selectedOption,
    this.selectedFundManager,
    this.selectedOptionId,
    this.detailText,
    this.depositCategory,
    this.groupId,
    this.loanId,
    this.goalId,
  });

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
  final TextEditingController _bankAmountController = TextEditingController();
  bool _isCopying = false;

  @override
  void initState() {
    super.initState();
    _getNumber();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_selectedMethod == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a deposit method')),
        );
        return;
      }
    } else if (_currentStep == 1) {
      if (_selectedMethod == 'Mobile Money') {
        if (depositAmount == null || depositAmount! <= 0 || phonenumber.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid amount and phone number')),
          );
          return;
        }
      } else if (_selectedMethod == 'Bank Transfer') {
        if (_bankAmountController.text.isEmpty ||
            double.tryParse(_bankAmountController.text) == null ||
            double.parse(_bankAmountController.text) <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid deposit amount')),
          );
          return;
        }
      }
    }
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
      case 'group_goal_deposit':
        return await ApiService.goalContribute(token, requestData);
      case 'pay_loan':
        return await ApiService.payLoan(token, requestData);
      case 'group_top_up':
        return await ApiService.groupTopUp(token, requestData);
      case 'group_investment_interest':
        return await ApiService.addInterest(token, requestData);
        case 'personal_goals':
        return await ApiService.personalGoal(token,requestData);
      default:
        throw Exception('Invalid deposit category: ${widget.depositCategory}');
    }
  }

  double _calculateTotalAmount(double amount) {
    final fee = ((1 / 100) * amount).toStringAsFixed(2);
    return double.parse(fee) + amount;
  }

  void _copyBankDetails() async {
    const bankDetails = '''
Bank Name: Cyanase Bank
Account Name: Cyanase Investments
Account Number: 1234567890
Bank Code: CYA123
SWIFT Code: CYANUS33
    ''';
    await Clipboard.setData(ClipboardData(text: bankDetails.trim()));
    setState(() {
      _isCopying = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bank details copied to clipboard!')),
    );
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isCopying = false;
    });
  }

  void submitDepositor() async {
    if (_selectedMethod == 'Bank Transfer' &&
        (_bankAmountController.text.isEmpty ||
            double.tryParse(_bankAmountController.text) == null ||
            double.parse(_bankAmountController.text) <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid deposit amount')),
      );
      return;
    }

    if (_selectedMethod == 'Mobile Money' &&
        (depositAmount == null || depositAmount! <= 0 || phonenumber.isEmpty)) {
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
      if (_selectedMethod == 'Bank Transfer') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Please make the deposit using the provided bank details and send proof of payment to support@cyanase.com'),
            duration: Duration(seconds: 5),
          ),
        );
      } else {
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
             "payment_means": _selectedMethod == 'Online' ? 'online' : 'online',
             "deposit_category": widget.depositCategory,
            "msisdn": phonenumber,
            "internal_reference": internalRef,
            "amount": depositAmount,
            "charge_amount":
                _calculateTotalAmount(depositAmount!).toStringAsFixed(2),
            "goal_id": widget.goalId,
            "loan_id": widget.loanId,
            "investment_id": widget.selectedOptionId,
            "currency": currency,
            "account_type": "basic",
            "reference": _generateReference(),
          "reference_id": _generateReferenceId(),
          "tx_ref":_generateReference(),
           
          };

          if (authPayment['success'] == true) {
            final response = await _processDeposit(
              token: token,
              requestData: myData,
            );

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
            SnackBar(content: Text('Payment request failed')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit deposit')),
      );
      
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
        physics: const NeverScrollableScrollPhysics(),
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
                Icon(icon, size: 30, color: primaryTwo),
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
                          onPressed: (_isSubmitting || depositAmount == null || depositAmount! <= 0)
                              ? null
                              : submitDepositor,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                (_isSubmitting || depositAmount == null || depositAmount! <= 0) ? Colors.grey : primaryTwo,
                            foregroundColor: primaryLight,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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
            child: IntrinsicHeight(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Deposit via Bank Transfer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryTwo,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Use the bank details below to make your deposit. After payment, please send proof of payment to support@cyanase.com.',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryLight,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Bank Details',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: primaryTwo,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _copyBankDetails,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _isCopying
                                          ? Colors.green.withOpacity(0.2)
                                          : primaryTwo.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _isCopying ? Icons.check : Icons.copy,
                                          size: 16,
                                          color: primaryTwo,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _isCopying ? 'Copied' : 'Copy',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: primaryTwo,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildBankDetailRow(
                                'Bank Name', 'Diamond Trust bank'),
                            _buildBankDetailRow('Account Name',
                                'Cyanase technology \nand investment ltd'),
                            _buildBankDetailRow('Account Number', '0190514001'),
                            _buildBankDetailRow('SWIFT Code', 'DTKEUGKAXXX'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'After making the deposit, email the proof of payment to support@cyanase.com with your reference: ${_generateReference()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _textField('Enter Amount'),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: (_isSubmitting || _bankAmountController.text.isEmpty || double.tryParse(_bankAmountController.text) == null || double.parse(_bankAmountController.text) <= 0)
                                ? null
                                : submitDepositor,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (_isSubmitting || _bankAmountController.text.isEmpty || double.tryParse(_bankAmountController.text) == null || double.parse(_bankAmountController.text) <= 0)
                                  ? Colors.grey
                                  : primaryTwo,
                              foregroundColor: primaryLight,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(height: 20, width: 20, child: Loader())
                                : const Text('Submit'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBankDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: primaryTwo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField(String label) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      child: TextFormField(
        controller:
            _selectedMethod == 'Bank Transfer' ? _bankAmountController : null,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        onChanged: (value) {
          if (_selectedMethod == 'Mobile Money') {
            setState(() {
              depositAmount =
                  value.isNotEmpty ? double.tryParse(value) ?? 0.0 : null;
            });
          }
        },
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primaryTwo),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTwo,
              foregroundColor: primaryLight,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }
}
