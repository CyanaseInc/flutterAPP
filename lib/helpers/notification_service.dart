import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

import 'package:cyanase/helpers/endpoints.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      'resource://drawable/notification_icon',
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic Notifications',
          channelDescription: 'Basic notification channel',
          defaultColor: Colors.blue,
          ledColor: Colors.blue,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          enableVibration: true,
          enableLights: true,
        ),
        NotificationChannel(
          channelKey: 'group_messages',
          channelName: 'Group Messages',
          channelDescription: 'Notifications for group messages',
          defaultColor: Colors.green,
          ledColor: Colors.green,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          enableVibration: true,
          enableLights: true,
        ),
        NotificationChannel(
          channelKey: 'goal_reminders',
          channelName: 'Goal Reminders',
          channelDescription: 'Notifications for goal reminders',
          defaultColor: Colors.orange,
          ledColor: Colors.orange,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          enableVibration: true,
          enableLights: true,
        ),
        NotificationChannel(
          channelKey: 'product_updates',
          channelName: 'Product Updates',
          channelDescription: 'Notifications for product updates',
          defaultColor: Colors.purple,
          ledColor: Colors.purple,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          enableVibration: true,
          enableLights: true,
        ),
      ],
    );

    // Request notification permissions
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
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
    // Determine notification layout based on message type
    NotificationLayout layout = NotificationLayout.Default;
    String? bigPicture;
    String? largeIcon;

    if (messageType == 'image' && messageImage != null) {
      layout = NotificationLayout.BigPicture;
      bigPicture = messageImage;
    }

    // Set group icon as large icon if available
    if (groupIcon != null) {
      largeIcon = groupIcon;
    } else if (profilePic != null) {
      largeIcon = profilePic;
    }

    // Ensure URLs are absolute
    if (largeIcon != null && !largeIcon.startsWith('http')) {
      largeIcon = '${ApiEndpoints.server}/$largeIcon';
    }
    if (bigPicture != null && !bigPicture.startsWith('http')) {
      bigPicture = '${ApiEndpoints.server}/$bigPicture';
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'group_messages',
        title: '$groupName - $senderName',
        body: message,
        notificationLayout: layout,
        category: NotificationCategory.Message,
        wakeUpScreen: true,
        fullScreenIntent: false,
        criticalAlert: false,
        bigPicture: bigPicture,
        largeIcon: largeIcon,
        payload: {
          'type': 'group_message',
          'group_id': groupId,
          'message_type': messageType,
        },
      ),
    );
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

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'goal_reminders',
        title: 'Goal Reminder: $goalName',
        body: reminderMessage,
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Reminder,
        wakeUpScreen: true,
        fullScreenIntent: false,
        criticalAlert: false,
        largeIcon: largeIcon,
        payload: {
          'type': 'goal_reminder',
          'goal_id': goalId,
        },
      ),
    );
  }

  Future<void> showProductUpdateNotification({
    required String title,
    required String message,
    String? updateId,
    String? updateImage,
  }) async {
    NotificationLayout layout = NotificationLayout.Default;
    String? bigPicture;

    if (updateImage != null) {
      layout = NotificationLayout.BigPicture;
      bigPicture = updateImage.startsWith('http')
          ? updateImage
          : '${ApiEndpoints.server}/$updateImage';
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'product_updates',
        title: title,
        body: message,
        notificationLayout: layout,
        category: NotificationCategory.Social,
        wakeUpScreen: true,
        fullScreenIntent: false,
        criticalAlert: false,
        bigPicture: bigPicture,
        payload: {
          'type': 'product_update',
          'update_id': updateId,
        },
      ),
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

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'basic_channel',
        title: title,
        body: message,
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Message,
        wakeUpScreen: true,
        fullScreenIntent: false,
        criticalAlert: false,
        largeIcon: largeIcon,
        payload: {
          'type': 'basic',
          'data': payload,
        },
      ),
    );
  }

  // Handle notification actions
  void setupNotificationActionHandlers(BuildContext context) {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: (ReceivedAction receivedAction) async {
        final payload = receivedAction.payload;
        if (payload == null) return;

        switch (payload['type']) {
          case 'group_message':
            // Handle group message notification tap
            final groupId = payload['group_id'];
            if (groupId != null) {
              // Navigate to the group chat
              // You'll need to implement this navigation logic
            }
            break;

          case 'goal_reminder':
            // Handle goal reminder notification tap
            final goalId = payload['goal_id'];
            if (goalId != null) {
              // Navigate to the goal details
              // You'll need to implement this navigation logic
            }
            break;

          case 'product_update':
            // Handle product update notification tap
            final updateId = payload['update_id'];
            if (updateId != null) {
              // Navigate to the update details
              // You'll need to implement this navigation logic
            }
            break;

          case 'basic':
            // Handle basic notification tap
            final data = payload['data'];
            if (data != null) {
              // Handle basic notification data
              // You'll need to implement this logic
            }
            break;
        }
      },
    );
  }
}
