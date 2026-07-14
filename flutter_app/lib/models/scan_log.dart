import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'scan_log.g.dart';

@JsonSerializable()
class ScanLog {

  ScanLog({
    required this.logId,
    required this.leaveId,
    required this.qrType,
    this.scannedBy,
    required this.scanTime,
    this.ipAddress,
    required this.isValid,
    this.validationMessage,
    this.employeeName,
    this.employeeId,
  });

  factory ScanLog.fromJson(Map<String, dynamic> json) =>
      _$ScanLogFromJson(json);
  @JsonKey(name: 'log_id', fromJson: _intFromJson)
  final int logId;

  @JsonKey(name: 'leave_id', defaultValue: '')
  final String leaveId;

  @JsonKey(name: 'qr_type', defaultValue: '')
  final String qrType;

  @JsonKey(name: 'scanned_by')
  final String? scannedBy;

  @JsonKey(name: 'scan_time', fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime scanTime;

  @JsonKey(name: 'ip_address')
  final String? ipAddress;

  @JsonKey(name: 'is_valid', fromJson: _boolFromJson)
  final bool isValid;

  @JsonKey(name: 'validation_message')
  final String? validationMessage;

  @JsonKey(name: 'employee_name')
  final String? employeeName;

  @JsonKey(name: 'employee_id')
  final String? employeeId;

  static int _intFromJson(dynamic v) => int.tryParse('$v') ?? 0;
  static bool _boolFromJson(dynamic v) => v == true || v == 1;
  static DateTime _dateFromJson(dynamic v) {
    final result = DateTime.tryParse(v?.toString() ?? '');
    if (result == null) {
      debugPrint(
          'Warning: Failed to parse scan_time from "$v", using current time');
      return DateTime.now();
    }
    return result;
  }

  static String _dateToJson(DateTime v) => v.toIso8601String();

  Map<String, dynamic> toJson() => _$ScanLogToJson(this);
}
