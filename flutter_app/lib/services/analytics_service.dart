import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  factory AnalyticsService() => _instance;
  AnalyticsService._();
  static final AnalyticsService _instance = AnalyticsService._();
  static bool _enabled = true;

  late final analytics = FirebaseAnalytics.instance;

  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  Future<void> logLogin({required String role}) async {
    if (!_enabled) return;
    await analytics.logEvent(
      name: 'login',
      parameters: {'role': role},
    );
  }

  Future<void> logLogout() async {
    if (!_enabled) return;
    await analytics.logEvent(name: 'logout');
  }

  Future<void> logLeaveSubmitted() async {
    if (!_enabled) return;
    await analytics.logEvent(name: 'leave_submitted');
  }

  Future<void> logLeaveApproved() async {
    if (!_enabled) return;
    await analytics.logEvent(name: 'leave_approved');
  }

  Future<void> logLeaveRejected() async {
    if (!_enabled) return;
    await analytics.logEvent(name: 'leave_rejected');
  }

  Future<void> logLeaveRevoked() async {
    if (!_enabled) return;
    await analytics.logEvent(name: 'leave_revoked');
  }

  Future<void> logQrScan({required String qrType, required bool isValid}) async {
    if (!_enabled) return;
    await analytics.logEvent(
      name: 'qr_scan',
      parameters: {'qr_type': qrType, 'is_valid': isValid.toString()},
    );
  }
}
