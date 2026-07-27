// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'department.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Department _$DepartmentFromJson(Map<String, dynamic> json) => Department(
      departmentId: Department._stringFromJson(json['department_id']),
      departmentName: Department._stringFromJson(json['department_name']),
      departmentCode: json['department_code'] as String?,
      headOfDepartment: json['head_of_department'] as String?,
      isActive: Department._boolFromJson(json['is_active']),
    );

Map<String, dynamic> _$DepartmentToJson(Department instance) =>
    <String, dynamic>{
      'department_id': instance.departmentId,
      'department_name': instance.departmentName,
      'department_code': instance.departmentCode,
      'head_of_department': instance.headOfDepartment,
      'is_active': instance.isActive,
    };
