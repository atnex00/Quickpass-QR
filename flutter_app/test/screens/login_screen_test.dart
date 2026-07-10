import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:quickpass/config/theme.dart';
import 'package:quickpass/providers/auth_provider.dart';
import 'package:quickpass/screens/auth/login_screen.dart';

import '../helpers/mocks.mocks.dart';

Widget _buildTestApp(AuthProvider authProvider) {
  return MaterialApp(
    theme: QuickpassTheme.light,
    home: ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: const LoginScreen(),
    ),
  );
}

void main() {
  late MockApiService mockApi;
  late AuthProvider authProvider;

  setUp(() {
    mockApi = MockApiService();
    authProvider = AuthProvider(api: mockApi);
  });

  testWidgets('renders login form with all key elements',
      (WidgetTester tester) async {
    when(mockApi.getStoredToken()).thenAnswer((_) async => null);

    await tester.pumpWidget(_buildTestApp(authProvider));
    await tester.pump();

    expect(find.text('Employee ID'), findsOneWidget);
    expect(find.text('Password'), findsAtLeast(1));
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Quickpass'), findsOneWidget);
    expect(find.text('Forgot?'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Internal Support'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('Secured'), findsOneWidget);
  });

  testWidgets('toggles password visibility', (WidgetTester tester) async {
    when(mockApi.getStoredToken()).thenAnswer((_) async => null);

    await tester.pumpWidget(_buildTestApp(authProvider));
    await tester.pump();

    expect(find.byIcon(Icons.visibility), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off), findsNothing);

    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();

    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
  });

  testWidgets('shows error message when auth has error',
      (WidgetTester tester) async {
    when(mockApi.getStoredToken()).thenAnswer((_) async => null);

    await tester.pumpWidget(_buildTestApp(authProvider));
    await tester.pump();

    // Trigger login to simulate error
    when(mockApi.login('000001', 'wrong'))
        .thenThrow(Exception('Invalid credentials'));
    await tester.enterText(find.byType(TextFormField).first, '000001');
    await tester.enterText(find.byType(TextFormField).last, 'wrong');
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.textContaining('Invalid credentials'), findsOneWidget);
  });
}
