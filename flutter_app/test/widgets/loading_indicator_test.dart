import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/config/theme.dart';
import 'package:quickpass/widgets/loading_indicator.dart';

Widget _wrap(Widget w) => MaterialApp(theme: QuickpassTheme.light, home: w);

void main() {
  group('LoadingIndicator', () {
    testWidgets('renders spinner without message', (tester) async {
      await tester.pumpWidget(_wrap(const LoadingIndicator()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders spinner with message', (tester) async {
      await tester.pumpWidget(_wrap(
        const LoadingIndicator(message: 'Loading...'),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
    });
  });
}
