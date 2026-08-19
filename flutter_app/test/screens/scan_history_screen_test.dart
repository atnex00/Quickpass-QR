import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:quickpass/config/theme.dart';
import 'package:quickpass/providers/scan_provider.dart';
import 'package:quickpass/screens/security/scan_history_screen.dart';

import '../helpers/mocks.mocks.dart';
import '../helpers/test_setup.dart';

void main() {
  late MockApiService mockApi;

  setUp(() async {
    await setupTestInfrastructure();
    mockApi = MockApiService();
  });

  Widget wrap({String? departmentName, String? departmentCode}) {
    return ChangeNotifierProvider(
      create: (_) => ScanProvider(api: mockApi),
      child: MaterialApp(
        theme: QuickpassTheme.light,
        home: ScanHistoryScreen(
          departmentName: departmentName,
          departmentCode: departmentCode,
        ),
      ),
    );
  }

  void stubHistory(List<Map<String, dynamic>> data) {
    when(mockApi.getScanHistory(
            page: anyNamed('page'),
            limit: anyNamed('limit'),
            department: anyNamed('department')))
        .thenAnswer((_) async => {
              'data': data,
              'pagination': {'total': data.length, 'page': 1, 'pages': 1},
            });
  }

  void stubDepartments(List<Map<String, dynamic>> data) {
    when(mockApi.getScanHistoryDepartments())
        .thenAnswer((_) async => {'success': true, 'data': data});
  }

  Map<String, dynamic> departmentEntry({
    required String departmentName,
    required String departmentCode,
    int scanCount = 0,
  }) {
    return {
      'department_name': departmentName,
      'department_code': departmentCode,
      'scan_count': scanCount,
    };
  }

  Map<String, dynamic> logEntry({
    required String qrType,
    String? departmentName,
    String? departmentCode,
    String? scannedByName,
  }) {
    return {
      'log_id': 1,
      'leave_id': 'LV-001',
      'qr_type': qrType,
      'scan_time': DateTime.now().toIso8601String(),
      'is_valid': true,
      'employee_name': 'James Wilson',
      'employee_id': '000001',
      if (departmentName != null) 'department_name': departmentName,
      if (departmentCode != null) 'department_code': departmentCode,
      if (scannedByName != null) 'scanned_by_name': scannedByName,
    };
  }

  testWidgets('shows department cards with scan counts', (tester) async {
    stubDepartments([
      departmentEntry(
          departmentName: 'Information Systems',
          departmentCode: 'ISD',
          scanCount: 2),
      departmentEntry(
          departmentName: 'Technical Services',
          departmentCode: 'TSD',
          scanCount: 1),
    ]);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Information Systems'), findsOneWidget);
    expect(find.text('Technical Services'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('shows empty state when no departments', (tester) async {
    stubDepartments([]);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('No departments yet'), findsOneWidget);
  });

  testWidgets('tapping a department card opens its filtered history',
      (tester) async {
    stubDepartments([
      departmentEntry(
          departmentName: 'Technical Services',
          departmentCode: 'TSD',
          scanCount: 1),
    ]);
    stubHistory([
      logEntry(
          qrType: 'OUT',
          departmentName: 'Technical Services',
          departmentCode: 'TSD'),
    ]);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Technical Services'));
    await tester.pumpAndSettle();

    expect(find.text('Scans for Technical Services'), findsOneWidget);
    verify(mockApi.getScanHistory(
            page: anyNamed('page'),
            limit: anyNamed('limit'),
            department: 'Technical Services'))
        .called(1);
  });

  testWidgets('shows department and scanned-by on history entries',
      (tester) async {
    stubHistory([
      logEntry(
          qrType: 'OUT',
          departmentName: 'Technical Services',
          departmentCode: 'TSD',
          scannedByName: 'Mike Ross'),
    ]);

    await tester.pumpWidget(
        wrap(departmentName: 'Technical Services', departmentCode: 'TSD'));
    await tester.pumpAndSettle();

    expect(find.text('James Wilson'), findsOneWidget);
    expect(find.text('Technical Services'), findsOneWidget);
    expect(find.text('TSD'), findsNWidgets(2));
    expect(find.textContaining('Scanned by Mike Ross'), findsOneWidget);
  });

  testWidgets('omits department and scanned-by when absent', (tester) async {
    stubHistory([logEntry(qrType: 'IN')]);

    await tester.pumpWidget(
        wrap(departmentName: 'Technical Services', departmentCode: 'TSD'));
    await tester.pumpAndSettle();

    expect(find.text('James Wilson'), findsOneWidget);
    expect(find.textContaining('Scanned by'), findsNothing);
  });

  testWidgets('shows filter header and loads history for a department',
      (tester) async {
    stubHistory([
      logEntry(
          qrType: 'OUT',
          departmentName: 'Technical Services',
          departmentCode: 'TSD'),
    ]);

    await tester.pumpWidget(
        wrap(departmentName: 'Technical Services', departmentCode: 'TSD'));
    await tester.pumpAndSettle();

    expect(find.text('Scans for Technical Services'), findsOneWidget);
    verify(mockApi.getScanHistory(
            page: anyNamed('page'),
            limit: anyNamed('limit'),
            department: 'Technical Services'))
        .called(1);
  });
}
