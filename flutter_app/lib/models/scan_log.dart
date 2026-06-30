class ScanLog {
  final int logId;
  final String leaveId;
  final String qrType;
  final String? scannedBy;
  final DateTime scanTime;
  final String? ipAddress;
  final bool isValid;
  final String? validationMessage;
  final String? employeeName;
  final String? employeeId;

  ScanLog({
    required this.logId,
    required this.leaveId,
    required this.qrType,
    this.scannedBy,
    required this.scanTime,
    this.ipAddress,
    required this.isValid,
    this.validationMessage,
    this.employeeName,
    this.employeeId,
  });

  factory ScanLog.fromJson(Map<String, dynamic> json) {
    return ScanLog(
      logId: json['log_id'] ?? 0,
      leaveId: json['leave_id'] ?? '',
      qrType: json['qr_type'] ?? '',
      scannedBy: json['scanned_by'],
      scanTime: DateTime.parse(json['scan_time']),
      ipAddress: json['ip_address'],
      isValid: json['is_valid'] ?? true,
      validationMessage: json['validation_message'],
      employeeName: json['employee_name'],
      employeeId: json['employee_id'],
    );
  }
}
