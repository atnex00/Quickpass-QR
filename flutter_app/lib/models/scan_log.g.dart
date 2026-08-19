// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScanLog _$ScanLogFromJson(Map<String, dynamic> json) => ScanLog(
      logId: ScanLog._intFromJson(json['log_id']),
      leaveId: json['leave_id'] as String? ?? '',
      qrType: json['qr_type'] as String? ?? '',
      scannedBy: json['scanned_by'] as String?,
      scanTime: ScanLog._dateFromJson(json['scan_time']),
      ipAddress: json['ip_address'] as String?,
      isValid: ScanLog._boolFromJson(json['is_valid']),
      validationMessage: json['validation_message'] as String?,
      employeeName: json['employee_name'] as String?,
      employeeId: json['employee_id'] as String?,
      departmentName: json['department_name'] as String?,
      departmentCode: json['department_code'] as String?,
      scannedByName: json['scanned_by_name'] as String?,
    );

Map<String, dynamic> _$ScanLogToJson(ScanLog instance) => <String, dynamic>{
      'log_id': instance.logId,
      'leave_id': instance.leaveId,
      'qr_type': instance.qrType,
      'scanned_by': instance.scannedBy,
      'scan_time': ScanLog._dateToJson(instance.scanTime),
      'ip_address': instance.ipAddress,
      'is_valid': instance.isValid,
      'validation_message': instance.validationMessage,
      'employee_name': instance.employeeName,
      'employee_id': instance.employeeId,
      'department_name': instance.departmentName,
      'department_code': instance.departmentCode,
      'scanned_by_name': instance.scannedByName,
    };
