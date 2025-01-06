import 'package:flutter/material.dart';
import '../../theme/theme.dart'; // Your theme file

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

  void _nextPage() {
    if (_isCurrentSlideValid()) {
      if (_currentPage < 2) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _resetPassword();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill out all required fields correctly.'),
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

  void _validateEmail() {
    setState(() {
      _isEmailValid = RegExp(r"^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}")
          .hasMatch(_emailController.text.trim());
    });
  }

  void _resetPassword() {
    // Implement password reset logic here
    print("Password reset successful!");
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
        title: const Text('Forgot Password'),
      ),
      body: Column(
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
    );
  }

  Widget _buildEmailStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Enter your email address',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _emailController,
            onChanged: (_) => _validateEmail(),
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
              border: const UnderlineInputBorder(),
              errorText: _isEmailValid ? null : 'Please enter a valid email',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Enter the verification code sent to your email',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: primaryTwo),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _verificationCodeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Verification Code',
              border: UnderlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPasswordStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Set your new password',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: primaryTwo),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'New Password',
              border: UnderlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm Password',
              border: UnderlineInputBorder(),
            ),
          ),
        ],
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
              ),
              child: const Text(
                'Back',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ElevatedButton(
            onPressed: _isCurrentSlideValid() ? _nextPage : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isCurrentSlideValid() ? primaryTwo : Colors.grey,
            ),
            child: Text(
              _currentPage < 2 ? 'Next' : 'Reset Password',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
