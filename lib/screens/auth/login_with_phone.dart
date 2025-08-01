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
import 'package:flutter/cupertino.dart';
import 'package:cyanase/helpers/link_handler.dart';
import 'package:cyanase/screens/home/group/group_invite.dart';
import 'dart:io' show Platform;

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
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String username = '';
  String password = '';
  String countryCode = '+256'; // Default country code
  String phoneNumber = '';
  bool _passcode = false;
  String _email = '';
  String name = '';
  bool _showPasscodeOption = false;
  final TextEditingController _phoneController =
      TextEditingController(text: '+256');
  bool _obscurePassword = true; // Controls password visibility
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

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

    try {
      final loginResponse = await ApiService.login({
        'username': username,
        'password': password,
      });

      if (loginResponse.containsKey('success') && !loginResponse['success']) {
        String errorMessage = loginResponse['message'] ?? 'Login failed';
        // Convert technical messages to user-friendly ones
        if (errorMessage.contains('Invalid credentials')) {
          errorMessage = 'Incorrect phone number or password. Please try again.';
        } else if (errorMessage.contains('not found')) {
          errorMessage = 'No account found with this phone number. Please sign up first.';
        } else if (errorMessage.contains('network')) {
          errorMessage = 'Unable to connect to the internet. Please check your connection.';
        }
        throw Exception(errorMessage);
      }

      if (loginResponse.containsKey('token') &&
          loginResponse.containsKey('user_id') &&
          loginResponse.containsKey('user')) {
        final token = loginResponse['token'] as String;
        final userId = loginResponse['user_id'] as int;
        final user = loginResponse['user'] as Map<String, dynamic>;
        final email = user['email'] as String;

        final profile = user['profile'] as Map<String, dynamic>;
        final picture = profile['profile_picture'] as String;
        final firstName = user["first_name"] as String;
        final lastName = user['last_name'] as String;
        final userCountry = profile['country'] as String;
        final phoneNumber = profile['phoneno'] as String;
        final isVerified = profile['is_verified'] as bool? ?? false;
        final mypasscode = profile['passcode'] as String?;
        final userName = '$firstName $lastName'.trim();
        final autoSave = profile['auto_save'] as bool? ?? false;
        final goalAlert = profile['goals_alert'] as bool? ?? false;
        setState(() {
          _email = email;
          _passcode = (mypasscode != null &&
              mypasscode.isNotEmpty &&
              mypasscode.startsWith('pbkdf2_sha256'));
        });

        if (isVerified) {
          final dbHelper = DatabaseHelper();
          final db = await dbHelper.database;
          
          // Use a transaction for all database operations
          await db.transaction((txn) async {
            final readExistingProfile = await txn.query('profile');
            
            if (readExistingProfile.isNotEmpty) {
              await txn.update(
                'profile',
                {
                  'email': email,
                  'country': userCountry,
                  'phone_number': phoneNumber,
                  'token': token,
                  'name': userName,
                  'profile_pic': picture,
                  'created_at': DateTime.now().toIso8601String(),
                  'auto_save': autoSave,
                  'goals_alert': goalAlert,
                },
              );
            }

            //Check if profile exists
            final existingProfile = await txn.query(
              'profile',
              where: 'id = ?',
              whereArgs: [userId],
            );

            if (existingProfile.isNotEmpty) {
              // Update existing profile
              final int updatedRows = await txn.update(
                'profile',
                {
                  'email': email,
                  'country': userCountry,
                  'phone_number': phoneNumber,
                  'token': token,
                  'name': userName,
                  'profile_pic': picture,
                  'created_at': DateTime.now().toIso8601String(),
                  'auto_save': autoSave,
                  'goals_alert': goalAlert,
                },
                where: 'id = ?',
                whereArgs: [userId],
              );

              if (updatedRows == 0) {
                throw Exception('Failed to update profile in database');
              }
            } else {
              // Insert new profile
              final int insertedId = await txn.insert(
                'profile',
                {
                  'id': userId,
                  'email': email,
                  'country': userCountry,
                  'token': token,
                  'phone_number': phoneNumber,
                  'name': userName,
                  'profile_pic': picture,
                  'created_at': DateTime.now().toIso8601String(),
                  'auto_save': autoSave,
                  'goals_alert': goalAlert,
                },
              );

              if (insertedId == 0) {
                throw Exception('Failed to insert profile into database');
              }
            }
          });

          // Verify the operation was successful by querying the database
          final verifiedProfile = await db.query(
            'profile',
            where: 'id = ?',
            whereArgs: [userId],
          );

          if (verifiedProfile.isEmpty) {
            throw Exception(
                'Profile verification failed - no profile found after operation');
          }

          // Handle pending deep link after login
          if (PendingDeepLink.uri != null &&
              PendingDeepLink.uri!.scheme == 'cyanase' &&
              PendingDeepLink.uri!.host == 'join') {
            final groupId = PendingDeepLink.uri!.queryParameters['group_id'];
            if (groupId != null && groupId.isNotEmpty) {
              PendingDeepLink.uri = null;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupInviteScreen(
                    groupId: int.parse(groupId),
                  ),
                ),
              );
              return;
            }
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                passcode: _passcode,
                email: _email,
                name: userName,
                picture: picture,
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
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(10),
        ),
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
                    : const Text('Verify',
                        style: TextStyle(color: primaryColor)),
              ),
            ],
          ),
        );
      },
    );
  }

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
    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        backgroundColor: white,
        child: SafeArea(
          child: Padding(
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
                      obscureText: _obscurePassword,
                      onChanged: (value) {
                        setState(() {
                          password = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock, color: primaryColor),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: primaryColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: const UnderlineInputBorder(),
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
                              setState(() {
                                username = _phoneController.text;
                                if (!username.startsWith('+')) {
                                  username = '+$username';
                                }
                              });
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
                        const Text('Don\'t have an account? '),
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
        ),
      );
    } else {
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
                    obscureText: _obscurePassword,
                    onChanged: (value) {
                      setState(() {
                        password = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock, color: primaryColor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: primaryColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: const UnderlineInputBorder(),
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
                            setState(() {
                              username = _phoneController.text;
                              if (!username.startsWith('+')) {
                                username = '+$username';
                              }
                            });
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
                      const Text('Don\'t have an account? '),
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
