import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import '../config/theme.dart';

part 'leave_request.g.dart';

enum LeaveStatus {
  pending,
  approved,
  rejected,
  active,
  completed,
  cancelled,
  unknown;

  String get label {
    switch (this) {
      case LeaveStatus.pending:
        return 'Pending';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
      case LeaveStatus.active:
        return 'Active';
      case LeaveStatus.completed:
        return 'Completed';
      case LeaveStatus.cancelled:
        return 'Cancelled';
      case LeaveStatus.unknown:
        return 'Unknown';
    }
  }

  Color get color {
    switch (this) {
      case LeaveStatus.pending:
        return QuickpassColors.warning;
      case LeaveStatus.approved:
        return QuickpassColors.primary;
      case LeaveStatus.rejected:
        return QuickpassColors.error;
      case LeaveStatus.active:
        return QuickpassColors.success;
      case LeaveStatus.completed:
        return QuickpassColors.secondary;
      case LeaveStatus.cancelled:
        return Colors.grey;
      case LeaveStatus.unknown:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case LeaveStatus.pending:
        return Icons.hourglass_empty;
      case LeaveStatus.approved:
        return Icons.check_circle;
      case LeaveStatus.rejected:
        return Icons.cancel;
      case LeaveStatus.active:
        return Icons.timer;
      case LeaveStatus.completed:
        return Icons.check_circle_outline;
      case LeaveStatus.cancelled:
        return Icons.close;
      case LeaveStatus.unknown:
        return Icons.help_outline;
    }
  }

  static LeaveStatus fromString(String s) {
    return LeaveStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => LeaveStatus.unknown,
    );
  }
}

@JsonSerializable()
class LeaveRequest {

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
    this.outQrImage,
    this.inQrImage,
    this.outScanTime,
    this.inScanTime,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    this.employeePosition,
    this.employeePhoto,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) =>
      _$LeaveRequestFromJson(json);
  @JsonKey(name: 'leave_id', defaultValue: '')
  final String leaveId;

  @JsonKey(name: 'employee_id', defaultValue: '')
  final String employeeId;

  @JsonKey(name: 'employee_name', defaultValue: '')
  final String employeeName;

  @JsonKey(name: 'department_id', defaultValue: '')
  final String departmentId;

  @JsonKey(name: 'supervisor_id', defaultValue: '')
  final String supervisorId;

  @JsonKey(name: 'supervisor_name', defaultValue: '')
  final String supervisorName;

  @JsonKey(name: 'leave_date', fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime leaveDate;

  @JsonKey(name: 'start_time', defaultValue: '')
  final String startTime;

  @JsonKey(name: 'end_time', defaultValue: '')
  final String endTime;

  @JsonKey(defaultValue: '')
  final String reason;

  @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
  final LeaveStatus status;

  @JsonKey(name: 'out_qr_code')
  final String? outQrCode;

  @JsonKey(name: 'in_qr_code')
  final String? inQrCode;

  @JsonKey(name: 'out_qr_image')
  final String? outQrImage;

  @JsonKey(name: 'in_qr_image')
  final String? inQrImage;

  @JsonKey(
      name: 'out_scan_time',
      fromJson: _dateTimeOrNullFromJson,
      toJson: _dateTimeOrNullToJson)
  final DateTime? outScanTime;

  @JsonKey(
      name: 'in_scan_time',
      fromJson: _dateTimeOrNullFromJson,
      toJson: _dateTimeOrNullToJson)
  final DateTime? inScanTime;

  @JsonKey(name: 'rejection_reason')
  final String? rejectionReason;

  @JsonKey(
      name: 'created_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;

  @JsonKey(
      name: 'updated_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime updatedAt;

  @JsonKey(name: 'employee_position')
  final String? employeePosition;

  @JsonKey(name: 'employee_photo')
  final String? employeePhoto;

  static DateTime _dateFromJson(dynamic v) {
    return DateTime.tryParse(v?.toString() ?? '') ?? DateTime(0);
  }

  static String _dateToJson(DateTime v) => v.toIso8601String().split('T').first;

  static DateTime? _dateTimeOrNullFromJson(dynamic v) =>
      v != null ? DateTime.tryParse(v.toString()) : null;

  static String? _dateTimeOrNullToJson(DateTime? v) => v?.toIso8601String();

  static DateTime _dateTimeFromJson(dynamic v) {
    return DateTime.tryParse(v?.toString() ?? '') ?? DateTime(0);
  }

  static String _dateTimeToJson(DateTime v) => v.toIso8601String();

  static LeaveStatus _statusFromJson(dynamic v) =>
      LeaveStatus.fromString(v?.toString() ?? 'pending');

  static String _statusToJson(LeaveStatus v) => v.name;

  Map<String, dynamic> toJson() => _$LeaveRequestToJson(this);

  bool get hasQrCodes => outQrCode != null && inQrCode != null;

  int get durationMinutes {
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    if (startParts.length < 2 || endParts.length < 2) return 0;
    final startH = int.tryParse(startParts[0]) ?? 0;
    final startM = int.tryParse(startParts[1]) ?? 0;
    final endH = int.tryParse(endParts[0]) ?? 0;
    final endM = int.tryParse(endParts[1]) ?? 0;
    final startMin = startH * 60 + startM;
    var endMin = endH * 60 + endM;
    if (endMin < startMin) endMin += 1440;
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
