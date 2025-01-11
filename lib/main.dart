import 'package:flutter/material.dart';
import '/screens/splash.dart';
import 'screens/auth/login_with_passcode.dart'; // Import your LoginScreen
import 'theme/theme.dart'; // Import the centralized theme

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cyanase',
      theme: appTheme, // Use the theme from theme.dart
      home: const SplashScreenWrapper(), // Start with the Splash Screen Wrapper
    );
  }
}

class SplashScreenWrapper extends StatefulWidget {
  const SplashScreenWrapper({super.key});

  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  void _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 3)); // Splash screen duration
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const NumericLoginScreen(), // Navigate to LoginScreen
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen(); // SplashScreen widget from screens/splash.dart
  }
}
