import 'package:json_annotation/json_annotation.dart';

part 'scan_department.g.dart';

@JsonSerializable()
class ScanDepartment {
  ScanDepartment({
    required this.departmentName,
    this.departmentCode = '',
    this.scanCount = 0,
  });

  factory ScanDepartment.fromJson(Map<String, dynamic> json) =>
      _$ScanDepartmentFromJson(json);

  @JsonKey(name: 'department_name')
  final String departmentName;
  @JsonKey(name: 'department_code')
  final String departmentCode;
  @JsonKey(name: 'scan_count')
  final int scanCount;

  Map<String, dynamic> toJson() => _$ScanDepartmentToJson(this);
}