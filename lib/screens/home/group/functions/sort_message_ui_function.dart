// lib/utils/message_utils.dart
import 'package:intl/intl.dart';

class MessageSort {
  // Sort messages by date (newest to oldest)
  static List<Map<String, dynamic>> sortMessagesByDate(
      List<Map<String, dynamic>> messages) {
    messages.sort((a, b) {
      final DateTime aDate =
          DateTime.tryParse(a["timestamp"] ?? "") ?? DateTime.now();
      final DateTime bDate =
          DateTime.tryParse(b["timestamp"] ?? "") ?? DateTime.now();
      return bDate.compareTo(aDate); // Newest first
    });
    return messages;
  }

  // Group messages by date with WhatsApp-like date key
  static Map<String, List<Map<String, dynamic>>> groupMessagesByDate(
      List<Map<String, dynamic>> messages) {
    final Map<String, List<Map<String, dynamic>>> groupedMessages = {};

    for (final message in messages) {
      final DateTime? messageDate = message["timestamp"] != null
          ? DateTime.tryParse(message["timestamp"])
          : null;

      if (messageDate == null) {
        print('Skipping message with invalid timestamp: $message');
        continue;
      }

      final String dateKey = _getDateKey(messageDate.toLocal());

      if (!groupedMessages.containsKey(dateKey)) {
        groupedMessages[dateKey] = [];
      }
      groupedMessages[dateKey]!.add(message);
    }

    // Sort messages within each group (oldest to newest for chat screen display)
    groupedMessages.forEach((key, messages) {
      messages.sort((a, b) {
        final DateTime aDate = DateTime.parse(a["timestamp"]);
        final DateTime bDate = DateTime.parse(b["timestamp"]);
        return aDate.compareTo(bDate); // Oldest first within group
      });
    });

    return groupedMessages;
  }

  // Get a WhatsApp-like date key
  static String _getDateKey(DateTime date) {
    final DateTime now = DateTime.now().toLocal();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = DateTime(now.year, now.month, now.day - 1);
    final DateTime messageDay = DateTime(date.year, date.month, date.day);
    final Duration difference = today.difference(messageDay);

    if (messageDay.isAtSameMomentAs(today)) {
      return "Today";
    } else if (messageDay.isAtSameMomentAs(yesterday)) {
      return "Yesterday";
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(date); // e.g., "Tuesday"
    } else {
      return DateFormat('d MMM yyyy').format(date); // e.g., "2 Feb 2025"
    }
  }
}
