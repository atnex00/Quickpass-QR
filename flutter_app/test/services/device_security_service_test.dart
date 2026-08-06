import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/services/device_security_service.dart';

import '../helpers/test_setup.dart';

void main() {
  setUp(() async {
    await setupTestInfrastructure();
  });

  group('DeviceSecurityService', () {
    test('isDeviceCompromised returns true when safe_device throws',
        () async {
      final result = await DeviceSecurityService.isDeviceCompromised();
      expect(result, true);
    });

    test('handleCompromisedDevice does not throw', () async {
      await expectLater(
        DeviceSecurityService.handleCompromisedDevice(),
        completes,
      );
    });
  });

  group('BlockedApp', () {
    testWidgets('renders security blocked message', (tester) async {
      await tester.pumpWidget(const BlockedApp());
      expect(find.text('Security Blocked'), findsOneWidget);
      expect(
        find.textContaining('cannot run on a rooted or compromised device'),
        findsOneWidget,
      );
      expect(find.text('Exit'), findsOneWidget);
      expect(find.byIcon(Icons.security), findsOneWidget);
    });

    testWidgets('prevents back navigation', (tester) async {
      await tester.pumpWidget(const BlockedApp());
      final popScopes = find.byType(PopScope);
      expect(popScopes, findsOneWidget);
    });
  });
}
