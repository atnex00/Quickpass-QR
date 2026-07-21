import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/config/theme.dart';
import 'package:quickpass/widgets/offline_indicator.dart';

Widget _wrap(Widget w) => MaterialApp(theme: QuickpassTheme.light, home: w);

void main() {
  group('OfflineIndicator', () {
    testWidgets('renders cached data message', (tester) async {
      await tester.pumpWidget(_wrap(const OfflineIndicator()));
      expect(find.text('Showing cached data'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });
  });
}
