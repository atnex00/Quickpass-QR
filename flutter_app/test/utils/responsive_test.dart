import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/utils/responsive.dart';

Widget _frame({required double width, required Widget body}) {
  return MediaQuery(
    data: MediaQueryData(size: Size(width, 800)),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: body,
    ),
  );
}

void main() {
  group('getScreenType', () {
    testWidgets('returns phone for width 599', (tester) async {
      await tester.pumpWidget(_frame(width: 599, body: const SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));
      expect(MediaQuery.of(ctx).size.width, 599);
      expect(getScreenType(ctx), ScreenType.phone);
    });

    testWidgets('returns tablet for width 600', (tester) async {
      await tester.pumpWidget(_frame(width: 600, body: const SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));
      expect(MediaQuery.of(ctx).size.width, 600);
      expect(getScreenType(ctx), ScreenType.tablet);
    });

    testWidgets('returns tablet for width 899', (tester) async {
      await tester.pumpWidget(_frame(width: 899, body: const SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));
      expect(getScreenType(ctx), ScreenType.tablet);
    });

    testWidgets('returns desktop for width 900', (tester) async {
      await tester.pumpWidget(_frame(width: 900, body: const SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));
      expect(getScreenType(ctx), ScreenType.desktop);
    });
  });

  group('responsivePadding', () {
    testWidgets('returns proportional padding', (tester) async {
      await tester.pumpWidget(_frame(width: 375, body: const SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));
      final result = responsivePadding(ctx);
      expect(result.horizontal, result.vertical);
      expect(result.horizontal, greaterThan(0));
    });
  });

  group('responsiveSize', () {
    testWidgets('returns unscaled at design width', (tester) async {
      await tester.pumpWidget(_frame(width: 375, body: const SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));
      expect(responsiveSize(ctx, 100), 100);
    });
  });

  group('scaleWidth', () {
    testWidgets('returns unscaled at design width', (tester) async {
      await tester.pumpWidget(_frame(width: 375, body: const SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));
      expect(scaleWidth(ctx, 100), 100);
    });
  });

  group('adaptiveValue', () {
    testWidgets('returns phone value on phone screen', (tester) async {
      await tester.pumpWidget(_frame(width: 320, body: const SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));
      expect(adaptiveValue(ctx, phone: 'A', tablet: 'B', desktop: 'C'), 'A');
    });

    testWidgets('returns tablet value on tablet screen', (tester) async {
      await tester.pumpWidget(_frame(width: 700, body: const SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));
      expect(adaptiveValue(ctx, phone: 'A', tablet: 'B', desktop: 'C'), 'B');
    });

    testWidgets('returns desktop value on desktop screen', (tester) async {
      await tester.pumpWidget(_frame(width: 1200, body: const SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));
      expect(adaptiveValue(ctx, phone: 'A', tablet: 'B', desktop: 'C'), 'C');
    });
  });

  group('isSmallScreen', () {
    testWidgets('returns true for width < 360', (tester) async {
      await tester.pumpWidget(_frame(width: 300, body: const SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));
      expect(isSmallScreen(ctx), true);
    });

    testWidgets('returns false for width >= 360', (tester) async {
      await tester.pumpWidget(_frame(width: 360, body: const SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));
      expect(isSmallScreen(ctx), false);
    });
  });

  group('isTablet', () {
    testWidgets('returns false for width < 600', (tester) async {
      await tester.pumpWidget(_frame(width: 500, body: const SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));
      expect(isTablet(ctx), false);
    });

    testWidgets('returns true for width >= 600', (tester) async {
      await tester.pumpWidget(_frame(width: 600, body: const SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));
      expect(isTablet(ctx), true);
    });
  });

  group('responsiveHeight', () {
    testWidgets('scales proportionally within clamp bounds', (tester) async {
      await tester.pumpWidget(_frame(width: 375, body: const SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));
      expect(responsiveHeight(ctx, 100), closeTo(100 * (800 / 812), 0.01));
    });
  });

  group('responsiveFontSize', () {
    testWidgets('returns positive value at design width', (tester) async {
      await tester.pumpWidget(_frame(width: 375, body: const SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));
      expect(responsiveFontSize(ctx, 16), greaterThan(0));
    });
  });
}
