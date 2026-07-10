import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:quickpass/models/leave_request.dart';
import 'package:quickpass/providers/supervisor_provider.dart';

import '../helpers/mocks.mocks.dart';

LeaveRequest _mockLeave(String id, String status) {
  return LeaveRequest(
    leaveId: id,
    employeeId: '000004',
    employeeName: 'Bob',
    departmentId: '1',
    supervisorId: '000004',
    supervisorName: 'David Kim',
    leaveDate: DateTime(2025, 7, 1),
    startTime: '09:00',
    endTime: '17:00',
    reason: 'Test leave',
    status: LeaveStatus.fromString(status),
    createdAt: DateTime(2025, 6, 28),
    updatedAt: DateTime(2025, 6, 28),
  );
}

void main() {
  late MockApiService mockApi;
  late SupervisorProvider provider;

  setUp(() {
    mockApi = MockApiService();
    provider = SupervisorProvider(api: mockApi);
  });

  group('loadPendingRequests', () {
    test('loads pending requests successfully', () async {
      when(mockApi.getPendingRequests()).thenAnswer((_) async => [
            _mockLeave('l1', 'pending'),
            _mockLeave('l2', 'pending'),
          ]);

      await provider.loadPendingRequests();

      expect(provider.pendingRequests.length, 2);
      expect(provider.pendingCount, 2);
      expect(provider.isLoading, false);
    });

    test('sets error on failure', () async {
      when(mockApi.getPendingRequests()).thenThrow(Exception('Server error'));

      await provider.loadPendingRequests();

      expect(provider.error, 'Server error');
      expect(provider.isLoading, false);
    });
  });

  group('approveLeave', () {
    test('removes approved leave from pending list', () async {
      when(mockApi.getPendingRequests()).thenAnswer((_) async => [
            _mockLeave('l1', 'pending'),
            _mockLeave('l2', 'pending'),
          ]);
      await provider.loadPendingRequests();
      expect(provider.pendingCount, 2);

      when(mockApi.approveLeave('l1'))
          .thenAnswer((_) async => _mockLeave('l1', 'approved'));

      final result = await provider.approveLeave('l1');

      expect(result, isNotNull);
      expect(result?.status, LeaveStatus.approved);
      expect(provider.pendingCount, 1);
    });

    test('returns null on failure', () async {
      when(mockApi.approveLeave('l1')).thenThrow(Exception('Approve failed'));

      final result = await provider.approveLeave('l1');

      expect(result, isNull);
      expect(provider.error, 'Approve failed');
    });
  });

  group('rejectLeave', () {
    test('removes rejected leave from pending list', () async {
      when(mockApi.getPendingRequests()).thenAnswer((_) async => [
            _mockLeave('l1', 'pending'),
          ]);
      await provider.loadPendingRequests();
      expect(provider.pendingCount, 1);

      when(mockApi.rejectLeave('l1', 'Not approved'))
          .thenAnswer((_) async => _mockLeave('l1', 'rejected'));

      final result = await provider.rejectLeave('l1', 'Not approved');

      expect(result, isNotNull);
      expect(result?.status, LeaveStatus.rejected);
      expect(provider.pendingCount, 0);
    });
  });

  group('loadApprovedLeaves', () {
    test('loads approved leaves', () async {
      when(mockApi.getApprovedLeaves()).thenAnswer((_) async => [
            _mockLeave('l1', 'approved'),
          ]);

      await provider.loadApprovedLeaves();

      expect(provider.approvedLeaves.length, 1);
    });
  });

  group('revokeApproval', () {
    test('removes revoked leave from approved list', () async {
      when(mockApi.getApprovedLeaves()).thenAnswer((_) async => [
            _mockLeave('l1', 'approved'),
          ]);
      await provider.loadApprovedLeaves();
      expect(provider.approvedLeaves.length, 1);

      when(mockApi.revokeApproval('l1'))
          .thenAnswer((_) async => _mockLeave('l1', 'pending'));

      final result = await provider.revokeApproval('l1');

      expect(result, isNotNull);
      expect(provider.approvedLeaves.length, 0);
    });
  });
}
