class QrService {
  static bool isWithinWindow(String qrTimestamp, int windowMinutes) {
    final qrTime = DateTime.parse(qrTimestamp);
    final now = DateTime.now();
    final diff = now.difference(qrTime).inMilliseconds.abs();
    return diff <= windowMinutes * 60 * 1000;
  }

  static bool isOutQrValid(String date, String startTime, DateTime? outScanTime) {
    if (outScanTime != null) return false;
    final start = DateTime.parse('${date}T${startTime.padLeft(5, '0')}:00');
    final now = DateTime.now();
    final diff = now.difference(start).inMinutes.abs();
    return diff <= 15;
  }

  static bool isInQrValid(String date, String endTime, DateTime? inScanTime, DateTime? outScanTime) {
    if (inScanTime != null) return false;
    if (outScanTime == null) return false;
    final end = DateTime.parse('${date}T${endTime.padLeft(5, '0')}:00');
    final now = DateTime.now();
    final diff = now.difference(end).inMinutes.abs();
    return diff <= 15;
  }

  /// Returns a map with window state info for the QR code timer.
  /// Keys: 'state' ('before', 'during', 'after'), 'seconds' (int).
  static Map<String, dynamic> windowSeconds(String date, String time) {
    final t = time.split(':').take(2).join(':');
    final target = DateTime.parse('${date}T$t:00');
    final windowStart = target.subtract(const Duration(minutes: 15));
    final windowEnd = target.add(const Duration(minutes: 15));
    final now = DateTime.now();

    if (now.isBefore(windowStart)) {
      return {'state': 'before', 'seconds': windowStart.difference(now).inSeconds};
    } else if (now.isBefore(windowEnd) || now.isAtSameMomentAs(windowEnd)) {
      return {'state': 'during', 'seconds': windowEnd.difference(now).inSeconds};
    } else {
      return {'state': 'after', 'seconds': 0};
    }
  }

  static int remainingSeconds(String date, String time) {
    final result = windowSeconds(date, time);
    return result['seconds'] as int;
  }
}
