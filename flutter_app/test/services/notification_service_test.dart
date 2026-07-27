import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/services/notification_service.dart';

import '../helpers/test_setup.dart';

void main() {
  setUp(() async {
    await setupTestInfrastructure();
  });

  group('NotificationService', () {
    test('singleton returns same instance', () {
      expect(NotificationService(), same(NotificationService()));
    });

    test('consumePendingScreen returns null when no pending screen', () {
      expect(NotificationService().consumePendingScreen(), isNull);
    });

    test('consumePendingScreen clears after first call', () {
      expect(NotificationService().consumePendingScreen(), isNull);
      expect(NotificationService().consumePendingScreen(), isNull);
    });
  });
}
