class Employee {
  final String employeeId;
  final String fullName;
  final String position;
  final String departmentId;
  final String departmentName;
  final String email;
  final bool isSupervisor;
  final bool isAdmin;
  final bool isSecurity;
  final bool isActive;
  final String? profilePhoto;
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

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      employeeId: json['employee_id'] ?? '',
      fullName: json['full_name'] ?? '',
      position: json['position'] ?? '',
      departmentId: (json['department_id'] ?? '').toString(),
      departmentName: json['department_name'] ?? '',
      email: json['email'] ?? '',
      isSupervisor: json['is_supervisor'] ?? false,
      isAdmin: json['is_admin'] ?? false,
      isSecurity: json['is_security'] ?? false,
      isActive: json['is_active'] ?? true,
      profilePhoto: json['profile_photo'],
      hireDate: json['hire_date'] != null ? DateTime.tryParse(json['hire_date']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'employee_id': employeeId,
    'full_name': fullName,
    'position': position,
    'department_id': departmentId,
    'department_name': departmentName,
    'email': email,
    'is_supervisor': isSupervisor,
    'is_admin': isAdmin,
    'is_security': isSecurity,
    'is_active': isActive,
    'profile_photo': profilePhoto,
    'hire_date': hireDate?.toIso8601String().split('T').first,
  };

  static bool isValidId(String id) => RegExp(r'^\d{6}$').hasMatch(id);

  String get formattedId => employeeId.padLeft(6, '0');
}
