import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/config/theme.dart';
import 'package:quickpass/widgets/expandable_reason.dart';

const _longReason =
    'This is a very long leave reason that keeps going on and on so that it '
    'will definitely exceed the available width of the card on a phone-sized '
    'screen and trigger the expandable Read more toggle to show the full '
    'message to the supervisor who needs to review it before deciding.';

Widget _buildApp({required String text, int collapsedLines = 2}) {
  return MaterialApp(
    theme: QuickpassTheme.light,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 300,
          child: ExpandableReason(text: text, collapsedLines: collapsedLines),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('short text renders without toggle', (tester) async {
    await tester.pumpWidget(_buildApp(text: 'Medical appointment'));

    expect(find.text('Medical appointment'), findsOneWidget);
    expect(find.text('Read more'), findsNothing);
  });

  testWidgets('long text shows Read more and expands to full', (tester) async {
    await tester.pumpWidget(_buildApp(text: _longReason));

    expect(find.text('Read more'), findsOneWidget);
    expect(find.text('Show less'), findsNothing);

    final collapsed = tester.widget<Text>(find.textContaining('This is a very'));
    expect(collapsed.maxLines, 2);

    await tester.tap(find.text('Read more'));
    await tester.pumpAndSettle();

    expect(find.text('Show less'), findsOneWidget);
    final expanded = tester.widget<Text>(find.textContaining('This is a very'));
    expect(expanded.maxLines, isNull);

    await tester.tap(find.text('Show less'));
    await tester.pumpAndSettle();

    expect(find.text('Read more'), findsOneWidget);
    final recollapsed = tester.widget<Text>(find.textContaining('This is a very'));
    expect(recollapsed.maxLines, 2);
  });
}