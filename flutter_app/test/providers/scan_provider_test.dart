import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:quickpass/providers/scan_provider.dart';

import '../helpers/mocks.mocks.dart';
import '../helpers/test_setup.dart';

void main() {
  late MockApiService mockApi;
  late ScanProvider provider;

  setUp(() async {
    await setupTestInfrastructure();
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
    test('clears last result and error', () async {
      when(mockApi.validateScan('qr'))
          .thenAnswer((_) async => {'success': true});
      await provider.validateScan('qr');
      provider.clearResult();

      expect(provider.lastResult, isNull);
      expect(provider.error, isNull);
    });
  });

  group('loadHistoryDepartments', () {
    test('loads departments with scan counts', () async {
      when(mockApi.getScanHistoryDepartments()).thenAnswer((_) async => {
            'success': true,
            'data': [
              {
                'department_name': 'Information Systems',
                'department_code': 'ISD',
                'scan_count': 2,
              },
              {
                'department_name': 'Technical Services',
                'department_code': 'TSD',
                'scan_count': 1,
              },
            ],
          });

      await provider.loadHistoryDepartments();

      expect(provider.historyDepartments, hasLength(2));
      expect(provider.historyDepartments[0].departmentName,
          'Information Systems');
      expect(provider.historyDepartments[0].departmentCode, 'ISD');
      expect(provider.historyDepartments[0].scanCount, 2);
      expect(provider.historyDepartmentsLoading, false);
      expect(provider.error, isNull);
    });

    test('sets error on failure', () async {
      when(mockApi.getScanHistoryDepartments())
          .thenThrow(Exception('Network error'));

      await provider.loadHistoryDepartments();

      expect(provider.historyDepartments, isEmpty);
      expect(provider.historyDepartmentsLoading, false);
      expect(provider.error, 'Network error');
    });
  });
}
