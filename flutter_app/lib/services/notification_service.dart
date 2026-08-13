import 'package:firebase_messaging/firebase_messaging.dart';
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
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    final token = await messaging.getToken();
    if (token != null) await _sendToken(token);

    messaging.onTokenRefresh.listen(_sendToken);

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessage);

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _pendingScreen = initialMessage.data['type'] ?? 'leave_history';
    }

    _initialized = true;
  }

  Future<void> _sendToken(String token) async {
    try {
      await _api?.updateFcmToken(token);
    } catch (_) {}
  }

  void _onForegroundMessage(RemoteMessage message) {
    _onUnreadNotification?.call();
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';
    if (title.isEmpty && body.isEmpty) return;
    final id = message.data['leave_id']?.hashCode ??
        DateTime.now().millisecondsSinceEpoch.remainder(100000);
    _localNotifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'leave_notifications',
          'Leave Notifications',
          channelDescription: 'Leave request notifications',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['type'] ?? 'leave_history',
    );
  }

  String? consumePendingScreen() {
    final screen = _pendingScreen;
    _pendingScreen = null;
    return screen;
  }

  void _onNotificationTap(NotificationResponse response) {
    _navigateByType(response.payload ?? 'leave_history');
  }

  void _handleRemoteMessage(RemoteMessage message) {
    _navigateByType(message.data['type'] ?? 'leave_history');
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
