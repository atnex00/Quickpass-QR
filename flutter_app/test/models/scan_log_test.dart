import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/models/scan_log.dart';

void main() {
  group('ScanLog', () {
    final now = DateTime.now();
    final isoNow = now.toIso8601String();

    test('fromJson parses all fields correctly', () {
      final log = ScanLog.fromJson({
        'log_id': 42,
        'leave_id': 'leave-001',
        'qr_type': 'out',
        'scanned_by': 'security-1',
        'scan_time': isoNow,
        'ip_address': '192.168.1.1',
        'is_valid': true,
        'validation_message': 'Valid QR',
        'employee_name': 'James Wilson',
        'employee_id': '000001',
        'department_name': 'Technical Services',
        'scanned_by_name': 'Mike Ross',
      });

      expect(log.logId, 42);
      expect(log.leaveId, 'leave-001');
      expect(log.qrType, 'out');
      expect(log.scannedBy, 'security-1');
      expect(log.isValid, true);
      expect(log.validationMessage, 'Valid QR');
      expect(log.employeeName, 'James Wilson');
      expect(log.employeeId, '000001');
      expect(log.departmentName, 'Technical Services');
      expect(log.scannedByName, 'Mike Ross');
    });

    test('fromJson handles missing fields with defaults', () {
      final log = ScanLog.fromJson({
        'scan_time': isoNow,
      });

      expect(log.logId, 0);
      expect(log.leaveId, '');
      expect(log.qrType, '');
      expect(log.scannedBy, isNull);
      expect(log.isValid, false);
      expect(log.validationMessage, isNull);
      expect(log.employeeName, isNull);
      expect(log.employeeId, isNull);
      expect(log.departmentName, isNull);
      expect(log.scannedByName, isNull);
    });

    test('toJson round-trips correctly', () {
      final original = ScanLog.fromJson({
        'log_id': 42,
        'leave_id': 'leave-001',
        'qr_type': 'out',
        'scanned_by': 'security-1',
        'scan_time': isoNow,
        'ip_address': '192.168.1.1',
        'is_valid': true,
        'validation_message': 'Valid QR',
        'employee_name': 'James Wilson',
        'employee_id': '000001',
      });

      final json = original.toJson();
      final restored = ScanLog.fromJson(json);

      expect(restored.logId, original.logId);
      expect(restored.leaveId, original.leaveId);
      expect(restored.qrType, original.qrType);
      expect(restored.scanTime, original.scanTime);
    });
  });
}
