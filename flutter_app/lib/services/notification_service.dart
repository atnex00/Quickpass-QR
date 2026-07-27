import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../screens/employee/dashboard_screen.dart';
import '../screens/employee/leave_history_screen.dart';
import '../screens/supervisor/supervisor_dashboard.dart';
import 'api_service.dart';

class NotificationService {
  factory NotificationService() => _instance;
  NotificationService._();
  static final NotificationService _instance = NotificationService._();

  bool _initialized = false;
  GlobalKey<NavigatorState>? _navigatorKey;
  ApiService? _api;
  String? _pendingScreen;
  void Function()? _onUnreadNotification;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init({
    required GlobalKey<NavigatorState> navigatorKey,
    required ApiService apiService,
    void Function()? onUnreadNotification,
  }) async {
    if (_initialized) return;
    _navigatorKey = navigatorKey;
    _api = apiService;
    _onUnreadNotification = onUnreadNotification;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
  }

String? consumePendingScreen() {
    final screen = _pendingScreen;
    _pendingScreen = null;
    return screen;
  }

  void _onNotificationTap(NotificationResponse response) {
    _navigateByType(response.payload ?? 'leave_history');
  }

  void _navigateByType(String type) {
    final screen = switch (type) {
      'new_request' => const SupervisorDashboard(),
      'approved' || 'rejected' || 'revoked' || 'out_scan' || 'in_scan'
          => const LeaveHistoryScreen(),
      _ => const EmployeeDashboard(),
    };
    _navigatorKey?.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }
}
