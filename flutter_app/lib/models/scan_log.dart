import 'package:json_annotation/json_annotation.dart';

part 'scan_log.g.dart';

@JsonSerializable()
class ScanLog {
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

  static int _intFromJson(dynamic v) => v as int? ?? 0;
  static bool _boolFromJson(dynamic v) => v as bool? ?? true;
  static DateTime _dateFromJson(dynamic v) => DateTime.parse(v as String);
  static String _dateToJson(DateTime v) => v.toIso8601String();

  factory ScanLog.fromJson(Map<String, dynamic> json) =>
      _$ScanLogFromJson(json);

  Map<String, dynamic> toJson() => _$ScanLogToJson(this);
}
