import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/services/analytics_service.dart';

import '../helpers/test_setup.dart';

void main() {
  setUp(() async {
    await setupTestInfrastructure();
  });

  group('AnalyticsService', () {
    test('setEnabled(false) prevents event logging', () async {
      AnalyticsService.setEnabled(false);
      final service = AnalyticsService();
      await expectLater(
        service.logLogin(role: 'employee'),
        completes,
      );
      await expectLater(service.logLogout(), completes);
      await expectLater(service.logLeaveSubmitted(), completes);
      await expectLater(service.logLeaveApproved(), completes);
      await expectLater(service.logLeaveRejected(), completes);
      await expectLater(service.logLeaveRevoked(), completes);
      await expectLater(
        service.logQrScan(qrType: 'OUT', isValid: true),
        completes,
      );
    });

    test('logLogin accepts role parameter', () async {
      AnalyticsService.setEnabled(false);
      final service = AnalyticsService();
      await expectLater(
        service.logLogin(role: 'admin'),
        completes,
      );
    });

    test('logQrScan accepts qrType and isValid', () async {
      AnalyticsService.setEnabled(false);
      final service = AnalyticsService();
      await expectLater(
        service.logQrScan(qrType: 'IN', isValid: false),
        completes,
      );
    });

    test('singleton returns same instance', () {
      final a = AnalyticsService();
      final b = AnalyticsService();
      expect(a, same(b));
    });
  });
}
