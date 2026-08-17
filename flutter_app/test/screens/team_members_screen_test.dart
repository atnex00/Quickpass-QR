import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:quickpass/config/theme.dart';
import 'package:quickpass/models/employee.dart';
import 'package:quickpass/providers/directory_provider.dart';
import 'package:quickpass/screens/supervisor/team_members_screen.dart';

import '../helpers/mocks.mocks.dart';
import '../helpers/test_setup.dart';

Employee _mockMember(String id, String name, String department,
    {int leaveCount = 0, bool supervisor = false}) {
  return Employee(
    employeeId: id,
    fullName: name,
    position: supervisor ? 'Manager' : 'Engineer',
    departmentId: 'DEP-$department',
    departmentName: department,
    isSupervisor: supervisor,
    isAdmin: false,
    isSecurity: false,
    isActive: true,
    email: '',
    profilePhoto: null,
    leaveCount: leaveCount,
  );
}

Widget _wrap(MockApiService api) {
  return ChangeNotifierProvider(
    create: (_) => DirectoryProvider(api: api),
    child: MaterialApp(
      theme: QuickpassTheme.light,
      home: TeamMembersScreen(),
    ),
  );
}

void main() {
  late MockApiService mockApi;

  setUp(() async {
    await setupTestInfrastructure();
    mockApi = MockApiService();
    when(mockApi.getMyTeam()).thenAnswer((_) async => [
          _mockMember('000001', 'James Wilson', 'TSD', leaveCount: 4),
          _mockMember('000002', 'Jane Doe', 'TSD', leaveCount: 0),
        ]);
  });

  testWidgets('renders team members with leave counts', (tester) async {
    await tester.pumpWidget(_wrap(mockApi));
    await tester.pumpAndSettle();

    expect(find.text('James Wilson'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('4 leaves'), findsOneWidget);
    expect(find.text('0 leaves'), findsOneWidget);
    expect(find.text('Engineer'), findsNWidgets(2));
    expect(find.text('TSD'), findsOneWidget);
  });

  testWidgets('filters by search query', (tester) async {
    await tester.pumpWidget(_wrap(mockApi));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'jane');
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('James Wilson'), findsNothing);
  });
}