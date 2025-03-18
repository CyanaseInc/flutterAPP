import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:smile_id/smile_id.dart';
import '/screens/splash.dart'; // Splash screen widget
import 'screens/auth/login_with_passcode.dart'; // Login screen
import 'screens/auth/login_with_phone.dart'; // Your phone login screen (if needed)
import 'theme/theme.dart'; // Centralized theme
import 'package:cyanase/helpers/database_helper.dart'; // Database helper

// Class to handle background notification actions
class NotificationHandler {
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    print('Notification action received in background: ${receivedAction.body}');
    // Handle background actions here
  }
}

void main() async {
  // initialise smile id auth
  // SmileID.initialize(useSandbox: true);
  WidgetsFlutterBinding.ensureInitialized();

  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'scheduled_notifications',
        channelName: 'Scheduled Notifications',
        channelDescription: 'Notifications for saving goal reminders',
        defaultColor: const Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
      ),
    ],
    debug: true,
  );

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
      theme: appTheme,
      home: const SplashScreenWrapper(),
    );
  }
}

class SplashScreenWrapper extends StatefulWidget {
  const SplashScreenWrapper({super.key});

  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  // Changed to nullable bool to match LoginScreen

  @override
  void initState() {
    super.initState();
    _checkUserProfile();
  }

  Future<void> _checkUserProfile() async {
    await Future.delayed(const Duration(seconds: 3));

    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      List<Map> result = await db.query(
        'profile',
        where: 'email IS NOT NULL AND phone_number IS NOT NULL',
      );

      if (mounted) {
        // Check if widget is still mounted
        if (result.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const NumericLoginScreen(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
          );
        }
      }
    } catch (e) {
      print('Error checking user profile: $e');
      if (mounted) {
        // Check if widget is still mounted
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
