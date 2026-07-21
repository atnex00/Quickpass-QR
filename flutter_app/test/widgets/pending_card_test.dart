import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quickpass/config/theme.dart';
import 'package:quickpass/models/leave_request.dart';
import 'package:quickpass/providers/leave_provider.dart';
import 'package:quickpass/providers/supervisor_provider.dart';
import 'package:quickpass/widgets/pending_card.dart';

import '../helpers/mocks.mocks.dart';
import '../helpers/test_setup.dart';

final _now = DateTime.now();

LeaveRequest _makeLeave(String id) {
  return LeaveRequest(
    leaveId: id,
    employeeId: '000001',
    employeeName: 'Alice Chen',
    departmentId: 'DEP-001',
    supervisorId: '000004',
    supervisorName: 'David Kim',
    leaveDate: DateTime(2026, 7, 21),
    startTime: '09:00',
    endTime: '17:00',
    reason: 'Medical appointment',
    status: LeaveStatus.pending,
    createdAt: _now,
    updatedAt: _now,
    employeePosition: 'Engineer',
  );
}

Widget _buildApp({
  required LeaveRequest leave,
  bool showAdminActions = false,
}) {
  return MaterialApp(
    theme: QuickpassTheme.light,
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LeaveProvider(api: MockApiService())),
        ChangeNotifierProvider(create: (_) => SupervisorProvider(api: MockApiService())),
      ],
      child: Scaffold(
        body: PendingCard(
          leave: leave,
          showAdminActions: showAdminActions,
        ),
      ),
    ),
  );
}

void main() {
  setUp(() async {
    await setupTestInfrastructure();
  });

  group('PendingCard', () {
    testWidgets('renders employee info and leave details', (tester) async {
      await tester.pumpWidget(_buildApp(leave: _makeLeave('LV-001')));
      await tester.pump();
      expect(find.text('Alice Chen'), findsOneWidget);
      expect(find.text('Engineer'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Medical appointment'), findsOneWidget);
    });

    testWidgets('renders Approve and Reject buttons', (tester) async {
      await tester.pumpWidget(_buildApp(leave: _makeLeave('LV-002')));
      await tester.pump();
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    });

    testWidgets('shows delete button when showAdminActions', (tester) async {
      await tester.pumpWidget(_buildApp(
        leave: _makeLeave('LV-003'),
        showAdminActions: true,
      ));
      await tester.pump();
      expect(find.byTooltip('Delete'), findsOneWidget);
    });
  });
}
