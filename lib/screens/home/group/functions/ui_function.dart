class UIFunctions {
  static String formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return "Last seen just now";
    } else if (difference.inMinutes < 60) {
      return "Last seen ${difference.inMinutes} minutes ago";
    } else if (difference.inHours < 24) {
      return "Last seen ${difference.inHours} hours ago";
    } else {
      return "Last seen ${difference.inDays} days ago";
    }
  }

  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  static String truncateText(String text, {int maxLength = 30}) {
    if (text.length > maxLength) {
      return text.substring(0, maxLength) + '...';
    }
    return text;
  }
}
