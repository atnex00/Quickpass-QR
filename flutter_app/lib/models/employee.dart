import 'package:json_annotation/json_annotation.dart';

part 'employee.g.dart';

@JsonSerializable()
class Employee {

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
    this.leaveCount = 0,
  });

  factory Employee.fromJson(Map<String, dynamic> json) =>
      _$EmployeeFromJson(json);
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

  @JsonKey(name: 'leave_count', defaultValue: 0)
  final int leaveCount;

  @JsonKey(
      name: 'hire_date', fromJson: _hireDateFromJson, toJson: _hireDateToJson)
  final DateTime? hireDate;

  static bool _boolFromJson(dynamic v) => v == true || v == 1;
  static bool _boolActiveFromJson(dynamic v) => v == true || v == 1;
  static DateTime? _hireDateFromJson(dynamic v) {
    if (v == null) return null;
    final parts = v.toString().split(RegExp(r'[T ]')).first.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) return DateTime(y, m, d);
    }
    return DateTime.tryParse(v.toString());
  }
  static String? _hireDateToJson(DateTime? v) =>
      v?.toIso8601String().split('T').first;

  Map<String, dynamic> toJson() => _$EmployeeToJson(this);

  static bool isValidId(String id) => RegExp(r'^\d{6}$').hasMatch(id);

  String get formattedId => employeeId.padLeft(6, '0');
}
