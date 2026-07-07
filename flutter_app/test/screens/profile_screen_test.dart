import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:quickpass/config/theme.dart';
import 'package:quickpass/models/employee.dart';
import 'package:quickpass/providers/auth_provider.dart';
import 'package:quickpass/screens/employee/profile_screen.dart';

import '../helpers/mocks.mocks.dart';

Widget _buildTestApp(AuthProvider authProvider) {
  return MaterialApp(
    theme: QuickpassTheme.light,
    home: ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: const ProfileScreen(),
    ),
  );
}

void main() {
  late MockApiService mockApi;
  late AuthProvider authProvider;
  late Employee testUser;

  setUp(() {
    mockApi = MockApiService();
    authProvider = AuthProvider(api: mockApi);
    testUser = Employee(
      employeeId: '000001',
      fullName: 'Alice Chen',
      position: 'Software Engineer',
      departmentId: '1',
      departmentName: 'Engineering',
      email: 'alice@example.com',
      isSupervisor: false,
      isAdmin: false,
      isSecurity: false,
      isActive: true,
    );
    when(mockApi.getStoredToken()).thenAnswer((_) async => 'test-token');
  });

  testWidgets('renders profile with user information', (WidgetTester tester) async {
    authProvider.setUserForTest(testUser);

    await tester.pumpWidget(_buildTestApp(authProvider));
    await tester.pump();

    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('Alice Chen'), findsAtLeast(1));
    expect(find.text('000001'), findsOneWidget);
    expect(find.text('Engineering'), findsOneWidget);
    expect(find.text('Software Engineer'), findsAtLeast(1));
    expect(find.text('Account Information'), findsOneWidget);
    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('shows logout confirmation dialog on logout tap', (WidgetTester tester) async {
    authProvider.setUserForTest(testUser);

    await tester.pumpWidget(_buildTestApp(authProvider));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pump();

    expect(find.text('Logout'), findsAtLeast(2));
    expect(find.text('Are you sure you want to logout?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('cancel dismisses logout dialog without logging out', (WidgetTester tester) async {
    authProvider.setUserForTest(testUser);

    await tester.pumpWidget(_buildTestApp(authProvider));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pump();

    await tester.tap(find.text('Cancel'));
    await tester.pump();

    expect(find.text('Are you sure you want to logout?'), findsNothing);
  });
}
