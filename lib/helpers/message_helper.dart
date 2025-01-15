Map<String, List<Map<String, dynamic>>> groupMessagesByDate(
    List<Map<String, dynamic>> messages) {
  final groupedMessages = <String, List<Map<String, dynamic>>>{};

  for (final message in messages) {
    final timestamp = message['timestamp'];
    final messageTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(messageTime);

    String dateLabel;
    if (difference.inDays == 0) {
      dateLabel = 'Today';
    } else if (difference.inDays == 1) {
      dateLabel = 'Yesterday';
    } else if (difference.inDays < 7) {
      dateLabel = 'Last ${_getDayOfWeek(messageTime.weekday)}';
    } else {
      dateLabel = '${messageTime.day}/${messageTime.month}/${messageTime.year}';
    }

    if (!groupedMessages.containsKey(dateLabel)) {
      groupedMessages[dateLabel] = [];
    }
    groupedMessages[dateLabel]!.add(message);
  }

  return groupedMessages;
}

// Define the _getDayOfWeek function
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
