// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Employee _$EmployeeFromJson(Map<String, dynamic> json) => Employee(
      employeeId: json['employee_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      position: json['position'] as String? ?? '',
      departmentId: json['department_id'] as String? ?? '',
      departmentName: json['department_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      isSupervisor: Employee._boolFromJson(json['is_supervisor']),
      isAdmin: Employee._boolFromJson(json['is_admin']),
      isSecurity: Employee._boolFromJson(json['is_security']),
      isActive: Employee._boolActiveFromJson(json['is_active']),
      profilePhoto: json['profile_photo'] as String?,
      hireDate: Employee._hireDateFromJson(json['hire_date']),
      leaveCount: json['leave_count'] == null
          ? 0
          : Employee._leaveCountFromJson(json['leave_count']),
    );

Map<String, dynamic> _$EmployeeToJson(Employee instance) => <String, dynamic>{
      'employee_id': instance.employeeId,
      'full_name': instance.fullName,
      'position': instance.position,
      'department_id': instance.departmentId,
      'department_name': instance.departmentName,
      'email': instance.email,
      'is_supervisor': instance.isSupervisor,
      'is_admin': instance.isAdmin,
      'is_security': instance.isSecurity,
      'is_active': instance.isActive,
      'profile_photo': instance.profilePhoto,
      'leave_count': instance.leaveCount,
      'hire_date': Employee._hireDateToJson(instance.hireDate),
    };
