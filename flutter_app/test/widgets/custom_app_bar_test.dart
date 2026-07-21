import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/widgets/custom_app_bar.dart';

Widget _wrap(Widget w) => MaterialApp(home: Scaffold(appBar: w as PreferredSizeWidget));

void main() {
  group('QuickpassAppBar', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(_wrap(
        const QuickpassAppBar(title: 'Dashboard'),
      ));
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('shows back button when showBack is true', (tester) async {
      await tester.pumpWidget(_wrap(
        const QuickpassAppBar(title: 'Details', showBack: true),
      ));
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('hides back button by default', (tester) async {
      await tester.pumpWidget(_wrap(
        const QuickpassAppBar(title: 'Details'),
      ));
      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('renders custom leading widget', (tester) async {
      await tester.pumpWidget(_wrap(
        QuickpassAppBar(
          title: 'Details',
          leading: const Icon(Icons.menu),
        ),
      ));
      expect(find.byIcon(Icons.menu), findsOneWidget);
    });

    testWidgets('renders actions', (tester) async {
      await tester.pumpWidget(_wrap(
        QuickpassAppBar(
          title: 'Home',
          actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
        ),
      ));
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('has correct preferred size', (tester) async {
      const appBar = QuickpassAppBar(title: 'Test');
      expect(appBar.preferredSize, const Size.fromHeight(kToolbarHeight));
    });
  });
}
