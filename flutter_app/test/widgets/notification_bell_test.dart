import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quickpass/config/theme.dart';
import 'package:quickpass/providers/auth_provider.dart';
import 'package:quickpass/providers/notification_provider.dart';
import 'package:quickpass/widgets/notification_bell.dart';

import '../helpers/mocks.mocks.dart';
import '../helpers/test_setup.dart';

Widget _buildApp({
  required NotificationProvider notifProv,
  required AuthProvider authProv,
}) {
  return MaterialApp(
    theme: QuickpassTheme.light,
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: notifProv),
        ChangeNotifierProvider.value(value: authProv),
      ],
      child: const Scaffold(body: NotificationBell()),
    ),
  );
}

void main() {
  late MockApiService mockApi;
  late AuthProvider authProv;
  late NotificationProvider notifProv;

  setUp(() async {
    await setupTestInfrastructure();
    mockApi = MockApiService();
    authProv = AuthProvider(api: mockApi);
    notifProv = NotificationProvider();
    await notifProv.load();
  });

  group('NotificationBell', () {
    testWidgets('renders bell icon without badge by default',
        (tester) async {
      await tester.pumpWidget(_buildApp(
        notifProv: notifProv,
        authProv: authProv,
      ));
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('shows badge when there are unread notifications',
        (tester) async {
      await notifProv.increment();
      await tester.pumpWidget(_buildApp(
        notifProv: notifProv,
        authProv: authProv,
      ));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('hides badge after reset', (tester) async {
      await notifProv.increment();
      await notifProv.reset();
      await tester.pumpWidget(_buildApp(
        notifProv: notifProv,
        authProv: authProv,
      ));
      await tester.pump();
      expect(find.text('1'), findsNothing);
    });
  });
}
