// helpers/date_formatter.dart
String formatTimestamp(String timestamp) {
  final now = DateTime.now();
  final messageTime = DateTime.parse(timestamp);
  final difference = now.difference(messageTime);

  if (difference.inDays == 0) {
    // Today: Show time (e.g., "10:30 AM")
    return '${messageTime.hour}:${messageTime.minute.toString().padLeft(2, '0')}';
  } else if (difference.inDays == 1) {
    // Yesterday: Show "Yesterday"
    return 'Yesterday';
  } else if (difference.inDays < 7) {
    // Within the last week: Show day (e.g., "Monday")
    return _getDayOfWeek(messageTime.weekday);
  } else {
    // Older than a week: Show date (e.g., "12/10/2023")
    return '${messageTime.day}/${messageTime.month}/${messageTime.year}';
  }
}

String _getDayOfWeek(int weekday) {
  switch (weekday) {
    case 1:
      return 'Monday';
    case 2:
      return 'Tuesday';
    case 3:
      return 'Wednesday';
    case 4:
      return 'Thursday';
    case 5:
      return 'Friday';
    case 6:
      return 'Saturday';
    case 7:
      return 'Sunday';
    default:
      return '';
  }
}
