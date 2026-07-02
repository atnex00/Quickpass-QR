import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quickpass/main.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const QuickpassApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
