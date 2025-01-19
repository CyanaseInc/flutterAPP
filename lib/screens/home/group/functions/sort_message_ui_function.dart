import 'package:intl/intl.dart'; // For date formatting

/// Represents a group of messages for a specific date.
class MessageGroup {
  final String date; // e.g., "Today", "Yesterday", or "15 October 2023"
  final List<Map<String, dynamic>> messages; // List of messages for this date

  MessageGroup({required this.date, required this.messages});
}

/// Groups messages by date and sorts them by timestamp.
List<MessageGroup> groupMessagesByDate(List<Map<String, dynamic>> messages) {
  // Filter out messages with null timestamps
  messages = messages.where((message) => message["timestamp"] != null).toList();

  // Sort messages by timestamp (oldest to newest)
  messages.sort((a, b) =>
      DateTime.parse(a["timestamp"]).compareTo(DateTime.parse(b["timestamp"])));

  // Group messages by date
  Map<String, List<Map<String, dynamic>>> groupedMessages = {};

  for (var message in messages) {
    final timestamp = DateTime.parse(message["timestamp"]);
    final dateKey = getDateKey(timestamp);

    if (!groupedMessages.containsKey(dateKey)) {
      groupedMessages[dateKey] = [];
    }
    groupedMessages[dateKey]!.add(message);
  }

  // Convert the map into a list of MessageGroup objects
  return groupedMessages.entries.map((entry) {
    return MessageGroup(date: entry.key, messages: entry.value);
  }).toList();
}

/// Returns a formatted date key (e.g., "Today", "Yesterday", or "15 October 2023").
String getDateKey(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = DateTime(now.year, now.month, now.day - 1);

  if (date.isAfter(today)) {
    return "Today";
  } else if (date.isAfter(yesterday)) {
    return "Yesterday";
  } else {
    return DateFormat('d MMMM y').format(date); // e.g., "15 October 2023"
  }
}

/// Formats a timestamp into a human-readable string.
String formatTimestamp(String timestamp) {
  final date = DateTime.parse(timestamp);
  return DateFormat('h:mm a').format(date); // e.g., "10:30 AM"
}
