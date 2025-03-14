import 'package:flutter/material.dart';
import '../../theme/theme.dart'; // Import your theme file
import 'login_with_phone.dart';
import 'signup.dart';
import '../home/home.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'package:cyanase/helpers/loader.dart';
import 'package:cyanase/helpers/api_helper.dart';

class NumericLoginScreen extends StatefulWidget {
  const NumericLoginScreen({Key? key}) : super(key: key);

  @override
  _NumericLoginScreenState createState() => _NumericLoginScreenState();
}

class _NumericLoginScreenState extends State<NumericLoginScreen> {
  final int _passcodeLength = 4;
  String _input = "";
  bool _passcode = false;
  void _onNumberPressed(String number) {
    if (_input.length < _passcodeLength) {
      setState(() {
        _input += number;
      });

      if (_input.length == _passcodeLength) {
        _verifyPasscode(_input);
      }
    }
  }

  void _onDeletePressed() {
    if (_input.isNotEmpty) {
      setState(() {
        _input = _input.substring(0, _input.length - 1);
      });
    }
  }

  Future<void> _verifyPasscode(String passcode) async {
    final dbHelper = DatabaseHelper(); // Get the DatabaseHelper instance

    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Loader(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    try {
      // Initialize the database
      final db = await dbHelper.database;

      // Retrieve the user's email from the profile table
      final userProfile = await db.query('profile', limit: 1);
      final email = userProfile.first['email'] as String;
      final name = userProfile.first['first_name'] as String;

      // Perform login API request using the retrieved email and passcode
      final loginResponse = await ApiService.passcodeLogin({
        'username': email,
        'password': passcode,
      });

      // Dismiss the loading indicator

      // Check if the response indicates failure
      if (loginResponse.containsKey('success') && !loginResponse['success']) {
        // Show a red SnackBar for errorsNavigato
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loginResponse['message'] ?? 'Login failed'),
            backgroundColor: Colors.red, // Red SnackBar for errors
          ),
        );
        return;
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
        final userCountry = profile['country'];
        final phoneNumber = profile['phoneno'];
        final isVerified = profile['is_verified'] ?? false;
        final mypasscode =
            profile['passcode'] as String?; // Cast to String? for safety

        setState(() {
          // Always set email
          _passcode = (mypasscode != null &&
              mypasscode.isNotEmpty); // True if not empty
        });
        if (isVerified) {
          // Store only the required profile details in the database
          final dbHelper = DatabaseHelper();
          final db = await dbHelper.database;

          // Check if the profile already exists
          final existingProfile = await db.query('profile');

          if (existingProfile.isNotEmpty) {
            // Update the existing profile
            await db.update(
              'profile',
              {
                'email': email,
                'country': userCountry,
                'phone_number': phoneNumber,
                'token': token,
                'name': userName,
                'created_at': DateTime.now().toIso8601String(),
              },
            );
          } else {
            // Insert a new profile
            await db.insert(
              'profile',
              {
                'id': userId,
                'email': email,
                'country': userCountry,
                'token': token,
                'phone_number': phoneNumber,
                'name': userName,
                'created_at': DateTime.now().toIso8601String(),
              },
            );
          }
          Navigator.pop(context);
          // Navigate to HomeScreen after successful login
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(passcode: _passcode, name: name),
            ),
          );
        } else {
          // Show bottom sheet to verify account
          // You can add your logic here for unverified accounts
        }
      } else {
        Navigator.pop(context); // Show a red SnackBar for invalid response
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid login response: Missing required fields'),
            backgroundColor: Colors.red, // Red SnackBar for errors
          ),
        );
      }
    } catch (e) {
      // Dismiss the loading indicator
      Navigator.pop(context);

      // Show a red SnackBar for errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Check internet connection and try again'),
          backgroundColor: Colors.red, // Red SnackBar for errors
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 100,
            width: 70,
          ),
          const SizedBox(height: 20),
          const Text(
            'Enter pass code to login',
            style: TextStyle(
              fontSize: 20,
              color: primaryTwo,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _passcodeLength,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                width: 16.0,
                height: 16.0,
                decoration: BoxDecoration(
                  color: index < _input.length ? primaryTwo : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Column(
            children: [
              for (var row in [
                ["1", "2", "3"],
                ["4", "5", "6"],
                ["7", "8", "9"],
                ["", "0", "\u232b"]
              ])
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: row.map((item) {
                    if (item == "") {
                      return SizedBox(
                        width: 60,
                        height: 60,
                        child: Container(), // Empty space placeholder
                      );
                    } else if (item == "\u232b") {
                      return GestureDetector(
                        onTap: _onDeletePressed,
                        child: Container(
                          width: 60,
                          height: 60,
                          alignment: Alignment.center,
                          child: const Icon(Icons.backspace, size: 28),
                        ),
                      );
                    } else {
                      return GestureDetector(
                        onTap: () => _onNumberPressed(item),
                        child: Container(
                          margin: const EdgeInsets.all(8.0),
                          width: 60,
                          height: 60,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(30.0),
                            border: Border.all(color: primaryTwo, width: 1),
                          ),
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 20,
                              color: primaryTwo,
                            ),
                          ),
                        ),
                      );
                    }
                  }).toList(),
                ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
            child: const Text(
              'Login using Phone number?',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
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
              'Don’t have an account? Sign up!',
              style: TextStyle(
                color: primaryTwo,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
