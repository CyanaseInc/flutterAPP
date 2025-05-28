import 'dart:math';
import 'package:cyanase/helpers/loader.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/helpers/api_helper.dart';
import '../../theme/theme.dart';
import 'package:flutter_verification_code_field/flutter_verification_code_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _verificationCodeController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isEmailValid = false;
  bool _isLoading = false; // To show/hide the preloader
  bool _obscureNewPassword = true; // To toggle new password visibility
  bool _obscureConfirmPassword = true; // To toggle confirm password visibility
  String _verificationCode = ''; // Store the generated verification code

  // Generate a 6-digit verification code
  String _generateVerificationCode() {
    var rnd = Random();
    var code = rnd.nextInt(900000) + 100000; // Generates a 6-digit number
    return code.toString();
  }

  // Validate email and send verification code
  Future<void> _sendVerificationCode() async {
    final email = _emailController.text.trim();
    final isValid = RegExp(r"^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}")
        .hasMatch(email);

    setState(() {
      _isEmailValid = isValid;
    });

    if (isValid) {
      setState(() {
        _isLoading = true; // Show preloader
      });

      _verificationCode =
          _generateVerificationCode(); // Generate and store the code

      final userData = {
        'email': email,
        'code': _verificationCode, // Send the code to the backend
      };

      try {
        final response = await ApiService.CheckResetPassword(userData);
        print(response['success']);
        if (response['success'] == true) {
          // Code sent successfully, navigate to the next screen
          _nextPage();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to send verification code: ${response['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false; // Hide preloader
        });
      }
    }
  }

  // Navigate to the next page or validate the verification code
  void _nextPage() {
    if (_isCurrentSlideValid()) {
      if (_currentPage < 2) {
        if (_currentPage == 1) {
          // Check if the entered code matches the generated code
          if (_verificationCodeController.text.trim() == _verificationCode) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid verification code. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      } else {
        _resetPassword();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill out all required fields correctly.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Check if the current slide's input is valid
  bool _isCurrentSlideValid() {
    switch (_currentPage) {
      case 0:
        return _isEmailValid;
      case 1:
        return _verificationCodeController.text.trim().length == 6;
      case 2:
        return _newPasswordController.text.trim().isNotEmpty &&
            _newPasswordController.text == _confirmPasswordController.text;
      default:
        return false;
    }
  }

  // Reset password logic
  void _resetPassword() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final email = _emailController.text
        .trim()
        .split(' ')[0]; // Take only the email part before any space

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userData = {
      'email': email,
      'password': newPassword,
      'ref': 'reset_token',
    };

    try {
      final response = await ApiService.ResetPassword(userData);
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successful!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset password: ${response['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _verificationCodeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Forgot password',
          style: TextStyle(
            color: white,
          ),
        ),
        backgroundColor: primaryTwo,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    _buildEmailStep(),
                    _buildVerificationStep(),
                    _buildNewPasswordStep(),
                  ],
                ),
              ),
              _buildNavigationButtons(),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5), // Overlay
              child: const Center(
                child: Loader(), // Preloader
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmailStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter your email address',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: primaryTwo),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              onChanged: (_) {
                setState(() {
                  _isEmailValid =
                      RegExp(r"^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}")
                          .hasMatch(_emailController.text.trim());
                });
              },
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: const UnderlineInputBorder(),
                errorText: _isEmailValid ? null : 'Please enter a valid email',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter the verification code',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: primaryTwo),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Verification code was sent to your email address.',
              style: TextStyle(fontSize: 15, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            VerificationCodeField(
              length: 6,
              onFilled: (value) {
                if (value.length == 6) {
                  // Check if the code has been filled
                  setState(() {
                    // Trigger the state update here
                    _verificationCodeController.text = value;
                  });
                }
              },
              size: const Size(30, 60),
              spaceBetween: 16,
              matchingPattern: RegExp(r'^\d+$'),
            ),
            // TextField(
            //   controller: _verificationCodeController,
            //   onChanged: (_) {
            //     setState(
            //         () {}); // Trigger state update to enable/disable the Next button
            //   },
            //   keyboardType: TextInputType.number,
            //   maxLength: 6,
            //   decoration: const InputDecoration(
            //     labelText: 'Verification Code',
            //     border: UnderlineInputBorder(),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewPasswordStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Set your new password',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: primaryTwo),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              onChanged: (_) {
                setState(
                    () {}); // Trigger state update to enable/disable the Reset Password button
              },
              decoration: InputDecoration(
                labelText: 'New Password',
                border: const UnderlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: primaryTwo,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              onChanged: (_) {
                setState(
                    () {}); // Trigger state update to enable/disable the Reset Password button
              },
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: const UnderlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: primaryTwo,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            ElevatedButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTwo,
                foregroundColor: Colors.white,
              ),
              child: const Text('Back'),
            ),
          ElevatedButton(
            onPressed: _isCurrentSlideValid()
                ? () {
                    if (_currentPage == 0) {
                      _sendVerificationCode();
                    } else {
                      _nextPage();
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTwo,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey,
              disabledForegroundColor: Colors.white70,
            ),
            child: Text(
              _currentPage < 2 ? 'Next' : 'Reset Password',
            ),
          ),
        ],
      ),
    );
  }
}
