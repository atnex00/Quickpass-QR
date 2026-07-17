import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quickpass/main.dart';
import 'package:quickpass/providers/auth_provider.dart';
import 'package:quickpass/providers/notification_provider.dart';
import 'package:quickpass/providers/settings_provider.dart';

import 'helpers/mocks.mocks.dart';

void main() {
  testWidgets('App renders MaterialApp', (WidgetTester tester) async {
    final apiService = MockApiService();
    final settings = SettingsProvider();
    final auth = AuthProvider(api: apiService);
    final notifProv = NotificationProvider();
    await tester.pumpWidget(QuickpassApp(
      apiService: apiService,
      settings: settings,
      auth: auth,
      notifProv: notifProv,
    ));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
