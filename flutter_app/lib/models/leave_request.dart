import 'package:flutter/material.dart';
import '../config/theme.dart';

enum LeaveStatus {
  pending,
  approved,
  rejected,
  active,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case LeaveStatus.pending: return 'Pending';
      case LeaveStatus.approved: return 'Approved';
      case LeaveStatus.rejected: return 'Rejected';
      case LeaveStatus.active: return 'Active';
      case LeaveStatus.completed: return 'Completed';
      case LeaveStatus.cancelled: return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case LeaveStatus.pending: return QuickpassColors.warning;
      case LeaveStatus.approved: return QuickpassColors.primary;
      case LeaveStatus.rejected: return QuickpassColors.error;
      case LeaveStatus.active: return QuickpassColors.success;
      case LeaveStatus.completed: return QuickpassColors.secondary;
      case LeaveStatus.cancelled: return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case LeaveStatus.pending: return Icons.hourglass_empty;
      case LeaveStatus.approved: return Icons.check_circle;
      case LeaveStatus.rejected: return Icons.cancel;
      case LeaveStatus.active: return Icons.timer;
      case LeaveStatus.completed: return Icons.check_circle_outline;
      case LeaveStatus.cancelled: return Icons.close;
    }
  }

  static LeaveStatus fromString(String s) {
    return LeaveStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => LeaveStatus.pending,
    );
  }
}

class LeaveRequest {
  final String leaveId;
  final String employeeId;
  final String employeeName;
  final String departmentId;
  final String supervisorId;
  final String supervisorName;
  final DateTime leaveDate;
  final String startTime;
  final String endTime;
  final String reason;
  final LeaveStatus status;
  final String? outQrCode;
  final String? inQrCode;
  final DateTime? outScanTime;
  final DateTime? inScanTime;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? employeePosition;
  final String? employeePhoto;

  LeaveRequest({
    required this.leaveId,
    required this.employeeId,
    required this.employeeName,
    required this.departmentId,
    required this.supervisorId,
    required this.supervisorName,
    required this.leaveDate,
    required this.startTime,
    required this.endTime,
    required this.reason,
    required this.status,
    this.outQrCode,
    this.inQrCode,
    this.outScanTime,
    this.inScanTime,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    this.employeePosition,
    this.employeePhoto,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      leaveId: json['leave_id'] ?? '',
      employeeId: json['employee_id'] ?? '',
      employeeName: json['employee_name'] ?? '',
      departmentId: json['department_id'] ?? '',
      supervisorId: json['supervisor_id'] ?? '',
      supervisorName: json['supervisor_name'] ?? '',
      leaveDate: DateTime.parse(json['leave_date']),
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      reason: json['reason'] ?? '',
      status: LeaveStatus.fromString(json['status'] ?? 'pending'),
      outQrCode: json['out_qr_code'],
      inQrCode: json['in_qr_code'],
      outScanTime: json['out_scan_time'] != null ? DateTime.tryParse(json['out_scan_time']) : null,
      inScanTime: json['in_scan_time'] != null ? DateTime.tryParse(json['in_scan_time']) : null,
      rejectionReason: json['rejection_reason'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      employeePosition: json['employee_position'],
      employeePhoto: json['employee_photo'],
    );
  }

  bool get hasQrCodes => outQrCode != null && inQrCode != null;

  int get durationMinutes {
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    if (startParts.length < 2 || endParts.length < 2) return 0;
    final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    return endMin - startMin;
  }

  String get durationText {
    final mins = durationMinutes;
    if (mins <= 0) return '0m';
    final h = mins ~/ 60;
    final m = mins % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }
}
