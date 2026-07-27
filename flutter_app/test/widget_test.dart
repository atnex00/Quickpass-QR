import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quickpass/config/theme.dart';

import 'helpers/test_setup.dart';

void main() {
  testWidgets('App renders MaterialApp', (WidgetTester tester) async {
    await setupTestInfrastructure();
    await tester.pumpWidget(MaterialApp(
      theme: QuickpassTheme.light,
      home: const Scaffold(body: Center(child: Text('Quickpass'))),
    ));
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Quickpass'), findsOneWidget);
  });
}
