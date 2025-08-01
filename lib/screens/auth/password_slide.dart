import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../../theme/theme.dart';

class PasswordSlide extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const PasswordSlide({
    Key? key,
    required this.passwordController,
    required this.confirmPasswordController,
  }) : super(key: key);

  @override
  _PasswordSlideState createState() => _PasswordSlideState();
}

class _PasswordSlideState extends State<PasswordSlide> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;
  String? _errorText;
  bool _showRequirements = false;

  // Password requirements
  final _requirements = [
    'At least 6 characters',
    '1 uppercase letter',
    '1 lowercase letter',
    '1 number',
    '1 special character (!@#\$%^&*)',
  ];

  // Replace these with your actual URLs
  final String _termsOfServiceUrl = 'https://cyanase.com/terms-of-use';
  final String _privacyPolicyUrl = 'https://cyanase.com/privacy-policy';

  void _validatePasswords() {
    final password = widget.passwordController.text;
    final confirmPassword = widget.confirmPasswordController.text;
    
    setState(() {
      if (password.isEmpty || confirmPassword.isEmpty) {
        _errorText = null;
        return;
      }
      
      if (password != confirmPassword) {
        _errorText = "Passwords do not match";
      } else if (!_validatePasswordStrength(password)) {
        _errorText = "Password doesn't meet requirements";
      } else {
        _errorText = null;
      }
    });
  }

  bool _validatePasswordStrength(String password) {
    return password.length >= 6 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#\$%^&*]'));
  }

Future<void> _launchUrl(String url, BuildContext context) async {
  try {
    final uri = Uri.parse(url);
    debugPrint('Attempting to launch: $url');
    if (await canLaunchUrl(uri)) {
      debugPrint('Can launch URL: true');
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // Use external app (e.g., browser)
        webViewConfiguration: const WebViewConfiguration(enableJavaScript: true),
      );
    } else {
      debugPrint('Can launch URL: false');
      throw 'Could not launch $url';
    }
  } catch (e) {
    debugPrint('Error launching URL: $e');
    _showUrlLaunchErrorDialog(context, url);
  }
}

void _showUrlLaunchErrorDialog(BuildContext context, String url) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Error'),
      content: Text('Could not open $url. Would you like to copy it?'),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: url));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('URL copied to clipboard')),
            );
            Navigator.pop(context);
          },
          child: const Text('Copy URL'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 100,
                  width: 70,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Secure your account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryTwo,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Create a strong password to protect your account",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),

              // Password field with requirements toggle
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: Column(
                  children: [
                    TextField(
                      controller: widget.passwordController,
                      obscureText: _obscurePassword,
                      onChanged: (_) {
                        _validatePasswords();
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: primaryTwo),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                _obscurePassword 
                                  ? Icons.visibility_off 
                                  : Icons.visibility,
                                color: primaryTwo,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                _showRequirements
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                                color: primaryTwo,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showRequirements = !_showRequirements;
                                });
                              },
                            ),
                          ],
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: primaryTwo),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: primaryTwo),
                        ),
                      ),
                    ),
                    if (_showRequirements) ...[
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _requirements.map((req) {
                          final meetsRequirement = _checkRequirement(req, widget.passwordController.text);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Icon(
                                  meetsRequirement 
                                    ? Icons.check_circle 
                                    : Icons.circle_outlined,
                                  color: meetsRequirement ? Colors.green : Colors.grey,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  req,
                                  style: TextStyle(
                                    color: meetsRequirement ? Colors.green : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Confirm password field
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: TextField(
                  controller: widget.confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  onChanged: (_) => _validatePasswords(),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: TextStyle(color: primaryTwo),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                        color: primaryTwo,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryTwo),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryTwo),
                    ),
                    errorText: _errorText,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Terms and conditions checkbox
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Checkbox(
                      value: _termsAccepted,
                      onChanged: (value) {
                        setState(() {
                          _termsAccepted = value ?? false;
                        });
                      },
                      activeColor: primaryTwo,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // No action needed here since individual spans handle taps
                        },
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                  color: primaryTwo,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _launchUrl(_termsOfServiceUrl, context),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: primaryTwo,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _launchUrl(_privacyPolicyUrl, context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _checkRequirement(String requirement, String password) {
    switch (requirement) {
      case 'At least 6 characters':
        return password.length >= 6;
      case '1 uppercase letter':
        return password.contains(RegExp(r'[A-Z]'));
      case '1 lowercase letter':
        return password.contains(RegExp(r'[a-z]'));
      case '1 number':
        return password.contains(RegExp(r'[0-9]'));
      case '1 special character (!@#\$%^&*)':
        return password.contains(RegExp(r'[!@#\$%^&*]'));
      default:
        return false;
    }
  }
}