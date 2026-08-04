import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:quickpass/config/theme.dart';
import 'package:quickpass/models/leave_request.dart';
import 'package:quickpass/providers/auth_provider.dart';
import 'package:quickpass/providers/notification_provider.dart';
import 'package:quickpass/screens/employee/qr_display_screen.dart';
import 'package:quickpass/services/api_service.dart';

import '../helpers/mocks.mocks.dart';
import '../helpers/test_setup.dart';

String _qrPayload() {
  final payload = jsonEncode({
    'leave_id': 'LV-TEST-001',
    'employee_id': '000001',
    'type': 'OUT',
    'timestamp':
        DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
  });
  return base64Url.encode(utf8.encode(payload));
}

LeaveRequest _makeLeave() {
  final qr = _qrPayload();
  final now = DateTime.now();
  return LeaveRequest(
    leaveId: 'LV-TEST-001',
    employeeId: '000001',
    employeeName: 'James Wilson',
    departmentId: 'DEPT-001',
    supervisorId: '000011',
    supervisorName: 'Ethan White',
    leaveDate: DateTime.now(),
    startTime: '09:00',
    endTime: '17:00',
    reason: 'Dental appointment',
    status: LeaveStatus.approved,
    outQrCode: qr,
    inQrCode: qr,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _buildTestApp(MockApiService mockApi, LeaveRequest leave) {
  return MaterialApp(
    theme: QuickpassTheme.light,
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(api: mockApi)),
        ChangeNotifierProvider<NotificationProvider>(
            create: (_) => NotificationProvider()),
        Provider<ApiService>.value(value: mockApi),
      ],
      child: QrDisplayScreen(leave: leave),
    ),
  );
}

void main() {
  late MockApiService mockApi;

  setUp(() async {
    await setupTestInfrastructure();
    mockApi = MockApiService();
    when(mockApi.getStoredToken()).thenAnswer((_) async => null);
  });

  testWidgets('renders approved leave with OUT and IN QR passes',
      (WidgetTester tester) async {
    final leave = _makeLeave();
    when(mockApi.getLeaveById('LV-TEST-001'))
        .thenAnswer((_) async => leave);

    await tester.pumpWidget(_buildTestApp(mockApi, leave));
    await tester.pump();

    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Dental appointment'), findsOneWidget);
    expect(find.text('ID: #LV-TEST-001'), findsOneWidget);
    expect(find.text('OUT PASS'), findsOneWidget);
    expect(find.text('Exit Authorized'), findsOneWidget);
    expect(find.text('Scan at Main Gate (Exit)'), findsOneWidget);
    expect(find.text('IN PASS'), findsOneWidget);
    expect(find.text('Entry Authorized'), findsOneWidget);
    expect(find.text('Scan at Main Gate (Entry)'), findsOneWidget);
    expect(find.text('Pass Guidelines'), findsNothing);
    await tester.scrollUntilVisible(find.text('Pass Guidelines'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Pass Guidelines'), findsOneWidget);
    expect(find.byType(QrImageView), findsNWidgets(2));
    expect(find.textContaining('Expires in'), findsOneWidget);
    expect(find.text('Ready to scan'), findsOneWidget);
  });

  testWidgets('polling keeps QR passes visible after refresh',
      (WidgetTester tester) async {
    final leave = _makeLeave();
    when(mockApi.getLeaveById('LV-TEST-001'))
        .thenAnswer((_) async => leave);

    await tester.pumpWidget(_buildTestApp(mockApi, leave));
    await tester.pump();

    await tester.pump(const Duration(seconds: 6));

    expect(find.text('OUT PASS'), findsOneWidget);
    expect(find.text('IN PASS'), findsOneWidget);
    expect(find.byType(QrImageView), findsNWidgets(2));
    verify(mockApi.getLeaveById('LV-TEST-001')).called(1);
  });
}
