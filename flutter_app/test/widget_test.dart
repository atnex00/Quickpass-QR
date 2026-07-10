import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quickpass/main.dart';
import 'package:quickpass/providers/settings_provider.dart';
import 'package:quickpass/services/api_service.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    final apiService = ApiService();
    final settings = SettingsProvider();
    await tester.pumpWidget(QuickpassApp(apiService: apiService, settings: settings));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
