import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quickpass/config/theme.dart';
import 'package:quickpass/models/leave_request.dart';
import 'package:quickpass/providers/leave_provider.dart';
import 'package:quickpass/screens/employee/widgets/recent_activity_section.dart';

import '../helpers/mocks.mocks.dart';
import '../helpers/test_setup.dart';

final _now = DateTime.now();

LeaveRequest _makeLeave(String id, LeaveStatus status, {bool isExpired = false}) {
  return LeaveRequest(
    leaveId: id,
    employeeId: '000001',
    employeeName: 'James Wilson',
    departmentId: 'DEP-001',
    supervisorId: '000011',
    supervisorName: 'Ethan White',
    leaveDate: DateTime(2026, 7, 21),
    startTime: '09:00',
    endTime: '17:00',
    reason: 'Medical appointment',
    status: status,
    createdAt: _now,
    updatedAt: _now,
    isExpired: isExpired,
  );
}

Widget _buildApp(List<LeaveRequest> history, {bool isLoading = false}) {
  return MaterialApp(
    theme: QuickpassTheme.light,
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => LeaveProvider(api: MockApiService())),
      ],
      child: Scaffold(
        body: RecentActivitySection(
          isLoading: isLoading,
          history: history,
          onSeeAll: () {},
        ),
      ),
    ),
  );
}

void main() {
  setUp(() async {
    await setupTestInfrastructure();
  });

  group('RecentActivitySection expired notice', () {
    testWidgets('shows notice when the newest leave is expired',
        (tester) async {
      await tester.pumpWidget(_buildApp([
        _makeLeave('LV-3', LeaveStatus.approved, isExpired: true),
        _makeLeave('LV-2', LeaveStatus.completed),
      ]));
      await tester.pump();
      expect(find.text('Your leave pass has expired'), findsOneWidget);
      expect(find.text('Request Again'), findsOneWidget);
    });

    testWidgets('hides notice when a newer leave exists', (tester) async {
      await tester.pumpWidget(_buildApp([
        _makeLeave('LV-3', LeaveStatus.pending),
        _makeLeave('LV-2', LeaveStatus.approved, isExpired: true),
        _makeLeave('LV-1', LeaveStatus.completed),
      ]));
      await tester.pump();
      expect(find.text('Your leave pass has expired'), findsNothing);
    });

    testWidgets('shows Expired badge on expired card', (tester) async {
      await tester.pumpWidget(_buildApp([
        _makeLeave('LV-1', LeaveStatus.approved, isExpired: true),
      ]));
      await tester.pump();
      expect(find.text('Expired'), findsOneWidget);
    });
  });
}