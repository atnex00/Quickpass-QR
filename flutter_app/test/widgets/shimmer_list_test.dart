import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/widgets/shimmer_list.dart';

Widget _wrap(Widget w) => MaterialApp(home: w);

void main() {
  group('ShimmerList', () {
    testWidgets('renders correct number of items', (tester) async {
      await tester.pumpWidget(_wrap(
        ShimmerList(
          itemCount: 3,
          itemBuilder: (i) => Container(height: 40, child: Text('Item $i')),
        ),
      ));
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('renders scrollable list by default', (tester) async {
      await tester.pumpWidget(_wrap(
        ShimmerList(
          itemCount: 2,
          itemBuilder: (i) => Container(height: 40),
        ),
      ));
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('renders non-scrollable column', (tester) async {
      await tester.pumpWidget(_wrap(
        ShimmerList(
          itemCount: 2,
          scrollable: false,
          itemBuilder: (i) => Container(height: 40),
        ),
      ));
      expect(find.byType(Column), findsOneWidget);
    });
  });
}
