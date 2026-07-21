import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/utils/debounce.dart';

void main() {
  group('Debouncer', () {
    test('fires after delay', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 10));
      var fired = false;
      debouncer(() => fired = true);
      expect(fired, false);
      await Future.delayed(const Duration(milliseconds: 20));
      expect(fired, true);
    });

    test('rapid calls cancel previous and only last fires', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 10));
      var callCount = 0;
      debouncer(() => callCount++);
      debouncer(() => callCount++);
      debouncer(() => callCount++);
      await Future.delayed(const Duration(milliseconds: 20));
      expect(callCount, 1);
    });

    test('cancel prevents pending call from firing', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 10));
      var fired = false;
      debouncer(() => fired = true);
      debouncer.cancel();
      await Future.delayed(const Duration(milliseconds: 20));
      expect(fired, false);
    });

    test('cancel on idle debouncer does not throw', () {
      final debouncer = Debouncer();
      expect(debouncer.cancel, returnsNormally);
    });

    test('zero delay fires on next microtask', () async {
      final debouncer = Debouncer(delay: Duration.zero);
      var fired = false;
      debouncer(() => fired = true);
      expect(fired, false);
      await Future.delayed(Duration.zero);
      expect(fired, true);
    });

    test('default delay is 300ms', () {
      final debouncer = Debouncer();
      expect(debouncer.delay, const Duration(milliseconds: 300));
    });
  });
}
