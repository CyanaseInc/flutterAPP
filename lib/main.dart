import 'package:flutter/material.dart';
import 'package:cyanase/screens/settings/invite.dart'; 
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cyanase/helpers/link_handler.dart';
import '/screens/splash.dart';
import 'screens/auth/login_with_passcode.dart';
import 'screens/auth/login_with_phone.dart';
import 'theme/theme.dart';
import 'package:cyanase/helpers/database_helper.dart';
import 'screens/home/home.dart';
import 'package:cyanase/helpers/notification_service.dart';

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

  // Initialize notification service first
  await NotificationService().initialize();

  // Initialize AwesomeNotifications for scheduled notifications only
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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  late DeepLinkHandler _deepLinkHandler;

  @override
  void initState() {
    super.initState();
    
    _deepLinkHandler = DeepLinkHandler(navigatorKey: navigatorKey);
    _deepLinkHandler.initDeepLinks();

    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    
    _deepLinkHandler.dispose();

    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    
    if (state == AppLifecycleState.resumed) {
      // App is coming to the foreground, update badge count from database
      NotificationService().updateBadgeCountFromDatabase();
    }
  }

  @override
  Widget build(BuildContext context) {
  
    return MaterialApp(
      title: 'Cyanase',
      theme: appTheme,
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: const SplashScreenWrapper(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
      // Enable route caching
      onGenerateRoute: (settings) {
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) {
            return _buildPage(settings.name!, settings.arguments);
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        );
      },
    );
  }

Widget _buildPage(String name, Object? arguments) {
  switch (name) {
    case '/':
      return const SplashScreenWrapper();
    case '/login':
      return const LoginScreen();
    case '/numeric_login':
      return const NumericLoginScreen();
    case '/home':
      final args = arguments as Map<String, dynamic>?;
      return HomeScreen(
        passcode: args?['passcode'],
        email: args?['email'],
        name: args?['name'],
        picture: args?['picture'],
      );
    // ADD THIS CASE
    case '/referral':
      final args = arguments as Map<String, dynamic>?;
      return ReferralPage(
        inviteCode: args?['inviteCode'] ?? 'UNKNOWN',
        totalEarnings: args?['totalEarnings'] ?? 0.0,
      );
    default:
      return const SplashScreenWrapper();
  }
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
