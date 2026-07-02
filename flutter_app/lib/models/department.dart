class Department {
  final String departmentId;
  final String departmentName;
  final String? departmentCode;
  final String? headOfDepartment;
  final bool isActive;

  Department({
    required this.departmentId,
    required this.departmentName,
    this.departmentCode,
    this.headOfDepartment,
    required this.isActive,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      departmentId: json['department_id'] ?? json['departmentId'] as String,
      departmentName: json['department_name'] ?? json['departmentName'] as String,
      departmentCode: json['department_code'] as String?,
      headOfDepartment: json['head_of_department'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'department_id': departmentId,
    'department_name': departmentName,
    'department_code': departmentCode,
    'head_of_department': headOfDepartment,
    'is_active': isActive,
  };
}
