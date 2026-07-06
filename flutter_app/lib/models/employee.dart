import 'package:json_annotation/json_annotation.dart';

part 'employee.g.dart';

@JsonSerializable()
class Employee {
  @JsonKey(name: 'employee_id', defaultValue: '')
  final String employeeId;

  @JsonKey(name: 'full_name', defaultValue: '')
  final String fullName;

  @JsonKey(defaultValue: '')
  final String position;

  @JsonKey(name: 'department_id', defaultValue: '')
  final String departmentId;

  @JsonKey(name: 'department_name', defaultValue: '')
  final String departmentName;

  @JsonKey(defaultValue: '')
  final String email;

  @JsonKey(name: 'is_supervisor', fromJson: _boolFromJson)
  final bool isSupervisor;

  @JsonKey(name: 'is_admin', fromJson: _boolFromJson)
  final bool isAdmin;

  @JsonKey(name: 'is_security', fromJson: _boolFromJson)
  final bool isSecurity;

  @JsonKey(name: 'is_active', fromJson: _boolActiveFromJson)
  final bool isActive;

  @JsonKey(name: 'profile_photo')
  final String? profilePhoto;

  @JsonKey(name: 'hire_date', fromJson: _hireDateFromJson, toJson: _hireDateToJson)
  final DateTime? hireDate;

  Employee({
    required this.employeeId,
    required this.fullName,
    required this.position,
    required this.departmentId,
    required this.departmentName,
    required this.email,
    required this.isSupervisor,
    required this.isAdmin,
    required this.isSecurity,
    required this.isActive,
    this.profilePhoto,
    this.hireDate,
  });

  static bool _boolFromJson(dynamic v) => v == true || v == 1;
  static bool _boolActiveFromJson(dynamic v) => v != false && v != 0;
  static DateTime? _hireDateFromJson(dynamic v) =>
      v != null ? DateTime.tryParse(v.toString()) : null;
  static String? _hireDateToJson(DateTime? v) =>
      v?.toIso8601String().split('T').first;

  factory Employee.fromJson(Map<String, dynamic> json) =>
      _$EmployeeFromJson(json);

  Map<String, dynamic> toJson() => _$EmployeeToJson(this);

  static bool isValidId(String id) => RegExp(r'^\d{6}$').hasMatch(id);

  String get formattedId => employeeId.padLeft(6, '0');
}
