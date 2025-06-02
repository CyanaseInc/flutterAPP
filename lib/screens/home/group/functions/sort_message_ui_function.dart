// lib/utils/message_utils.dart
import 'package:intl/intl.dart';

class MessageSort {
  // Sort messages by date (newest to oldest)
  static List<Map<String, dynamic>> sortMessagesByDate(
      List<Map<String, dynamic>> messages) {
    return List<Map<String, dynamic>>.from(messages)
      ..sort((a, b) {
        final aTime = DateTime.parse(a['timestamp'] ?? '');
        final bTime = DateTime.parse(b['timestamp'] ?? '');
        return bTime.compareTo(aTime); // Sort in descending order (newest first)
      });
  }

  // Group messages by date with WhatsApp-like date key
  static Map<String, List<Map<String, dynamic>>> groupMessagesByDate(
      List<Map<String, dynamic>> messages) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    
    for (var message in messages) {
      final date = DateTime.parse(message['timestamp'] ?? '');
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(message);
    }

    // Sort messages within each group
    grouped.forEach((key, messages) {
      messages.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp'] ?? '');
        final bTime = DateTime.parse(b['timestamp'] ?? '');
        return bTime.compareTo(aTime); // Sort in descending order (newest first)
      });
    });

    return grouped;
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
