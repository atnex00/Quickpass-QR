import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider extends ChangeNotifier {
  int _unreadCount = 0;

  int get unreadCount => _unreadCount;
  bool get hasUnread => _unreadCount > 0;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _unreadCount = prefs.getInt('unread_count') ?? 0;
    notifyListeners();
  }

  Future<void> increment() async {
    _unreadCount++;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('unread_count', _unreadCount);
  }

  Future<void> reset() async {
    _unreadCount = 0;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('unread_count', 0);
  }
}
