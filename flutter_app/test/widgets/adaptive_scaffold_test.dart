import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/widgets/adaptive_scaffold.dart';

const _dests = [
  AdaptiveDestination(icon: Icons.home, selectedIcon: Icons.home, label: 'Home'),
  AdaptiveDestination(icon: Icons.search, selectedIcon: Icons.search, label: 'Search'),
];

Widget _buildApp({required double width, required Widget body}) {
  return MediaQuery(
    data: MediaQueryData(size: Size(width, 800)),
    child: MaterialApp(
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: body,
      ),
    ),
  );
}

void main() {
  group('AdaptiveScaffold', () {
    testWidgets('renders NavigationBar on phone width', (tester) async {
      await tester.pumpWidget(_buildApp(
        width: 375,
        body: AdaptiveScaffold(
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          destinations: _dests,
          body: const Text('content'),
        ),
      ));
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('content'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('renders NavigationRail on tablet width', (tester) async {
      await tester.pumpWidget(_buildApp(
        width: 800,
        body: AdaptiveScaffold(
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          destinations: _dests,
          body: const Text('content'),
        ),
      ));
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('highlights selected index', (tester) async {
      await tester.pumpWidget(_buildApp(
        width: 375,
        body: AdaptiveScaffold(
          selectedIndex: 1,
          onDestinationSelected: (_) {},
          destinations: _dests,
          body: const Text('content'),
        ),
      ));
      expect(find.text('Search'), findsOneWidget);
    });
  });
}
