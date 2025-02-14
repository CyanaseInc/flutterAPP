import 'package:cyanase/helpers/loader.dart';
import 'package:cyanase/screens/auth/set_three_code.dart';
import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import 'package:cyanase/helpers/api_helper.dart'; // Assuming you have an ApiService class

class VerificationScreen extends StatefulWidget {
  final String email; // User's email address

  const VerificationScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _emailControllers =
      List.generate(6, (index) => TextEditingController());

  bool _isLoading = false; // Track if the verification is in progress

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 100,
                  width: 70,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Verify Email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryTwo,
                ),
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Please enter the 6-digit code sent to ',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    TextSpan(
                      text: widget.email,
                      style: TextStyle(
                        fontSize: 16,
                        color: primaryColor, // Change the color of the email
                      ),
                    ),
                    TextSpan(
                      text: '.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 50,
                    height: 50,
                    child: TextField(
                      controller: _emailControllers[index],
                      maxLength: 1,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        counterText: "",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          FocusScope.of(context).nextFocus();
                        } else if (value.isEmpty && index > 0) {
                          FocusScope.of(context).previousFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyEmail,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: primaryTwo,
                ),
                child: _isLoading
                    ? const Loader()
                    : const Text(
                        'Verify',
                        style: TextStyle(
                          fontSize: 15,
                          color: white,
                        ),
                      ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _isLoading ? null : _resendEmailCode,
                child: const Text(
                  'Resend Email Code',
                  style: TextStyle(
                    fontSize: 16,
                    color: primaryTwo,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verifyEmail() async {
    setState(() {
      _isLoading = true;
    });

    // Combine the 6-digit code from the text fields
    String emailCode =
        _emailControllers.map((controller) => controller.text).join();

    try {
      // Prepare the data to send to the API
      Map<String, dynamic> userData = {
        'email': widget.email, // Pass the email
        'code': emailCode, // Pass the verification code
      };

      // Make the API call
      final response = await ApiService.VerificationEmail(userData);

      // Handle the response
      if (response['success'] == true) {
        // Check if the response indicates success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified successfully!')),
        );
        // Navigate to the next screen after successful verification
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => SetCodeScreen(email: widget.email)),
        );
      } else {
        // Show error message from the API response
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Verification failed')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Show a generic error message if something goes wrong
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check code and  try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resendEmailCode() {
    // Simulate resending email code
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email code resent!')),
    );
  }
}

class NextScreen extends StatelessWidget {
  const NextScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Welcome! Your email has been verified.'),
      ),
    );
  }
}
