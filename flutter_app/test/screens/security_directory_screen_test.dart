import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:quickpass/config/theme.dart';
import 'package:quickpass/models/employee.dart';
import 'package:quickpass/providers/directory_provider.dart';
import 'package:quickpass/screens/security/security_directory_screen.dart';

import '../helpers/mocks.mocks.dart';
import '../helpers/test_setup.dart';

Employee _member(String id, String name, String deptId, String deptName,
    String code, String position,
    {bool supervisor = false}) {
  return Employee(
    employeeId: id,
    fullName: name,
    position: position,
    departmentId: deptId,
    departmentName: deptName,
    departmentCode: code,
    isSupervisor: supervisor,
    isAdmin: false,
    isSecurity: false,
    isActive: true,
    email: '',
  );
}

void main() {
  late MockApiService mockApi;

  setUp(() async {
    await setupTestInfrastructure();
    mockApi = MockApiService();
    when(mockApi.getDirectory()).thenAnswer((_) async => [
          _member('000001', 'James Wilson', 'DEP-002',
              'TSD · Technical Services Department', 'TSD', 'Software Engineer'),
          _member('000009', 'Daniel Kim', 'DEP-002',
              'TSD · Technical Services Department', 'TSD', 'Junior Developer'),
          _member('000015', 'Liam Thomas', 'DEP-001',
              'ISD · Institutional Services Department', 'ISD', 'ISD Supervisor',
              supervisor: true),
        ]);
  });

  Widget wrap() {
    return ChangeNotifierProvider(
      create: (_) => DirectoryProvider(api: mockApi),
      child: MaterialApp(
        theme: QuickpassTheme.light,
        home: const SecurityDirectoryScreen(),
      ),
    );
  }

  testWidgets('shows department cards with counts, not employee names',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('TSD · Technical Services Department'), findsOneWidget);
    expect(find.text('ISD · Institutional Services Department'), findsOneWidget);
    expect(find.text('TSD'), findsOneWidget);
    expect(find.text('ISD'), findsOneWidget);
    expect(find.text('James Wilson'), findsNothing);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('taps a department card to view members and back to exit',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('TSD · Technical Services Department'));
    await tester.pumpAndSettle();

    expect(find.text('James Wilson'), findsOneWidget);
    expect(find.text('Daniel Kim'), findsOneWidget);
    expect(find.text('Liam Thomas'), findsNothing);
    expect(find.text('Software Engineer'), findsWidgets);
    expect(find.text('Junior Developer'), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('TSD · Technical Services Department'), findsOneWidget);
    expect(find.text('James Wilson'), findsNothing);
  });
}