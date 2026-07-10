import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:quickpass/providers/scan_provider.dart';

import '../helpers/mocks.mocks.dart';

void main() {
  late MockApiService mockApi;
  late ScanProvider provider;

  setUp(() {
    mockApi = MockApiService();
    provider = ScanProvider(api: mockApi);
  });

  group('validateScan', () {
    test('returns true on successful validation', () async {
      when(mockApi.validateScan('qr-data-123')).thenAnswer((_) async => {
            'success': true,
            'message': 'Valid QR code',
            'data': {'leave_id': 'l1'},
          });

      final result = await provider.validateScan('qr-data-123');

      expect(result, true);
      expect(provider.lastResult, isNotNull);
      expect(provider.lastResult?['success'], true);
      expect(provider.isLoading, false);
    });

    test('returns false when validation fails', () async {
      when(mockApi.validateScan('bad-qr')).thenAnswer((_) async => {
            'success': false,
            'message': 'Invalid QR code',
          });

      final result = await provider.validateScan('bad-qr');

      expect(result, false);
      expect(provider.isLoading, false);
    });

    test('returns false on exception', () async {
      when(mockApi.validateScan('error-qr'))
          .thenThrow(Exception('Network error'));

      final result = await provider.validateScan('error-qr');

      expect(result, false);
      expect(provider.error, 'Network error');
      expect(provider.lastResult, isNull);
    });
  });

  group('setScanning', () {
    test('updates scanning state', () {
      expect(provider.isScanning, false);

      provider.setScanning(true);
      expect(provider.isScanning, true);

      provider.setScanning(false);
      expect(provider.isScanning, false);
    });
  });

  group('clearResult', () {
    test('clears last result and error', () {
      when(mockApi.validateScan('qr'))
          .thenAnswer((_) async => {'success': true});
      provider.validateScan('qr');
      provider.clearResult();

      expect(provider.lastResult, isNull);
      expect(provider.error, isNull);
    });
  });
}
