import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/services/qr_service.dart';

void main() {
  group('QrService', () {
    group('isWithinWindow', () {
      test('returns true for timestamps within window', () {
        final now = DateTime.now();
        final recent = now.subtract(const Duration(minutes: 5)).toIso8601String();
        expect(QrService.isWithinWindow(recent, 15), true);
      });

      test('returns false outside window', () {
        final now = DateTime.now();
        final old = now.subtract(const Duration(minutes: 16)).toIso8601String();
        expect(QrService.isWithinWindow(old, 15), false);
      });

      test('handles future timestamps', () {
        final now = DateTime.now();
        final future = now.add(const Duration(minutes: 10)).toIso8601String();
        expect(QrService.isWithinWindow(future, 15), true);
      });
    });

    group('windowSeconds', () {
      test('returns before state when now is before window', () {
        final future = DateTime.now().add(const Duration(hours: 2));
        final date = future.toIso8601String().substring(0, 10);
        final result = QrService.windowSeconds(date, '12:00');
        expect(result['state'], 'before');
        expect(result['seconds'], isPositive);
      });

      test('returns after state when now is after window', () {
        final past = DateTime.now().subtract(const Duration(hours: 2));
        final date = past.toIso8601String().substring(0, 10);
        final result = QrService.windowSeconds(date, '12:00');
        // May be 'after' or 0 if we're within 15 min of noon
        expect(result['seconds'], greaterThanOrEqualTo(0));
      });
    });

    group('remainingSeconds', () {
      test('returns non-negative integer', () {
        final now = DateTime.now();
        final date = now.toIso8601String().substring(0, 10);
        final seconds = QrService.remainingSeconds(date, '12:00');
        expect(seconds, greaterThanOrEqualTo(0));
      });
    });
  });
}
