import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/config/theme.dart';
import 'package:quickpass/models/leave_request.dart';
import 'package:quickpass/screens/employee/widgets/leave_history_card.dart';

import '../helpers/test_setup.dart';

final _now = DateTime.now();

LeaveRequest _makeLeave({LeaveStatus status = LeaveStatus.approved, bool isExpired = false}) {
  return LeaveRequest(
    leaveId: 'LV-001',
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

Widget _buildApp(LeaveRequest leave) {
  return MaterialApp(
    theme: QuickpassTheme.light,
    home: Scaffold(
      body: LeaveHistoryCard(
        leave: leave,
        onTap: () {},
        onCancel: () {},
      ),
    ),
  );
}

void main() {
  setUp(() async {
    await setupTestInfrastructure();
  });

  group('LeaveHistoryCard', () {
    testWidgets('shows Expired badge and hides cancel when leave is expired',
        (tester) async {
      await tester.pumpWidget(_buildApp(_makeLeave(isExpired: true)));
      await tester.pump();
      expect(find.text('Expired'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('shows status badge and cancel button when approved and not expired',
        (tester) async {
      await tester.pumpWidget(_buildApp(_makeLeave()));
      await tester.pump();
      expect(find.text('APPROVED'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}