import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quickpass/config/theme.dart';
import 'package:quickpass/providers/auth_provider.dart';
import 'package:quickpass/providers/settings_provider.dart';
import 'package:quickpass/screens/shared/settings_screen.dart';

import '../helpers/mocks.mocks.dart';
import '../helpers/test_setup.dart';

void main() {
  setUp(() async {
    await setupTestInfrastructure();
  });

  group('SettingsScreen', () {
    testWidgets('renders profile section', (tester) async {
      final mockApi = MockApiService();
      final auth = AuthProvider(api: mockApi);
      final settings = SettingsProvider();
      await tester.pumpWidget(
        MaterialApp(
          theme: QuickpassTheme.light,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: auth),
              ChangeNotifierProvider<SettingsProvider>.value(value: settings),
            ],
            child: const SettingsScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Profile'), findsOneWidget);
    });
  });
}
