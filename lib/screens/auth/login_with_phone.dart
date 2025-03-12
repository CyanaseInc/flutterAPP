import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import '../../theme/theme.dart'; // Import your theme file
import 'login_with_passcode.dart'; // Import the NumericLoginScreen
import 'signup.dart'; // Import the SignupScreen
import 'forgot.dart';
import '../home/home.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/loader.dart';
import 'package:cyanase/helpers/api_helper.dart';
import 'package:cyanase/helpers/web_db.dart';

// Custom formatter to enforce '+' at the beginning
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text;

    // Ensure '+' is always at the beginning
    if (!text.startsWith('+')) {
      text = '+$text';
    }

    // Remove any extra '+' signs after the first one
    text = '+' + text.replaceAll('+', '');

    if (text.length > 13) {
      // Limit to +256XXXXXXXXXX (13 characters)
      return oldValue;
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final bool? isEmailStored;

  const LoginScreen({
    super.key,
    this.isEmailStored,
  });

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String username = '';
  String password = '';
  String countryCode = '+256'; // Default country code
  String phoneNumber = '';
  bool _passcode = false;
  String _email = '';
  bool _showPasscodeOption = false;
  final TextEditingController _phoneController =
      TextEditingController(text: '+256');

  @override
  void initState() {
    super.initState();
    _checkEmailInDatabase();
  }

  Future<void> _checkEmailInDatabase() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final profiles = await db.query('profile');

      setState(() {
        _showPasscodeOption = profiles.isNotEmpty;
      });
    } catch (e) {
      print('Error checking database: $e');
      setState(() {
        _showPasscodeOption = false;
      });
    }
  }

  Future<void> _handleLogin(String username, String password) async {
    setState(() {
      _isLoading = true;
    });

    // Ensure username starts with '+'
    if (!username.startsWith('+')) {
      username = '+$username';
    }

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }
    print('username $username password: $password');
    try {
      final loginResponse = await ApiService.login({
        'username': username,
        'password': password,
      });

      if (loginResponse.containsKey('success') && !loginResponse['success']) {
        print('LOGIN $loginResponse');
        throw Exception(loginResponse['message'] ?? 'Login failed');
      }

      if (loginResponse.containsKey('token') &&
          loginResponse.containsKey('user_id') &&
          loginResponse.containsKey('user')) {
        final token = loginResponse['token'];
        final userId = loginResponse['user_id'];
        final user = loginResponse['user'];
        final email = user['email'];
        final userName = user['username'];
        final profile = user['profile'];
        final userCountry = profile['country'];
        final phoneNumber = profile['phoneno'];
        final isVerified = profile['is_verified'] ?? false;
        final mypasscode = profile['passcode'] as String?;

        setState(() {
          _email = email;
          _passcode = (mypasscode != null && mypasscode.isNotEmpty);
        });

        if (isVerified) {
          // final dbHelper = DatabaseHelper();
          // final db = await dbHelper.database;
          // final existingProfile = await db.query('profile');

          // initialise shared storage
          await WebSharedStorage.init();
          var existingProfile = WebSharedStorage();
          final readExistingProfile =
              existingProfile.getCommon(userId.toString());
          if (readExistingProfile == null) {
            // we have some id already reated to this login user
            //lets set some items to localstorage
            existingProfile.setCommon('token', token);
            existingProfile.setCommon('username', userName);
            existingProfile.setCommon('country', userCountry);

            // await db.update(
            //   'profile',
            //   {
            //     'email': email,
            //     'country': userCountry,
            //     'phone_number': phoneNumber,
            //     'token': token,
            //     'name': userName,
            //     'created_at': DateTime.now().toIso8601String(),
            //   },
            // );
          }
          // will work for mobile device
          // else {
          //   await db.insert(
          //     'profile',
          //     {
          //       'id': userId,
          //       'email': email,
          //       'country': userCountry,
          //       'token': token,
          //       'phone_number': phoneNumber,
          //       'name': userName,
          //       'created_at': DateTime.now().toIso8601String(),
          //     },
          //   );
          // }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                passcode: _passcode,
                email: _email,
              ),
            ),
          );
        } else {
          _showVerificationBottomSheet(phoneNumber);
        }
      } else {
        throw Exception('Invalid login response: Missing required fields');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showVerificationBottomSheet(String phoneNumber) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 30),
              const Text(
                'Verify Your Account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryTwo,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 40,
                    child: TextField(
                      maxLength: 1,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          FocusScope.of(context).nextFocus();
                        }
                        if (_controllers.every(
                            (controller) => controller.text.isNotEmpty)) {
                          _submitOTP(phoneNumber);
                        }
                      },
                      controller: _controllers[index],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () async {
                  try {
                    await ApiService.post('resend_verification_code', {
                      'phone_number': phoneNumber,
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Verification code resent.'),
                      ),
                    );
                  } catch (e) {
                    print('Error resending code: $e');
                  }
                },
                child: const Text(
                  'Resend Verification Code',
                  style: TextStyle(
                    color: primaryTwo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _submitOTP(phoneNumber),
                child: _isLoading
                    ? Loader()
                    : const Text('Verify',
                        style: TextStyle(color: primaryColor)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTwo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  minimumSize: const Size(double.infinity, 60),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  Future<void> _submitOTP(String phoneNumber) async {
    setState(() {
      _isLoading = true;
    });

    try {
      String otp = _controllers.map((controller) => controller.text).join('');
      Map<String, dynamic> userData = {
        'username': phoneNumber,
        'code': otp,
      };
      final response = await ApiService.VerificationEmail(userData);

      if (response['success'] == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification successful!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid code. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to verify OTP. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 100,
                  width: 70,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome to Cyanase!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryTwo,
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    PhoneNumberFormatter(),
                    LengthLimitingTextInputFormatter(13), // +256XXXXXXXXXX
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone, color: primaryColor),
                    border: UnderlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      if (value.startsWith('+')) {
                        String stripped = value.substring(1);
                        if (stripped.length >= 3) {
                          countryCode = '+${stripped.substring(0, 3)}';
                          phoneNumber = stripped.substring(3);
                        } else {
                          countryCode = value;
                          phoneNumber = '';
                        }
                      }
                    });
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  obscureText: true,
                  onChanged: (value) {
                    password = value;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock, color: primaryColor),
                    border: UnderlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_phoneController.text.length < 4) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please enter a valid phone number')),
                            );
                            return;
                          }
                          username = _phoneController.text;
                          if (!username.startsWith('+')) {
                            username = '+$username';
                          }
                          _handleLogin(username, password);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTwo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    minimumSize: const Size(double.infinity, 60),
                  ),
                  child: _isLoading
                      ? const Loader()
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: white,
                          ),
                        ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ForgotPasswordScreen()),
                    );
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_showPasscodeOption)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NumericLoginScreen()),
                      );
                    },
                    child: const Text(
                      'Login using Passcode?',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Don’t have an account? '),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SignupScreen()),
                        );
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
