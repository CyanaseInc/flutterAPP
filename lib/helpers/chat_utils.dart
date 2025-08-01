
import 'package:intl/intl.dart';

class ChatUtils {
  static final RegExp _urlRegExp = RegExp(
    r'((https?:\/\/)|(www\.))[^\s]+',
    caseSensitive: false,
  );

  static bool containsUrl(String text) {
    return _urlRegExp.hasMatch(text);
  }

  static List<String> extractUrls(String text) {
    return _urlRegExp.allMatches(text).map((match) => match.group(0)!).toList();
  }

  static String formatTime(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    return DateFormat.jm().format(dateTime);
  }

  static String getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return "Monday";
      case DateTime.tuesday:
        return "Tuesday";
      case DateTime.wednesday:
        return "Wednesday";
      case DateTime.thursday:
        return "Thursday";
      case DateTime.friday:
        return "Friday";
      case DateTime.saturday:
        return "Saturday";
      case DateTime.sunday:
        return "Sunday";
      default:
        return "";
    }
  }
}