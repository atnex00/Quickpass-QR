class QrService {
  static DateTime? _tryParse(String s) => DateTime.tryParse(s);

  static bool isWithinWindow(String qrTimestamp, int windowMinutes) {
    final qrTime = _tryParse(qrTimestamp);
    if (qrTime == null) return false;
    final now = DateTime.now();
    final diff = now.difference(qrTime).inMilliseconds.abs();
    return diff <= windowMinutes * 60 * 1000;
  }

  static bool isOutQrValid(
      String date, String startTime, DateTime? outScanTime) {
    if (outScanTime != null) return false;
    final start = _tryParse('${date}T${startTime.padLeft(5, '0')}:00');
    if (start == null) return false;
    final now = DateTime.now();
    final diff = now.difference(start).inMinutes.abs();
    return diff <= 15;
  }

  static bool isInQrValid(String date, String endTime, DateTime? inScanTime,
      DateTime? outScanTime) {
    if (inScanTime != null) return false;
    if (outScanTime == null) return false;
    final end = _tryParse('${date}T${endTime.padLeft(5, '0')}:00');
    if (end == null) return false;
    final now = DateTime.now();
    final diff = now.difference(end).inMinutes.abs();
    return diff <= 15;
  }

  static Map<String, dynamic> windowSeconds(String date, String time,
      {DateTime? now}) {
    final t = time.split(':').take(2).join(':');
    final target = _tryParse('${date}T$t:00');
    if (target == null) {
      return {'state': 'after', 'seconds': 0};
    }
    final windowStart = target.subtract(const Duration(minutes: 15));
    final windowEnd = target.add(const Duration(minutes: 15));
    now ??= DateTime.now();

    if (now.isBefore(windowStart)) {
      return {
        'state': 'before',
        'seconds': windowStart.difference(now).inSeconds
      };
    } else if (now.isBefore(windowEnd) || now.isAtSameMomentAs(windowEnd)) {
      return {
        'state': 'during',
        'seconds': windowEnd.difference(now).inSeconds
      };
    } else {
      return {'state': 'after', 'seconds': 0};
    }
  }

  static int remainingSeconds(String date, String time, {DateTime? now}) {
    final result = windowSeconds(date, time, now: now);
    return result['seconds'] as int;
  }
}
