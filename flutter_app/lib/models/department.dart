import 'package:json_annotation/json_annotation.dart';

part 'department.g.dart';

@JsonSerializable()
class Department {
  @JsonKey(name: 'department_id', fromJson: _stringFromJson)
  final String departmentId;

  @JsonKey(name: 'department_name', fromJson: _stringFromJson)
  final String departmentName;

  @JsonKey(name: 'department_code')
  final String? departmentCode;

  @JsonKey(name: 'head_of_department')
  final String? headOfDepartment;

  @JsonKey(name: 'is_active', fromJson: _boolFromJson)
  final bool isActive;

  Department({
    required this.departmentId,
    required this.departmentName,
    this.departmentCode,
    this.headOfDepartment,
    required this.isActive,
  });

  static String _stringFromJson(dynamic v) => v?.toString() ?? '';
  static bool _boolFromJson(dynamic v) => v == true || v == 1;

  factory Department.fromJson(Map<String, dynamic> json) =>
      _$DepartmentFromJson(json);

  Map<String, dynamic> toJson() => _$DepartmentToJson(this);
}
