import 'package:flutter/material.dart';
// Import the theme file

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Use the primary color from the theme
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Image
            Image.asset(
              'assets/logo.png', // Path to your logo image
              width: 80, // Adjust the width as needed
              height: 70, // Adjust the height as needed
            ),
            const SizedBox(height: 20),
            // App Name or Tagline
          ],
        ),
      ),
    );
  }
}
