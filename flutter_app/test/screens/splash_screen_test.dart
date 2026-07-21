import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quickpass/config/theme.dart';
import 'package:quickpass/providers/auth_provider.dart';
import 'package:quickpass/screens/auth/splash_screen.dart';

import '../helpers/mocks.mocks.dart';
import '../helpers/test_setup.dart';

void main() {
  setUp(() async {
    await setupTestInfrastructure();
  });

  group('SplashScreen', () {
    testWidgets('renders app name and spinner', (tester) async {
      final mockApi = MockApiService();
      final auth = AuthProvider(api: mockApi);
      await tester.pumpWidget(
        MaterialApp(
          theme: QuickpassTheme.light,
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: const SplashScreen(),
          ),
        ),
      );
      expect(find.text('Quickpass'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
