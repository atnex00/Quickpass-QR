import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:quickpass/models/leave_request.dart';
import 'package:quickpass/providers/leave_provider.dart';

import '../helpers/mocks.mocks.dart';
import '../helpers/test_setup.dart';

void main() {
  late MockApiService mockApi;
  late LeaveProvider provider;

  setUp(() async {
    await setupTestInfrastructure();
    mockApi = MockApiService();
    provider = LeaveProvider(api: mockApi);
  });

  group('loadHistory', () {
    test('loads and counts history correctly', () async {
      when(mockApi.getLeaveHistory(status: anyNamed('status')))
          .thenAnswer((_) async => {
                'data': [
                  {
                    'leave_id': 'l1',
                    'employee_id': '000001',
                    'employee_name': 'James Wilson',
                    'department_id': 'DEP-002',
                    'supervisor_id': '000011',
                    'supervisor_name': 'Ethan White',
                    'leave_date': '2025-06-15',
                    'start_time': '09:00',
                    'end_time': '17:00',
                    'reason': 'Sick',
                    'status': 'pending',
                    'created_at': '2025-06-10T08:00:00Z',
                    'updated_at': '2025-06-10T08:00:00Z',
                  },
                  {
                    'leave_id': 'l2',
                    'employee_id': '000001',
                    'employee_name': 'James Wilson',
                    'department_id': 'DEP-002',
                    'supervisor_id': '000011',
                    'supervisor_name': 'Ethan White',
                    'leave_date': '2025-06-20',
                    'start_time': '09:00',
                    'end_time': '17:00',
                    'reason': 'Vacation',
                    'status': 'approved',
                    'created_at': '2025-06-12T08:00:00Z',
                    'updated_at': '2025-06-12T08:00:00Z',
                  },
                  {
                    'leave_id': 'l3',
                    'employee_id': '000001',
                    'employee_name': 'James Wilson',
                    'department_id': 'DEP-002',
                    'supervisor_id': '000011',
                    'supervisor_name': 'Ethan White',
                    'leave_date': '2025-06-25',
                    'start_time': '09:00',
                    'end_time': '17:00',
                    'reason': 'Personal',
                    'status': 'completed',
                    'created_at': '2025-06-14T08:00:00Z',
                    'updated_at': '2025-06-14T08:00:00Z',
                  },
                ],
              });

      await provider.loadHistory();

      expect(provider.history.length, 3);
      expect(provider.pendingCount, 1);
      expect(provider.approvedCount, 1);
      expect(provider.completedCount, 1);
      expect(provider.isLoading, false);
    });

    test('sets error on failure', () async {
      when(mockApi.getLeaveHistory()).thenThrow(Exception('Failed to load'));

      await provider.loadHistory();

      expect(provider.error, 'Failed to load');
      expect(provider.isLoading, false);
    });
  });

  group('submitLeave', () {
    test('adds leave to history on success', () async {
      when(mockApi.submitLeave(
        leaveDate: anyNamed('leaveDate'),
        startTime: anyNamed('startTime'),
        endTime: anyNamed('endTime'),
        reason: anyNamed('reason'),
      )).thenAnswer((_) async {
        final mockLeave = _createMockLeaveRequest('l4', 'pending');
        return mockLeave;
      });

      final result = await provider.submitLeave(
        leaveDate: '2025-07-01',
        startTime: '09:00',
        endTime: '17:00',
        reason: 'New leave',
      );

      expect(result, isNotNull);
      expect(result?.leaveId, 'l4');
      expect(provider.history.length, 1);
      expect(provider.isLoading, false);
    });

    test('returns null on failure', () async {
      when(mockApi.submitLeave(
        leaveDate: anyNamed('leaveDate'),
        startTime: anyNamed('startTime'),
        endTime: anyNamed('endTime'),
        reason: anyNamed('reason'),
      )).thenThrow(Exception('Submission failed'));

      final result = await provider.submitLeave(
        leaveDate: '2025-07-01',
        startTime: '09:00',
        endTime: '17:00',
        reason: 'New leave',
      );

      expect(result, isNull);
      expect(provider.error, 'Submission failed');
    });
  });

  group('loadActiveLeave', () {
    test('loads active leave when present', () async {
      when(mockApi.getActiveLeave()).thenAnswer(
          (_) async => _createMockLeaveRequest('active-1', 'active'));

      await provider.loadActiveLeave();

      expect(provider.activeLeave, isNotNull);
      expect(provider.activeLeave?.leaveId, 'active-1');
    });

    test('sets null when no active leave', () async {
      when(mockApi.getActiveLeave()).thenAnswer((_) async => null);

      await provider.loadActiveLeave();

      expect(provider.activeLeave, isNull);
    });
  });

  group('deleteLeave', () {
    test('removes leave from history on success', () async {
      when(mockApi.getLeaveHistory(status: anyNamed('status')))
          .thenAnswer((_) async => {
                'data': [
                  {
                    'leave_id': 'l1',
                    'employee_id': '000001',
                    'employee_name': 'James Wilson',
                    'department_id': 'DEP-002',
                    'supervisor_id': '000011',
                    'supervisor_name': 'Ethan White',
                    'leave_date': '2025-06-15',
                    'start_time': '09:00',
                    'end_time': '17:00',
                    'reason': 'Sick',
                    'status': 'pending',
                    'created_at': '2025-06-10T08:00:00Z',
                    'updated_at': '2025-06-10T08:00:00Z',
                  },
                ],
              });
      await provider.loadHistory();
      expect(provider.history.length, 1);

      when(mockApi.deleteLeave('l1')).thenAnswer((_) async {});

      await provider.deleteLeave('l1');

      expect(provider.history.length, 0);
    });
  });

  group('refresh', () {
    test('calls both loadHistory and loadActiveLeave', () async {
      when(mockApi.getLeaveHistory(status: anyNamed('status')))
          .thenAnswer((_) async => {'data': []});
      when(mockApi.getActiveLeave()).thenAnswer((_) async => null);

      await provider.refresh();

      expect(provider.history, isEmpty);
      expect(provider.activeLeave, isNull);
    });
  });
}

LeaveRequest _createMockLeaveRequest(String id, String status) {
  return LeaveRequest(
    leaveId: id,
    employeeId: '000001',
    employeeName: 'James Wilson',
    departmentId: 'DEP-002',
    supervisorId: '000011',
    supervisorName: 'Ethan White',
    leaveDate: DateTime(2025, 6, 15),
    startTime: '09:00',
    endTime: '17:00',
    reason: 'Test',
    status: LeaveStatus.fromString(status),
    createdAt: DateTime(2025, 6, 10),
    updatedAt: DateTime(2025, 6, 10),
  );
}
