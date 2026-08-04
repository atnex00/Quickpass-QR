import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/config/theme.dart';
import 'package:quickpass/widgets/custom_widgets.dart';

Widget _wrap(Widget w) => MaterialApp(theme: QuickpassTheme.light, home: w);

void main() {
  group('InfoRow', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(_wrap(
        const InfoRow(label: 'Name', value: 'Alice'),
      ));
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('renders trailing widget instead of value', (tester) async {
      await tester.pumpWidget(_wrap(
        const InfoRow(
          label: 'Role',
          value: 'Engineer',
          trailing: Icon(Icons.star),
        ),
      ));
      expect(find.text('Engineer'), findsNothing);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });

  group('GuidelineItem', () {
    testWidgets('renders text with bullet', (tester) async {
      await tester.pumpWidget(_wrap(
        const GuidelineItem(text: 'Do not share your password'),
      ));
      expect(find.text('Do not share your password'), findsOneWidget);
    });
  });

  group('EmptyState', () {
    testWidgets('renders icon and title', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmptyState(icon: Icons.inbox, title: 'No data'),
      ));
      expect(find.text('No data'), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('renders subtitle', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmptyState(
          icon: Icons.inbox,
          title: 'No data',
          subtitle: 'Check back later',
        ),
      ));
      expect(find.text('Check back later'), findsOneWidget);
    });

    testWidgets('shows offline message when isOffline', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmptyState(
          icon: Icons.inbox,
          title: 'No data',
          isOffline: true,
        ),
      ));
      expect(find.text('Check your internet connection'), findsOneWidget);
    });

    testWidgets('error overrides title and shows retry', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmptyState(
          icon: Icons.inbox,
          title: 'No data',
          error: 'Server error',
        ),
      ));
      expect(find.text('Server error'), findsOneWidget);
      expect(find.text('Pull down to retry'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('renders action widget', (tester) async {
      await tester.pumpWidget(_wrap(
        EmptyState(
          icon: Icons.inbox,
          title: 'No data',
          action: ElevatedButton(onPressed: () {}, child: const Text('Retry')),
        ),
      ));
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
