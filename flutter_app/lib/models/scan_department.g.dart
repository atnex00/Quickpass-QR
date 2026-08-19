// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_department.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScanDepartment _$ScanDepartmentFromJson(Map<String, dynamic> json) =>
    ScanDepartment(
      departmentName: json['department_name'] as String,
      departmentCode: json['department_code'] as String? ?? '',
      scanCount: (json['scan_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ScanDepartmentToJson(ScanDepartment instance) =>
    <String, dynamic>{
      'department_name': instance.departmentName,
      'department_code': instance.departmentCode,
      'scan_count': instance.scanCount,
    };
