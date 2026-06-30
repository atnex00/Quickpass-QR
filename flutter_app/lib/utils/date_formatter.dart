import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat dateDisplay = DateFormat('MMM dd, yyyy');
  static final DateFormat dateApi = DateFormat('yyyy-MM-dd');
  static final DateFormat timeDisplay = DateFormat('hh:mm a');
  static final DateFormat timeApi = DateFormat('HH:mm:ss');
  static final DateFormat dateTimeDisplay = DateFormat('MMM dd, yyyy hh:mm a');
  static final DateFormat dateTimeApi = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
  static final DateFormat monthDay = DateFormat('MMM dd');
  static final DateFormat dayName = DateFormat('EEEE');

  static String formatDate(DateTime date) => dateDisplay.format(date);
  static String formatTime(DateTime date) => timeDisplay.format(date);
  static String formatDateTime(DateTime date) => dateTimeDisplay.format(date);
  static String formatDateApi(DateTime date) => dateApi.format(date);
  static String formatTimeOfDay(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${h.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  static String durationString(DateTime start, DateTime end) {
    final diff = end.difference(start);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
