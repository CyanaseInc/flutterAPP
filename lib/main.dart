import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cyanase/helpers/link_handler.dart';
import '/screens/splash.dart';
import 'screens/auth/login_with_passcode.dart';
import 'screens/auth/login_with_phone.dart';
import 'theme/theme.dart';
import 'package:cyanase/helpers/database_helper.dart';

class NotificationHandler {
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    debugPrint(
        'Notification action received in background: ${receivedAction.body}');
  }
}

void main() async {
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  late DeepLinkHandler _deepLinkHandler;

  @override
  void initState() {
    super.initState();
    debugPrint('Initializing MyApp, setting up DeepLinkHandler');
    _deepLinkHandler = DeepLinkHandler(navigatorKey: navigatorKey);
    _deepLinkHandler.initDeepLinks();
  }

  @override
  void dispose() {
    debugPrint('Disposing MyApp, cleaning up DeepLinkHandler');
    _deepLinkHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building MyApp with navigatorKey');
    return MaterialApp(
      title: 'Cyanase',
      theme: appTheme,
      navigatorKey: navigatorKey,
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
  @override
  void initState() {
    super.initState();
    debugPrint('SplashScreenWrapper initState, checking user profile');
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
        debugPrint('Profile check result: ${result.length} profiles found');
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
      debugPrint('Error checking user profile: $e');
      if (mounted) {
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
