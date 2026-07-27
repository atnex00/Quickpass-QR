import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/providers/notification_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_setup.dart';

void main() {
  setUp(() async {
    await setupTestInfrastructure();
  });

  group('NotificationProvider', () {
    test('default state is zero unread', () {
      final provider = NotificationProvider();
      expect(provider.unreadCount, 0);
      expect(provider.hasUnread, false);
    });

    test('load() reads from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'unread_count': 5});
      final provider = NotificationProvider();
      await provider.load();
      expect(provider.unreadCount, 5);
      expect(provider.hasUnread, true);
    });

    test('load() defaults to 0 when key missing', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = NotificationProvider();
      await provider.load();
      expect(provider.unreadCount, 0);
      expect(provider.hasUnread, false);
    });

    test('increment() increases count and persists', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = NotificationProvider();
      await provider.load();
      await provider.increment();
      expect(provider.unreadCount, 1);
      expect(provider.hasUnread, true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('unread_count'), 1);
    });

    test('increment() multiple times', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = NotificationProvider();
      await provider.load();
      await provider.increment();
      await provider.increment();
      await provider.increment();
      expect(provider.unreadCount, 3);
    });

    test('reset() clears count and persists', () async {
      SharedPreferences.setMockInitialValues({'unread_count': 10});
      final provider = NotificationProvider();
      await provider.load();
      expect(provider.unreadCount, 10);
      await provider.reset();
      expect(provider.unreadCount, 0);
      expect(provider.hasUnread, false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('unread_count'), 0);
    });

    test('notifies listeners on increment', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = NotificationProvider();
      await provider.load();
      var notified = false;
      provider.addListener(() => notified = true);
      await provider.increment();
      expect(notified, true);
    });

    test('notifies listeners on reset', () async {
      SharedPreferences.setMockInitialValues({'unread_count': 3});
      final provider = NotificationProvider();
      await provider.load();
      var notified = false;
      provider.addListener(() => notified = true);
      await provider.reset();
      expect(notified, true);
    });
  });
}
