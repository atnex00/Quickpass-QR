import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/utils/date_formatter.dart';

void main() {
  group('DateFormatter', () {
    group('formatDate', () {
      test('formats date to MMM dd, yyyy', () {
        final d = DateTime(2026, 7, 21);
        expect(DateFormatter.formatDate(d), 'Jul 21, 2026');
      });
    });

    group('formatDateApi', () {
      test('formats date to yyyy-MM-dd', () {
        final d = DateTime(2026, 7, 21);
        expect(DateFormatter.formatDateApi(d), '2026-07-21');
      });
    });

    group('formatTimeOfDay', () {
      test('midnight returns 12:00 AM', () {
        expect(DateFormatter.formatTimeOfDay(0, 0), '12:00 AM');
      });

      test('noon returns 12:00 PM', () {
        expect(DateFormatter.formatTimeOfDay(12, 0), '12:00 PM');
      });

      test('morning hour returns AM', () {
        expect(DateFormatter.formatTimeOfDay(9, 30), '09:30 AM');
      });

      test('afternoon hour returns PM', () {
        expect(DateFormatter.formatTimeOfDay(14, 15), '02:15 PM');
      });

      test('23:59 returns 11:59 PM', () {
        expect(DateFormatter.formatTimeOfDay(23, 59), '11:59 PM');
      });
    });

    group('durationString', () {
      test('same-day 9-17 returns 8h 0m', () {
        final start = DateTime(2026, 7, 21, 9, 0);
        final end = DateTime(2026, 7, 21, 17, 0);
        expect(DateFormatter.durationString(start, end), '8h 0m');
      });

      test('under an hour returns minutes only', () {
        final start = DateTime(2026, 7, 21, 10, 0);
        final end = DateTime(2026, 7, 21, 10, 30);
        expect(DateFormatter.durationString(start, end), '30m');
      });

      test('exact hour returns Xh 0m', () {
        final start = DateTime(2026, 7, 21, 9, 0);
        final end = DateTime(2026, 7, 21, 12, 0);
        expect(DateFormatter.durationString(start, end), '3h 0m');
      });

      test('zero duration returns 0m', () {
        final now = DateTime(2026, 7, 21, 10, 0);
        expect(DateFormatter.durationString(now, now), '0m');
      });
    });

    group('timeAgo', () {
      test('just now for less than a minute', () {
        final now = DateTime.now();
        expect(DateFormatter.timeAgo(now), 'Just now');
      });

      test('minutes ago', () {
        final d = DateTime.now().subtract(const Duration(minutes: 5));
        expect(DateFormatter.timeAgo(d), '5m ago');
      });

      test('hours ago', () {
        final d = DateTime.now().subtract(const Duration(hours: 3));
        expect(DateFormatter.timeAgo(d), '3h ago');
      });

      test('days ago', () {
        final d = DateTime.now().subtract(const Duration(days: 2));
        expect(DateFormatter.timeAgo(d), '2d ago');
      });
    });
  });
}
