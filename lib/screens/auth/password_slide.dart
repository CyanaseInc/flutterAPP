import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class PasswordSlide extends StatelessWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const PasswordSlide({
    Key? key,
    required this.passwordController,
    required this.confirmPasswordController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        // Make the content scrollable
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment:
                CrossAxisAlignment.center, // Center all children horizontally
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
                'Secure your account!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryTwo,
                ),
                textAlign: TextAlign.center, // Center the text
              ),
              const SizedBox(height: 16),
              const Text(
                "Add your password to continue.",
                textAlign: TextAlign.center, // Center the text
              ),
              const SizedBox(height: 50),
              // Password field with bottom border only
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: primaryTwo),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryTwo),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryTwo),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Confirm password field with bottom border only
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: TextStyle(color: primaryTwo),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryTwo),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryTwo),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
