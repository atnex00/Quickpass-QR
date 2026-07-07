import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Quickpass';
  static const String tagline = 'Smart Gatepass & Leave Management';

  static const String outQrLabel = 'EXIT PASS';
  static const String inQrLabel = 'ENTRY PASS';

  static const String employeeIdHint = '000001';
  static const int employeeIdLength = 6;

  static const Duration qrCountdownInterval = Duration(seconds: 1);
  static const Duration scanTimeout = Duration(seconds: 30);

  static const Map<String, Color> statusColors = {
    'pending': Color(0xFFF59E0B),
    'approved': Color(0xFF1E40AF),
    'rejected': Color(0xFFDC2626),
    'active': Color(0xFF16A34A),
    'completed': Color(0xFF2563EB),
    'cancelled': Color(0xFF94A3B8),
  };

  static const Map<String, String> statusLabels = {
    'pending': 'Pending',
    'approved': 'Approved',
    'rejected': 'Rejected',
    'active': 'Active',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
  };

  static const String supportEmail = 'support@zaneco.com';
  static const String supportPhone = 'Ext. 4200';
  static const String supportHours = '8:00 AM - 6:00 PM';
}
