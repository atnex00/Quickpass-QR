import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quickpass/main.dart';
import 'package:quickpass/providers/auth_provider.dart';
import 'package:quickpass/providers/settings_provider.dart';
import 'package:quickpass/services/api_service.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    final apiService = ApiService();
    final settings = SettingsProvider();
    final auth = AuthProvider(api: apiService);
    await tester.pumpWidget(QuickpassApp(
      apiService: apiService,
      settings: settings,
      auth: auth,
    ));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
