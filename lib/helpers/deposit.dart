import 'package:cyanase/helpers/loader.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/get_currency.dart';
import 'package:cyanase/helpers/api_helper.dart';

class DepositScreen extends StatefulWidget {
  final String? selectedFundClass;
  final String? selectedOption;
  final String? depositCategory;
  final String? selectedFundManager;
  final int? selectedOptionId;
  DepositScreen(
      {this.selectedFundClass,
      this.selectedOption,
      this.selectedFundManager,
      this.selectedOptionId,
      required this.depositCategory});

  @override
  _DepositScreenState createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  String? _selectedMethod;
  String Phonenumber = '';
  bool _isSubmitting = false;
  double? depositAmount;
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
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String _generateReference() {
    return 'REF-${DateTime.now().millisecondsSinceEpoch}';
  }

// Helper method to generate a unique reference_id
  String _generateReferenceId() {
    return 'REF-ID-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _getNumber() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      final userPhone = userProfile.first['phone_number'] as String;
      setState(() {
        Phonenumber = userPhone;
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
        physics: BouncingScrollPhysics(), // Allows scrolling left & right
        onPageChanged: (index) {
          setState(() {
            _currentStep = index;
          });
        },
        children: [
          _buildChooseDepositMethod(),
          _buildEnterAmount(),
          _buildSuccessScreen(),
        ],
      ),
    );
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
          SizedBox(height: 10),
          const Text(
            'Let us know how you want to deposit',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          SizedBox(height: 10),
          _depositOption('Mobile Money', Icons.phone_android),
          SizedBox(height: 10),
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
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            child: Row(
              children: [
                Icon(icon, size: 30),
                SizedBox(width: 10),
                Text(
                  method,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void submitDepositor() async {
    if (depositAmount == null || depositAmount! <= 0 || Phonenumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid amount and phone number')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true; // Show full-screen preloader
    });

    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final userProfile = await db.query('profile', limit: 1);
      final token = userProfile.first['token'] as String;
      final userCountry = userProfile.first['country'] as String; // e.g., "UG"

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
        "phone_number": Phonenumber,
      };
      print('response $requestData');
      // Make API call
      final response = await ApiService.investDeposit(token, requestData);

      // If successful, navigate to the success screen
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      print('Error submitting deposit: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit deposit. Please try again.')),
      );
    } finally {
      setState(() {
        _isSubmitting = false; // Hide preloader
      });
    }
  }

  Widget _buildEnterAmount() {
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
                    const Text(
                      'Enter Details to continue',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryTwo),
                    ),
                    SizedBox(height: 10),
                    const Text(
                      'Enter how much you want to deposit',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: 320,
                      child: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: primaryColor, width: 1),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 15, horizontal: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.phone_android,
                                  size: 35, color: primaryTwo),
                              SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      Phonenumber,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 4),
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
                    SizedBox(height: 10),
                    _textField('Enter Amount'),

                    /// **Submit Button**
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : submitDepositor,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isSubmitting ? Colors.grey : primaryTwo,
                            foregroundColor: white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                          ),
                          child: _isSubmitting
                              ? SizedBox(height: 20, width: 20, child: Loader())
                              : Text('Submit'),
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

  Widget _textField(String label) {
    return TextField(
      keyboardType: TextInputType.number,
      onChanged: (value) {
        setState(() {
          depositAmount = value.isNotEmpty ? double.parse(value) : null;
        });
      },
      decoration: InputDecoration(
        labelText: label,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: primaryLight),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 100),
          SizedBox(height: 20),
          Text(
            'Deposit Successful!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Finish'),
          ),
        ],
      ),
    );
  }
}
