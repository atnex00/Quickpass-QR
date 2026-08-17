import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:quickpass/models/employee.dart';
import 'package:quickpass/models/leave_request.dart';
import 'package:quickpass/providers/directory_provider.dart';

import '../helpers/mocks.mocks.dart';
import '../helpers/test_setup.dart';

Employee _mockMember(String id, String name, String department,
    {int leaveCount = 0}) {
  return Employee(
    employeeId: id,
    fullName: name,
    position: 'Engineer',
    departmentId: 'DEP-$department',
    departmentName: department,
    isSupervisor: false,
    isAdmin: false,
    isSecurity: false,
    isActive: true,
    email: '',
    profilePhoto: null,
    leaveCount: leaveCount,
  );
}

LeaveRequest _mockLeave(String id, String status) {
  return LeaveRequest(
    leaveId: id,
    employeeId: '000001',
    employeeName: 'James Wilson',
    departmentId: 'DEP-TSD',
    supervisorId: '000011',
    supervisorName: 'Ethan White',
    leaveDate: DateTime(2025, 7),
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
  late DirectoryProvider provider;

  setUp(() async {
    await setupTestInfrastructure();
    mockApi = MockApiService();
    provider = DirectoryProvider(api: mockApi);
  });

  test('loadTeam stores members from api', () async {
    when(mockApi.getMyTeam()).thenAnswer((_) async => [
          _mockMember('000001', 'James Wilson', 'TSD'),
          _mockMember('000002', 'Jane Doe', 'TSD', leaveCount: 3),
        ]);

    await provider.loadTeam();

    expect(provider.team, hasLength(2));
    expect(provider.team.first.fullName, 'James Wilson');
    expect(provider.team.last.leaveCount, 3);
    expect(provider.isLoading, isFalse);
    expect(provider.error, isNull);
  });

  test('loadTeam falls back to cache on error', () async {
    when(mockApi.getMyTeam()).thenThrow(Exception('network'));

    await provider.loadTeam();

    expect(provider.error, isNotNull);
    expect(provider.fromCache, isFalse);
  });

  test('loadDirectory stores all employees', () async {
    when(mockApi.getDirectory()).thenAnswer((_) async => [
          _mockMember('000001', 'James Wilson', 'TSD'),
          _mockMember('000015', 'Liam Thomas', 'ISD'),
        ]);

    await provider.loadDirectory();

    expect(provider.directory, hasLength(2));
    expect(provider.directory[1].departmentName, 'ISD');
  });

  test('loadTeamMemberLeaves stores per-employee history', () async {
    when(mockApi.getTeamMemberLeaves('000001')).thenAnswer((_) async => [
          _mockLeave('L1', 'approved'),
          _mockLeave('L2', 'completed'),
        ]);

    await provider.loadTeamMemberLeaves('000001');

    expect(provider.teamLeavesOf('000001'), hasLength(2));
    expect(provider.teamLeavesOf('000001')!.first.status,
        LeaveStatus.approved);
  });

  test('loadTeamMemberLeaves failure yields empty list', () async {
    when(mockApi.getTeamMemberLeaves('000001')).thenThrow(Exception('down'));

    await provider.loadTeamMemberLeaves('000001');

    expect(provider.teamLeavesOf('000001'), isEmpty);
  });

  test('reset clears all state', () async {
    when(mockApi.getMyTeam()).thenAnswer((_) async => [_mockMember('1', 'A', 'TSD')]);
    await provider.loadTeam();

    provider.reset();

    expect(provider.team, isEmpty);
    expect(provider.directory, isEmpty);
    expect(provider.error, isNull);
  });
}