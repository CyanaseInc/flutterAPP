import 'package:intl/intl.dart';

class MessageUtils {
  // Sort messages by date (oldest to newest)
  static List<Map<String, dynamic>> sortMessagesByDate(
      List<Map<String, dynamic>> messages) {
    messages.sort((a, b) {
      final DateTime aDate = DateTime.parse(a["timestamp"]);
      final DateTime bDate = DateTime.parse(b["timestamp"]);
      return aDate.compareTo(bDate); // Sort in ascending order
    });
    return messages;
  }

  // Group messages by date (e.g., "Today", "Yesterday", etc.)
  static Map<String, List<Map<String, dynamic>>> groupMessagesByDate(
      List<Map<String, dynamic>> messages) {
    final Map<String, List<Map<String, dynamic>>> groupedMessages = {};

    for (final message in messages) {
      final DateTime? messageDate = message["timestamp"] != null
          ? DateTime.tryParse(message["timestamp"])
          : null;

      if (messageDate == null) {
        continue; // Skip messages with invalid or null timestamps
      }

      final String dateKey = _getDateKey(messageDate);

      if (!groupedMessages.containsKey(dateKey)) {
        groupedMessages[dateKey] = [];
      }
      groupedMessages[dateKey]!.add(message);
    }

    return groupedMessages;
  }

  // Helper function to get a readable date key (e.g., "Today", "Yesterday", or a formatted date)
  static String _getDateKey(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = DateTime(now.year, now.month, now.day - 1);

    if (date.isAfter(today)) {
      return "Today";
    } else if (date.isAfter(yesterday)) {
      return "Yesterday";
    } else {
      return DateFormat('MMMM d, y').format(date); // Format: "October 10, 2023"
    }
  }
}
