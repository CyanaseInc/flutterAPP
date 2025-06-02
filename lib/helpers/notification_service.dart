import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cyanase/helpers/endpoints.dart';
import 'package:cyanase/helpers/database_helper.dart';


// This needs to be a top-level function for background notifications
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Handle background notification tap
  debugPrint('🔵 [NotificationService] Background notification tapped: ${notificationResponse.payload}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  Function(NotificationResponse)? _notificationTapHandler;
  int _badgeCount = 0;

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('🔵 [NotificationService] Already initialized');
      return;
    }

    debugPrint('🔵 [NotificationService] Initializing notification service');

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );
      debugPrint('🔵 [NotificationService] Basic initialization complete');

      // Request notification permissions for Android 13 and above
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        debugPrint('🔵 [NotificationService] Android notification permission granted: $granted');
        
        // Set up notification channels for Android
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'chat_messages',
            'Chat Messages',
            description: 'Notifications for new chat messages',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        );
        
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'group_messages',
            'Group Messages',
            description: 'Notifications for group messages',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        );
      }

      // Request notification permissions for iOS
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: true,
        );
        debugPrint('🔵 [NotificationService] iOS notification permission granted: $granted');
      }

      _isInitialized = true;
      debugPrint('🔵 [NotificationService] Initialization complete');

      // Update badge count from database on initialization
      await updateBadgeCountFromDatabase();

    } catch (e, stackTrace) {
      debugPrint('🔴 [NotificationService] Error initializing: $e');
      debugPrint('🔴 [NotificationService] Stack trace: $stackTrace');
    }
  }

  void setNotificationTapHandler(Function(NotificationResponse) handler) {
    debugPrint('🔵 [NotificationService] Setting notification tap handler');
    _notificationTapHandler = handler;
  }

  void _handleNotificationTap(NotificationResponse response) {
    debugPrint('🔵 [NotificationService] Notification tapped');
    debugPrint('🔵 [NotificationService] Payload: ${response.payload}');
    _notificationTapHandler?.call(response);
    _decrementBadgeCount();
  }

  Future<void> updateBadgeCountFromDatabase() async {
    debugPrint('🔵 [NotificationService] Updating badge count from database');
    try {
      final dbHelper = DatabaseHelper(); // Assuming DatabaseHelper is accessible or passed
      final unreadCount = await dbHelper.getTotalUnreadMessageCount(); // Assuming this method exists
      _badgeCount = unreadCount;
      await _updateBadgeCount(); // Update platform badge
      debugPrint('🔵 [NotificationService] Badge count updated to: $_badgeCount');
    } catch (e) {
      debugPrint('🔴 [NotificationService] Error updating badge count from database: $e');
    }
  }

  Future<void> _incrementBadgeCount() async {
    _badgeCount++;
    await _updateBadgeCount();
  }

  Future<void> _decrementBadgeCount() async {
    if (_badgeCount > 0) {
      _badgeCount--;
      await _updateBadgeCount();
    }
  }

  Future<void> _updateBadgeCount() async {
    try {
      // For Android, we'll use the notification channel's badge count
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          AndroidNotificationChannel(
            'chat_messages',
            'Chat Messages',
            description: 'Notifications for new chat messages',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        );
      }

      // For iOS, we'll use the notification details
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: true,
        );
      }
    } catch (e) {
      debugPrint('🔴 [NotificationService] Error updating badge count: $e');
    }
  }

  Future<void> showMessageNotification({
    required String title,
    required String body,
    required String groupId,
    String? payload,
  }) async {
 

    if (!_isInitialized) {
      debugPrint('🔵 [NotificationService] Not initialized, initializing now');
      await initialize();
    }

    try {
      await _incrementBadgeCount();

      final androidDetails = AndroidNotificationDetails(
        'chat_messages',
        'Chat Messages',
        channelDescription: 'Notifications for new chat messages',
        importance: Importance.max,
        priority: Priority.high,
        groupKey: 'chat_messages',
        showWhen: true,
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(''),
        fullScreenIntent: true,
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
        color: Color(0xFF2196F3),
        icon: '@mipmap/ic_launcher_foreground',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher_foreground'),
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
        threadIdentifier: 'chat_messages',
        badgeNumber: _badgeCount,
        sound: 'default',
        attachments: null,
        subtitle: 'New Message',
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
     

      await _notifications.show(
        id,
        title,
        body,
        details,
        payload: payload ?? groupId,
      );
      
    } catch (e, stackTrace) {
      debugPrint('🔴 [NotificationService] Error showing message notification: $e');
      debugPrint('🔴 [NotificationService] Stack trace: $stackTrace');
    }
  }

  Future<void> showGroupMessageNotification({
    required String groupName,
    required String senderName,
    required String message,
    required String groupId,
    String? profilePic,
    String? groupIcon,
    String? messageImage,
    String? messageType,
  }) async {
    if (!_isInitialized) {
      debugPrint('🔵 [NotificationService] Not initialized, initializing now');
      await initialize();
    }

    try {
      await _incrementBadgeCount();

      String? largeIcon;
      String? bigPicture;

      // Set group icon as large icon if available
      if (groupIcon != null) {
        largeIcon = groupIcon;
        debugPrint('🔵 [NotificationService] Using group icon: $groupIcon');
      } else if (profilePic != null) {
        largeIcon = profilePic;
        debugPrint('🔵 [NotificationService] Using profile pic: $profilePic');
      }

      // Ensure URLs are absolute
      if (largeIcon != null && !largeIcon.startsWith('http')) {
        largeIcon = '${ApiEndpoints.server}/$largeIcon';
       
      }
      if (messageImage != null && !messageImage.startsWith('http')) {
        bigPicture = '${ApiEndpoints.server}/$messageImage';
        debugPrint('🔵 [NotificationService] Converted to absolute URL: $bigPicture');
      }

      final androidDetails = AndroidNotificationDetails(
        'group_messages',
        'Group Messages',
        channelDescription: 'Notifications for group messages',
        importance: Importance.max,
        priority: Priority.high,
        groupKey: 'group_messages',
        showWhen: true,
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(''),
        largeIcon: (largeIcon != null && !largeIcon.startsWith('http'))
            ? ByteArrayAndroidBitmap.fromBase64String(largeIcon)
            : DrawableResourceAndroidBitmap('@mipmap/ic_launcher_foreground'),
        fullScreenIntent: true,
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
        color: Color(0xFF2196F3),
        icon: '@mipmap/ic_launcher_foreground',
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
        threadIdentifier: 'group_messages',
        badgeNumber: _badgeCount,
        sound: 'default',
        attachments: null,
        subtitle: 'New Group Message',
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      debugPrint('🔵 [NotificationService] Showing notification with ID: $id');

      await _notifications.show(
        id,
        '$groupName - $senderName',
        message,
        details,
        payload: jsonEncode({
          'type': 'group_message',
          'group_id': groupId,
          'message_type': messageType,
        }),
      );
      debugPrint('🔵 [NotificationService] Group message notification shown successfully');
    } catch (e, stackTrace) {
      debugPrint('🔴 [NotificationService] Error showing group message notification: $e');
      debugPrint('🔴 [NotificationService] Stack trace: $stackTrace');
    }
  }

  Future<void> showGoalReminderNotification({
    required String goalName,
    required String reminderMessage,
    required String goalId,
    String? goalIcon,
  }) async {
    String? largeIcon;
    if (goalIcon != null && !goalIcon.startsWith('http')) {
      largeIcon = '${ApiEndpoints.server}/$goalIcon';
    }

    const androidDetails = AndroidNotificationDetails(
      'goal_reminders',
      'Goal Reminders',
      channelDescription: 'Notifications for goal reminders',
      importance: Importance.high,
      priority: Priority.high,
      groupKey: 'goal_reminders',
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Goal Reminder: $goalName',
      reminderMessage,
      details,
      payload: jsonEncode({
        'type': 'goal_reminder',
        'goal_id': goalId,
      }),
    );
  }

  Future<void> showProductUpdateNotification({
    required String title,
    required String message,
    String? updateId,
    String? updateImage,
  }) async {
    String? bigPicture;
    if (updateImage != null) {
      bigPicture = updateImage.startsWith('http')
          ? updateImage
          : '${ApiEndpoints.server}/$updateImage';
    }

    const androidDetails = AndroidNotificationDetails(
      'product_updates',
      'Product Updates',
      channelDescription: 'Notifications for product updates',
      importance: Importance.high,
      priority: Priority.high,
      groupKey: 'product_updates',
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      message,
      details,
      payload: jsonEncode({
        'type': 'product_update',
        'update_id': updateId,
      }),
    );
  }

  Future<void> showBasicNotification({
    required String title,
    required String message,
    String? payload,
    String? icon,
  }) async {
    String? largeIcon;
    if (icon != null && !icon.startsWith('http')) {
      largeIcon = '${ApiEndpoints.server}/$icon';
    }

    const androidDetails = AndroidNotificationDetails(
      'basic_channel',
      'Basic Notifications',
      channelDescription: 'Basic notifications',
      importance: Importance.high,
      priority: Priority.high,
      groupKey: 'basic_channel',
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      message,
      details,
      payload: jsonEncode({
        'type': 'basic',
        'data': payload,
      }),
    );
  }

  Future<void> clearBadgeCount() async {
    _badgeCount = 0;
    await _updateBadgeCount();
  }
}
