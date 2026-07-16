import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  factory AnalyticsService() => _instance;
  AnalyticsService._();
  static final AnalyticsService _instance = AnalyticsService._();

  final analytics = FirebaseAnalytics.instance;

  Future<void> logLogin({required String role}) async {
    await analytics.logEvent(
      name: 'login',
      parameters: {'role': role},
    );
  }

  Future<void> logLogout() async {
    await analytics.logEvent(name: 'logout');
  }

  Future<void> logLeaveSubmitted() async {
    await analytics.logEvent(name: 'leave_submitted');
  }

  Future<void> logLeaveApproved() async {
    await analytics.logEvent(name: 'leave_approved');
  }

  Future<void> logLeaveRejected() async {
    await analytics.logEvent(name: 'leave_rejected');
  }

  Future<void> logLeaveRevoked() async {
    await analytics.logEvent(name: 'leave_revoked');
  }

  Future<void> logQrScan({required String qrType, required bool isValid}) async {
    await analytics.logEvent(
      name: 'qr_scan',
      parameters: {'qr_type': qrType, 'is_valid': isValid.toString()},
    );
  }
}
