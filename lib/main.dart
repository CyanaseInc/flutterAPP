import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart'; // Add this import
import '/screens/splash.dart'; // Splash screen widget
import 'screens/auth/login_with_passcode.dart'; // Login screen
import 'screens/auth/login_with_phone.dart'; // Your phone login screen (if needed)
import 'theme/theme.dart'; // Centralized theme
import 'package:cyanase/helpers/database_helper.dart'; // Database helper

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
    _checkUserProfile(); // Initiating user profile check
  }

  Future<void> _checkUserProfile() async {
    await Future.delayed(
        const Duration(seconds: 3)); // Simulate splash screen duration

    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      // Query to check if the user profile exists
      List<Map> result = await db.query(
        'profile', // Assuming 'profile' is your table name
        where: 'email IS NOT NULL AND phone_number IS NOT NULL',
      );

      // Navigate based on the result of the profile check
      if (result.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const NumericLoginScreen(), // Navigate to NumericLoginScreen
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const LoginScreen(), // Navigate to LoginScreen
          ),
        );
      }
    } catch (e) {
      // Handle errors (e.g., database not initialized, missing table, etc.)
      print('Error checking user profile: $e');

      // Fallback: Navigate to LoginScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen(); // The splash screen widget
  }
}
