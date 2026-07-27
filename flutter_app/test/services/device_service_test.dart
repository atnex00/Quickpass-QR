import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/services/device_service.dart';

import '../helpers/test_setup.dart';

void main() {
  setUp(() async {
    await setupTestInfrastructure();
  });

  group('DeviceService', () {
    test('getFingerprint returns a SHA-256 hex string', () async {
      final result = await DeviceService.getFingerprint();
      expect(result, isA<String>());
      expect(result.length, 64);
      expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(result), true);
    });
  });
}
