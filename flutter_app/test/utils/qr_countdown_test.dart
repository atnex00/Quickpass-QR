import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/utils/qr_countdown.dart';

class _TestState extends State<_TestWidget> with QrCountdownMixin<_TestWidget> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _TestWidget extends StatefulWidget {
  const _TestWidget();
  @override
  State<_TestWidget> createState() => _TestState();
}

Widget _buildTestApp() {
  return const MaterialApp(home: Scaffold(body: _TestWidget()));
}

void main() {
  group('QrCountdownMixin', () {
    testWidgets('initCountdown starts timer and updates state',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      final state = tester.state<_TestState>(find.byType(_TestWidget));
      expect(state.windowState, 'during');
      expect(state.remainingSeconds, 0);
      state.disposeCountdown();
    });

    testWidgets('formatCountdown formats seconds correctly', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      final state = tester.state<_TestState>(find.byType(_TestWidget));
      expect(state.formatCountdown(0), '00:00');
      expect(state.formatCountdown(65), '01:05');
      expect(state.formatCountdown(3661), '61:01');
      expect(state.formatCountdown(59), '00:59');
      state.disposeCountdown();
    });

    testWidgets('disposeCountdown cancels timer without error',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      final state = tester.state<_TestState>(find.byType(_TestWidget));
      expect(state.disposeCountdown, returnsNormally);
    });

    testWidgets('updateCountdown with same date/time is no-op',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      final state = tester.state<_TestState>(find.byType(_TestWidget));
      state.updateCountdown(
        '2026-07-21',
        '09:00',
        oldDate: '2026-07-21',
        oldTime: '09:00',
      );
      state.disposeCountdown();
    });

    testWidgets('updateCountdown with different date restarts timer',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      final state = tester.state<_TestState>(find.byType(_TestWidget));
      state.updateCountdown(
        '2026-07-22',
        '10:00',
        oldDate: '2026-07-21',
        oldTime: '09:00',
      );
      state.disposeCountdown();
    });
  });
}
