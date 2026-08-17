import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:quickpass/config/theme.dart';
import 'package:quickpass/models/employee.dart';
import 'package:quickpass/providers/auth_provider.dart';
import 'package:quickpass/providers/directory_provider.dart';
import 'package:quickpass/providers/scan_provider.dart';
import 'package:quickpass/screens/security/security_shell.dart';

import '../helpers/mocks.mocks.dart';
import '../helpers/test_setup.dart';

void main() {
  late MockApiService mockApi;

  setUp(() async {
    await setupTestInfrastructure();
    mockApi = MockApiService();
    when(mockApi.getStoredToken()).thenAnswer((_) async => 'token');
    when(mockApi.getProfile()).thenAnswer((_) async => Employee.fromJson({
          'employee_id': '090901',
          'full_name': 'Mike Ross',
          'position': 'Head of Security',
          'department_id': 'DEP-001',
          'department_name': 'ISD · Institutional Services Department',
          'email': 'mike.ross@zaneco.com',
          'is_supervisor': false,
          'is_admin': false,
          'is_security': true,
          'is_active': true,
        }));
    when(mockApi.getDirectory()).thenAnswer((_) async => [
          Employee.fromJson({
            'employee_id': '000001',
            'full_name': 'James Wilson',
            'position': 'Software Engineer',
            'department_id': 'DEP-002',
            'department_name': 'TSD · Technical Services Department',
            'email': 'james.wilson@zaneco.com',
            'is_supervisor': false,
            'is_admin': false,
            'is_security': false,
            'is_active': true,
          }),
        ]);
  });

  testWidgets('security shell shows a Directory tab with employees',
      (tester) async {
    final auth = AuthProvider(api: mockApi);
    await auth.initialize();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<ScanProvider>(
          create: (_) => ScanProvider(api: mockApi),
        ),
        ChangeNotifierProvider<DirectoryProvider>(
          create: (_) => DirectoryProvider(api: mockApi),
        ),
      ],
      child: MaterialApp(
        theme: QuickpassTheme.light,
        home: const SecurityShell(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Directory'), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Scan'), findsWidgets);
    expect(find.text('History'), findsWidgets);

    await tester.tap(find.text('Directory'));
    await tester.pumpAndSettle();

    expect(find.text('James Wilson'), findsOneWidget);
    expect(find.text('TSD · Technical Services Department'), findsOneWidget);
  });
}