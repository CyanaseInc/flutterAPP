import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import '../../theme/theme.dart'; // Import your theme file
import 'login_sec.dart'; // Import the NumericLoginScreen
import 'signup.dart'; // Import the SignupScreen
import 'forgot.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Image.asset(
                  'assets/logo.png', // Your logo image here
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

                // Phone Number Field
                TextFormField(
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Only numbers
                    LengthLimitingTextInputFormatter(10), // Max 10 digits
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone, color: primaryColor),
                    border: UnderlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // Password Field
                TextFormField(
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock, color: primaryColor),
                    border: UnderlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 40),

                // Login Button
                ElevatedButton(
                  onPressed: () {
                    // Implement your login logic here
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
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

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
