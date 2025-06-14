import 'dart:math';
import 'package:cyanase/helpers/loader.dart';
import 'package:flutter/material.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../theme/theme.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isEmailValid = false;
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String _verificationCode = '';

  String _generateVerificationCode() {
    var rnd = Random();
    var code = rnd.nextInt(900000) + 100000;
    return code.toString();
  }

  Future<void> _sendVerificationCode() async {
    final email = _emailController.text.trim();
    final isValid = RegExp(r"^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}")
        .hasMatch(email);

    setState(() {
      _isEmailValid = isValid;
    });

    if (isValid) {
      setState(() {
        _isLoading = true;
      });

      _verificationCode = _generateVerificationCode();

      final userData = {
        'email': email,
        'code': _verificationCode,
      };

      try {
        final response = await ApiService.CheckResetPassword(userData);
        if (response['success'] == true) {
          _nextPage();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send verification code: ${response['message']}'),
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
          _isLoading = false;
        });
      }
    }
  }

  void _nextPage() {
    if (_isCurrentSlideValid()) {
      if (_currentPage < 2) {
        if (_currentPage == 1) {
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

  void _resetPassword() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final email = _emailController.text.trim().split(' ')[0];

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
    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text(
            'Forgot password',
            style: TextStyle(color: white),
          ),
          backgroundColor: primaryTwo,
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.back, color: white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        child: Stack(
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
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Loader(),
                ),
              ),
          ],
        ),
      );
    } else {
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
            icon: const Icon(Icons.arrow_back_ios, color: white),
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
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Loader(),
              ),
            ),
        ],
      ),
    );
    }
  }

  Widget _buildEmailStep() {
    if (Platform.isIOS) {
    return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Reset Password',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryTwo,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Enter your email address to receive a verification code',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            CupertinoTextField(
              controller: _emailController,
              placeholder: 'Email Address',
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 40),
            CupertinoButton.filled(
              onPressed: _isLoading ? null : _sendVerificationCode,
              child: _isLoading
                  ? const Loader()
                  : const Text('Send Verification Code'),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Reset Password',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryTwo,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Enter your email address to receive a verification code',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendVerificationCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTwo,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const Loader()
                  : const Text('Send Verification Code'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildVerificationStep() {
    if (Platform.isIOS) {
    return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter Verification Code',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryTwo,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Please enter the verification code sent to your email',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            CupertinoTextField(
              controller: _verificationCodeController,
              placeholder: 'Verification Code',
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 40),
            CupertinoButton.filled(
              onPressed: _isLoading ? null : _sendVerificationCode,
              child: _isLoading ? const Loader() : const Text('Verify Code'),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter Verification Code',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryTwo,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Please enter the verification code sent to your email',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            TextField(
                controller: _verificationCodeController,
              decoration: const InputDecoration(
                labelText: 'Verification Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendVerificationCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTwo,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading ? const Loader() : const Text('Verify Code'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildNewPasswordStep() {
    if (Platform.isIOS) {
    return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Set New Password',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryTwo,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Please enter your new password',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            CupertinoTextField(
              controller: _newPasswordController,
              placeholder: 'New Password',
              obscureText: true,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 20),
            CupertinoTextField(
              controller: _confirmPasswordController,
              placeholder: 'Confirm Password',
              obscureText: true,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 40),
            CupertinoButton.filled(
              onPressed: _isLoading ? null : _resetPassword,
              child: _isLoading ? const Loader() : const Text('Reset Password'),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Set New Password',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryTwo,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Please enter your new password',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTwo,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading ? const Loader() : const Text('Reset Password'),
          ),
        ],
      ),
    );
    }
  }
}