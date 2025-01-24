import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart'; // Add this import
import '/screens/splash.dart';
import 'screens/auth/login_with_passcode.dart'; // Import your LoginScreen
import 'theme/theme.dart'; // Import the centralized theme

// Class to handle background notification actions
class NotificationHandler {
  // Static method to handle background actions
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    print('Notification action received in background: ${receivedAction.body}');
    // Handle background actions here
  }
}

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure Flutter binding is initialized

  // Initialize AwesomeNotifications
  await AwesomeNotifications().initialize(
    null, // Use null for default app icon
    [
      NotificationChannel(
        channelKey: 'scheduled_notifications',
        channelName: 'Scheduled Notifications',
        channelDescription: 'Notifications for saving goal reminders',
        defaultColor: Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
      ),
    ],
    debug: true, // Enable debug logs
  );

  // Set the static method for background actions
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: NotificationHandler.onActionReceivedMethod,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cyanase',
      theme: appTheme, // Use the light theme from theme.dart
      //darkTheme: darkTheme, // Use the dark theme from theme.dart
      //  themeMode: ThemeMode.system, // Automatically adapt to system theme
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
