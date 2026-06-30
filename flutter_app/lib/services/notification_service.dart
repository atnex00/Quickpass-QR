import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? _messaging;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;

      await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await _messaging!.getToken();
      if (token != null) {
        try {
          await ApiService().logout();
          await ApiService().login('', ''); // FCM token update
        } catch (_) {}
      }

      FirebaseMessaging.onMessage.listen(_handleMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    } catch (e) {
      print('Notification init failed: $e');
    }
  }

  void _handleMessage(RemoteMessage message) {
    // Will be handled by the app's notification listener
  }

  Future<String?> getToken() async {
    return await _messaging?.getToken();
  }
}
