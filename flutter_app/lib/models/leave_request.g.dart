// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leave_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaveRequest _$LeaveRequestFromJson(Map<String, dynamic> json) => LeaveRequest(
      leaveId: json['leave_id'] as String? ?? '',
      employeeId: json['employee_id'] as String? ?? '',
      employeeName: json['employee_name'] as String? ?? '',
      departmentId: json['department_id'] as String? ?? '',
      supervisorId: json['supervisor_id'] as String? ?? '',
      supervisorName: json['supervisor_name'] as String? ?? '',
      leaveDate: LeaveRequest._dateFromJson(json['leave_date']),
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      status: LeaveRequest._statusFromJson(json['status']),
      outQrCode: json['out_qr_code'] as String?,
      inQrCode: json['in_qr_code'] as String?,
      outScanTime: LeaveRequest._dateTimeOrNullFromJson(json['out_scan_time']),
      inScanTime: LeaveRequest._dateTimeOrNullFromJson(json['in_scan_time']),
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: LeaveRequest._dateTimeFromJson(json['created_at']),
      updatedAt: LeaveRequest._dateTimeFromJson(json['updated_at']),
      employeePosition: json['employee_position'] as String?,
      employeePhoto: json['employee_photo'] as String?,
    );

Map<String, dynamic> _$LeaveRequestToJson(LeaveRequest instance) =>
    <String, dynamic>{
      'leave_id': instance.leaveId,
      'employee_id': instance.employeeId,
      'employee_name': instance.employeeName,
      'department_id': instance.departmentId,
      'supervisor_id': instance.supervisorId,
      'supervisor_name': instance.supervisorName,
      'leave_date': LeaveRequest._dateToJson(instance.leaveDate),
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'reason': instance.reason,
      'status': LeaveRequest._statusToJson(instance.status),
      'out_qr_code': instance.outQrCode,
      'in_qr_code': instance.inQrCode,
      'out_scan_time': LeaveRequest._dateTimeOrNullToJson(instance.outScanTime),
      'in_scan_time': LeaveRequest._dateTimeOrNullToJson(instance.inScanTime),
      'rejection_reason': instance.rejectionReason,
      'created_at': LeaveRequest._dateTimeToJson(instance.createdAt),
      'updated_at': LeaveRequest._dateTimeToJson(instance.updatedAt),
      'employee_position': instance.employeePosition,
      'employee_photo': instance.employeePhoto,
    };
