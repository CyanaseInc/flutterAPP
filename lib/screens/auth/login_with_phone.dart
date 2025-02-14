import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import '../../theme/theme.dart'; // Import your theme file
import 'login_with_passcode.dart'; // Import the NumericLoginScreen
import 'signup.dart'; // Import the SignupScreen
import 'forgot.dart';
import '../home/home.dart';
import 'package:cyanase/helpers/hash_numbers.dart';
import 'package:cyanase/theme/theme.dart';
import 'package:cyanase/helpers/database_helper.dart'; // Import the file containing fetchAndHashContacts and getRegisteredContacts
import 'package:cyanase/helpers/loader.dart';
import 'package:cyanase/helpers/api_helper.dart'; // Import the reusable function

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String username = '';
  String password = '';
  String countryCode = '256'; // Default country code
  String phoneNumber = ''; // Store phone number separately

  // State to track if login is in progress
  Future<void> _handleLogin(String username, String password) async {
    setState(() {
      _isLoading = true; // Show loader
    });

    // Validate that the username and password are not empty
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required')),
      );
      setState(() {
        _isLoading = false; // Hide loader
      });
      return; // Exit early if validation fails
    }

    try {
      // Perform login API request
      final loginResponse = await ApiService.login({
        'username': username,
        'password': password,
      });
      print('my username is $username and my password is $password');
      // Check if the response indicates failure
      if (loginResponse.containsKey('success') && !loginResponse['success']) {
        // Handle invalid credentials or other errors
        throw Exception(loginResponse['message'] ?? 'Login failed');
      }

      // Check if the response contains the expected fields for a successful login
      if (loginResponse.containsKey('token') &&
          loginResponse.containsKey('user_id') &&
          loginResponse.containsKey('user')) {
        final token = loginResponse['token'];
        final userId = loginResponse['user_id'];
        final user = loginResponse['user'];

        // Extract user details
        final email = user['email'];
        final userName = user['username'];

        // Extract profile details
        final profile = user['profile'];
        final phoneNumber = profile['phoneno'];
        final isVerified = profile['is_verified'] ?? false;

        if (isVerified) {
          // Store only the required profile details in the database
          final dbHelper = DatabaseHelper();
          final db = await dbHelper.database;
          await db.insert(
            'profile',
            {
              'id': userId,
              'email': email,
              'phone_number': phoneNumber,
              'name': userName,
              'created_at': DateTime.now().toIso8601String(),
            },
          );

          // Initialize the database
          await dbHelper.database;

          // Fetch and hash contacts (if needed)
          List<Map<String, String>> contacts = await fetchAndHashContacts();
          List<Map<String, dynamic>> registeredContacts =
              await getRegisteredContacts(contacts);

          // Navigate to HomeScreen after successful login
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(),
            ),
          );
        } else {
          // Show bottom sheet to verify account
          _showVerificationBottomSheet(phoneNumber);
        }
      } else {
        throw Exception('Invalid login response: Missing required fields');
      }
    } catch (e) {
      print('Error: $e');
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Invalid Login credentials. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loader
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
                        // Move to next field when a digit is entered
                        if (value.isNotEmpty && index < 5) {
                          FocusScope.of(context).nextFocus();
                        }

                        // Check if all fields are filled, and auto-submit OTP
                        if (_controllers.every(
                            (controller) => controller.text.isNotEmpty)) {
                          _submitOTP(
                              phoneNumber); // Trigger OTP submission when all fields are filled
                        }
                      },
                      controller:
                          _controllers[index], // Add controllers for each field
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () async {
                  try {
                    // Call the API to resend verification code
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
                    ? Loader() // Show loading spinner instead of "Verify" text
                    : const Text('Verify',
                        style: TextStyle(color: primaryColor)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTwo, // Set button background color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                  minimumSize: const Size(double.infinity, 60),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Assuming these controllers and isLoading variable are declared globally
  List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  // Method to handle OTP submission
  Future<void> _submitOTP(String phoneNumber) async {
    setState(() {
      _isLoading = true; // Show loader
    });

    try {
      // Join all OTP digits to form the complete OTP
      String otp = _controllers.map((controller) => controller.text).join('');

      // Call API to validate OTP
      final response = await ApiService.post('validate_otp', {
        'phone_number': phoneNumber,
        'otp': otp,
      });

      if (response['status'] == 'success') {
        // Close bottom sheet if successful
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification successful!'),
          ),
        );
      } else {
        // Show error if verification failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid code. Please try again.'),
          ),
        );
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to verify OTP. Please try again.'),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loader after the request
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
                // App Logo
                Image.asset(
                  'assets/images/logo.png', // Your logo image here
                  height: 100,
                  width: 70,
                ),
                const SizedBox(height: 20),

                // Welcome Note
                const Text(
                  'Welcome to Cyanase!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryTwo, // Use primaryColor color from theme
                  ),
                ),
                const SizedBox(height: 40),

                // Phone Number Field with Editable Country Code
                Row(
                  children: [
                    // Country Code Field
                    SizedBox(
                      width: 80, // Fixed width for the country code field
                      child: TextFormField(
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter
                              .digitsOnly, // Only numbers
                          LengthLimitingTextInputFormatter(
                              3), // Max 3 digits for country code
                        ],
                        decoration: const InputDecoration(
                          prefixText: '+', // Add '+' prefix
                          prefixStyle: TextStyle(color: Colors.black),
                          labelText: 'Code',
                          border: UnderlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            countryCode = value; // Update country code
                          });
                        },
                        initialValue: '256', // Default country code
                      ),
                    ),
                    const SizedBox(width: 10), // Spacing between fields
                    // Phone Number Field
                    Expanded(
                      child: TextFormField(
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter
                              .digitsOnly, // Only numbers
                          LengthLimitingTextInputFormatter(10), // Max 10 digits
                        ],
                        onChanged: (value) {
                          setState(() {
                            phoneNumber = value; // Update phone number
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Password Field
                TextFormField(
                  obscureText: true,
                  onChanged: (value) {
                    password = value; // Update password
                  },
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock, color: primaryColor),
                    border: UnderlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 40),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          // Combine country code and phone number to form the username
                          if (countryCode.isEmpty || phoneNumber.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please fill in all fields')),
                            );
                            return;
                          }
                          username =
                              '+$countryCode$phoneNumber'; // Combine into one value
                          _handleLogin(
                              username, password); // Call login function
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTwo, // Use primaryColor from theme
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 15, // Same vertical padding as the input fields
                    ),
                    minimumSize: const Size(double.infinity, 60),
                  ),
                  child: _isLoading
                      ? Loader() // Show loader when loading
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

                // Forgot Password Text
                GestureDetector(
                  onTap: () {
                    // Navigate to Forgot Password screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: primaryColor, // Use primaryColor from theme
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Passcode Login Text
                GestureDetector(
                  onTap: () {
                    // Navigate to the Passcode Login screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NumericLoginScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Login using Passcode?',
                    style: TextStyle(
                      color: primaryColor, // Use primaryColor from theme
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Don't have an account? Register text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Don’t have an account? '),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignupScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: primaryColor, // Use primaryColor from theme
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
