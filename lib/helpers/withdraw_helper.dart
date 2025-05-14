import 'package:flutter/material.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:http/http.dart' as http; // Added for HTTP requests
import 'dart:convert'; // Added for JSON encoding

class WithdrawHelper extends StatefulWidget {
  final String withdrawType;
  final String withdrawId;
  final String phonenumber;
  final Function(String) onMethodSelected;

  const WithdrawHelper({
    required this.withdrawType,
    required this.withdrawId,
    required this.phonenumber,
    required this.onMethodSelected,
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
  int currentStep = 0;
  bool isLoading = false; // Added for loading state

  @override
  void initState() {
    super.initState();
    phoneNumber = widget.phonenumber;
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

  // New function to handle the POST request
  Future<void> submitWithdrawal() async {
    setState(() {
      isLoading = true; // Show loading indicator
    });

    try {
      final url = Uri.parse(
          'https://api.example.com/withdraw'); // Replace with your API endpoint
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          // Add any required auth headers, e.g., 'Authorization': 'Bearer <token>'
        },
        body: jsonEncode({
          'withdrawType': widget.withdrawType,
          'withdrawId': widget.withdrawId,
          'method': withdrawMethod,
          'phoneNumber': phoneNumber,
          'bankDetails': bankDetails,
          'amount': withdrawAmount,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success: Show a success message or navigate
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Withdrawal request submitted successfully!')),
        );
        // Optionally reset the form or navigate back
        setState(() {
          currentStep = 0;
          withdrawMethod = null;
          withdrawAmount = null;
          bankDetails = null;
        });
      } else {
        // Error: Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to submit withdrawal: ${response.statusCode}')),
        );
      }
    } catch (e) {
      // Handle network or other errors
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
    } finally {
      setState(() {
        isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                  onPressed:
                      isLoading ? null : previousStep, // Disable during loading
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
                  onPressed: isLoading
                      ? null
                      : () {
                          if (currentStep == 0 && withdrawMethod != null) {
                            widget.onMethodSelected(withdrawMethod!);
                            nextStep();
                          } else if (currentStep == 1 &&
                              withdrawAmount != null &&
                              withdrawAmount! > 0) {
                            nextStep();
                          }
                        }, // Disable during loading
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
                  onPressed:
                      isLoading ? null : submitWithdrawal, // Call POST request
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTwo,
                    foregroundColor: white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Confirm Withdraw',
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
        Text(
          'Withdraw from ${widget.withdrawType}: ${widget.withdrawId}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryTwo,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Choose Your Withdrawal Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: isLoading
                    ? null
                    : () {
                        setState(() {
                          withdrawMethod = 'mobile money';
                        });
                      },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: withdrawMethod == 'mobile money'
                        ? primaryTwo.withOpacity(0.1)
                        : primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: withdrawMethod == 'mobile money'
                          ? primaryTwo
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.phone_android,
                        size: 32,
                        color: withdrawMethod == 'mobile money'
                            ? primaryTwo
                            : Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mobile Money',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: withdrawMethod == 'mobile money'
                              ? primaryTwo
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: isLoading
                    ? null
                    : () {
                        setState(() {
                          withdrawMethod = 'bank';
                        });
                      },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: withdrawMethod == 'bank'
                        ? primaryTwo.withOpacity(0.1)
                        : primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: withdrawMethod == 'bank'
                          ? primaryTwo
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_balance,
                        size: 32,
                        color:
                            withdrawMethod == 'bank' ? primaryTwo : Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bank Transfer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: withdrawMethod == 'bank'
                              ? primaryTwo
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOption(String? method) {
    if (method == 'mobile money') {
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
        Text(
          'Withdraw from ${widget.withdrawType}: ${widget.withdrawId}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryTwo,
          ),
        ),
        const SizedBox(height: 24),
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
                    widget.phonenumber,
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
          keyboardType: TextInputType.number,
          onChanged: (value) {
            setState(() {
              withdrawAmount = double.tryParse(value);
            });
          },
          enabled: !isLoading, // Disable input during loading
        ),
      ],
    );
  }

  Widget buildBankDetailsStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Withdraw from ${widget.withdrawType}: ${widget.withdrawId}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryTwo,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Bank Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'Bank Details',
            filled: true,
            fillColor: primaryLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          keyboardType: TextInputType.text,
          onChanged: (value) {
            setState(() {
              bankDetails = value;
            });
          },
          enabled: !isLoading, // Disable input during loading
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
          keyboardType: TextInputType.number,
          onChanged: (value) {
            setState(() {
              withdrawAmount = double.tryParse(value);
            });
          },
          enabled: !isLoading, // Disable input during loading
        ),
      ],
    );
  }

  Widget buildConfirmStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm Withdrawal',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryTwo,
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
              Text(
                'From: ${widget.withdrawType} (${widget.withdrawId})',
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
                withdrawMethod == 'mobile money'
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
