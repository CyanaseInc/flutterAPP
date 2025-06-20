import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Theme.of(context) to access the current theme colors
    final colorScheme = Theme.of(context).colorScheme;

    // Determine the logo based on the theme mode
    final isDarkMode = colorScheme.brightness == Brightness.dark;
    final logoAsset = isDarkMode
        ? 'assets/images/logo.png' // Dark mode logo
        : 'assets/images/logo.png'; // Light mode logo

    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        backgroundColor: colorScheme.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Image (changes based on theme)
              Image.asset(
                logoAsset, // Dynamic logo based on theme
                width: 80, // Adjust the width as needed
                height: 70, // Adjust the height as needed
              ),
              const SizedBox(height: 20),
              // App Name or Tagline
              Text(
                'Cyanase',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground, // Use text color from the theme
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Image (changes based on theme)
              Image.asset(
                logoAsset, // Dynamic logo based on theme
                width: 80, // Adjust the width as needed
                height: 70, // Adjust the height as needed
              ),
              const SizedBox(height: 20),
              // App Name or Tagline
              Text(
                'Cyanase',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground, // Use text color from the theme
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
