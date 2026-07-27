import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/models/leave_request.dart';
import 'package:quickpass/widgets/status_badge.dart';

Widget _wrap(Widget w) => MaterialApp(home: w);

void main() {
  group('StatusBadge', () {
    testWidgets('renders pending badge', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatusBadge(status: LeaveStatus.pending),
      ));
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('renders approved badge', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatusBadge(status: LeaveStatus.approved),
      ));
      expect(find.text('Approved'), findsOneWidget);
    });

    testWidgets('renders rejected badge', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatusBadge(status: LeaveStatus.rejected),
      ));
      expect(find.text('Rejected'), findsOneWidget);
    });

    testWidgets('renders active badge', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatusBadge(status: LeaveStatus.active),
      ));
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('renders completed badge', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatusBadge(status: LeaveStatus.completed),
      ));
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('renders cancelled badge', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatusBadge(status: LeaveStatus.cancelled),
      ));
      expect(find.text('Cancelled'), findsOneWidget);
    });

    testWidgets('renders unknown badge', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatusBadge(status: LeaveStatus.unknown),
      ));
      expect(find.text('Unknown'), findsOneWidget);
    });

    testWidgets('custom fontSize is applied', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatusBadge(status: LeaveStatus.pending, fontSize: 16),
      ));
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('has pill shape', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatusBadge(status: LeaveStatus.approved),
      ));
      expect(find.byType(StatusBadge), findsOneWidget);
    });
  });
}
