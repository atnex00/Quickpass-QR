import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:quickpass/config/theme.dart';
import 'package:quickpass/providers/notification_provider.dart';
import 'package:quickpass/screens/admin/admin_reports_tab.dart';
import 'package:quickpass/services/api_service.dart';

import '../helpers/mocks.mocks.dart';
import '../helpers/test_setup.dart';

void main() {
  late MockApiService mockApi;

  setUp(() async {
    await setupTestInfrastructure();
    mockApi = MockApiService();
    when(mockApi.getReports(
            startDate: anyNamed('startDate'),
            endDate: anyNamed('endDate')))
        .thenAnswer((_) async => {
              'success': true,
              'data': [
                {
                  'status': 'approved',
                  'employee_name': 'James Wilson',
                  'leave_date': '2026-08-04',
                  'start_time': '09:00',
                  'end_time': '17:00',
                  'reason': 'Vacation',
                },
              ],
            });
    when(mockApi.getReports(type: 'department'))
        .thenAnswer((_) async => {
              'success': true,
              'data': [
                {
                  'department_name': 'TSD · Technical Services Department',
                  'department_id': 'DEP-002',
                  'pending': 1,
                  'approved': 2,
                  'rejected': 0,
                  'completed': 5,
                },
                {
                  'department_name': 'IAD · Internal Audit Department',
                  'department_id': 'DEP-004',
                  'pending': 0,
                  'approved': 1,
                  'rejected': 1,
                  'completed': 2,
                },
              ],
            });
  });

  Widget wrap() {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: mockApi),
        ChangeNotifierProvider<NotificationProvider>(
            create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        theme: QuickpassTheme.light,
        home: const ReportsTab(),
      ),
    );
  }

  testWidgets('department overview shows a code-to-name legend',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Department Overview'), findsOneWidget);
    expect(find.text('Department Legend'), findsOneWidget);
    expect(find.text('TSD'), findsNWidgets(2));
    expect(find.text('Technical Services Department'), findsOneWidget);
    expect(find.text('IAD'), findsNWidgets(2));
    expect(find.text('Internal Audit Department'), findsOneWidget);
  });
}