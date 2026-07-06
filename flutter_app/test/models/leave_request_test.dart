import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/models/leave_request.dart';

void main() {
  group('LeaveStatus', () {
    test('fromString returns correct enum value', () {
      expect(LeaveStatus.fromString('pending'), LeaveStatus.pending);
      expect(LeaveStatus.fromString('approved'), LeaveStatus.approved);
      expect(LeaveStatus.fromString('rejected'), LeaveStatus.rejected);
      expect(LeaveStatus.fromString('active'), LeaveStatus.active);
      expect(LeaveStatus.fromString('completed'), LeaveStatus.completed);
      expect(LeaveStatus.fromString('cancelled'), LeaveStatus.cancelled);
    });

    test('fromString returns pending for unknown value', () {
      expect(LeaveStatus.fromString('unknown'), LeaveStatus.pending);
    });

    test('label returns correct display strings', () {
      expect(LeaveStatus.pending.label, 'Pending');
      expect(LeaveStatus.approved.label, 'Approved');
      expect(LeaveStatus.rejected.label, 'Rejected');
      expect(LeaveStatus.active.label, 'Active');
      expect(LeaveStatus.completed.label, 'Completed');
      expect(LeaveStatus.cancelled.label, 'Cancelled');
    });

    test('color returns non-null color for all statuses', () {
      for (final status in LeaveStatus.values) {
        expect(status.color, isNotNull);
      }
    });

    test('icon returns non-null icon for all statuses', () {
      for (final status in LeaveStatus.values) {
        expect(status.icon, isNotNull);
      }
    });
  });

  group('LeaveRequest', () {
    final baseJson = {
      'leave_id': 'leave-001',
      'employee_id': '000001',
      'employee_name': 'Alice Chen',
      'department_id': '1',
      'supervisor_id': '000004',
      'supervisor_name': 'David Kim',
      'leave_date': '2025-06-15',
      'start_time': '09:00',
      'end_time': '17:00',
      'reason': 'Medical appointment',
      'status': 'pending',
      'created_at': '2025-06-10T08:00:00Z',
      'updated_at': '2025-06-10T08:00:00Z',
    };

    test('fromJson parses all required fields correctly', () {
      final lr = LeaveRequest.fromJson(baseJson);

      expect(lr.leaveId, 'leave-001');
      expect(lr.employeeId, '000001');
      expect(lr.employeeName, 'Alice Chen');
      expect(lr.departmentId, '1');
      expect(lr.supervisorId, '000004');
      expect(lr.supervisorName, 'David Kim');
      expect(lr.leaveDate, DateTime(2025, 6, 15));
      expect(lr.startTime, '09:00');
      expect(lr.endTime, '17:00');
      expect(lr.reason, 'Medical appointment');
      expect(lr.status, LeaveStatus.pending);
    });

    test('fromJson parses optional fields correctly', () {
      final lr = LeaveRequest.fromJson({
        ...baseJson,
        'status': 'approved',
        'out_qr_code': 'qr-out-123',
        'in_qr_code': 'qr-in-456',
        'out_scan_time': '2025-06-15T09:05:00Z',
        'in_scan_time': '2025-06-15T17:10:00Z',
        'rejection_reason': null,
        'employee_position': 'Engineer',
        'employee_photo': 'https://example.com/photo.jpg',
      });

      expect(lr.status, LeaveStatus.approved);
      expect(lr.outQrCode, 'qr-out-123');
      expect(lr.inQrCode, 'qr-in-456');
      expect(lr.outScanTime, isNotNull);
      expect(lr.inScanTime, isNotNull);
      expect(lr.rejectionReason, isNull);
      expect(lr.employeePosition, 'Engineer');
      expect(lr.employeePhoto, 'https://example.com/photo.jpg');
    });

    test('fromJson handles missing fields with defaults', () {
      final lr = LeaveRequest.fromJson({});

      expect(lr.leaveId, '');
      expect(lr.leaveDate, isNotNull);
      expect(lr.status, LeaveStatus.pending);
    });

    test('toJson round-trips correctly', () {
      final original = LeaveRequest.fromJson(baseJson);
      final json = original.toJson();
      final restored = LeaveRequest.fromJson(json);

      expect(restored.leaveId, original.leaveId);
      expect(restored.employeeId, original.employeeId);
      expect(restored.status, original.status);
      expect(restored.leaveDate, original.leaveDate);
    });

    test('hasQrCodes returns false when QR codes are null', () {
      final lr = LeaveRequest.fromJson(baseJson);
      expect(lr.hasQrCodes, false);
    });

    test('hasQrCodes returns true when both QR codes are present', () {
      final lr = LeaveRequest.fromJson({
        ...baseJson,
        'out_qr_code': 'qr-out',
        'in_qr_code': 'qr-in',
      });
      expect(lr.hasQrCodes, true);
    });

    group('durationMinutes', () {
      test('calculates same-day duration correctly', () {
        final lr = LeaveRequest.fromJson({
          ...baseJson,
          'start_time': '09:00',
          'end_time': '17:00',
        });
        expect(lr.durationMinutes, 480);
      });

      test('returns 0 for invalid time format', () {
        final lr = LeaveRequest.fromJson({
          ...baseJson,
          'start_time': 'invalid',
          'end_time': '17:00',
        });
        expect(lr.durationMinutes, 0);
      });

      test('handles overnight duration', () {
        final lr = LeaveRequest.fromJson({
          ...baseJson,
          'start_time': '22:00',
          'end_time': '02:00',
        });
        expect(lr.durationMinutes, 240);
      });
    });

    group('durationText', () {
      test('formats hours and minutes', () {
        final lr = LeaveRequest.fromJson({
          ...baseJson,
          'start_time': '09:00',
          'end_time': '17:00',
        });
        expect(lr.durationText, '8h 0m');
      });

      test('formats minutes only', () {
        final lr = LeaveRequest.fromJson({
          ...baseJson,
          'start_time': '09:00',
          'end_time': '09:30',
        });
        expect(lr.durationText, '30m');
      });

      test('returns 0m for zero duration', () {
        final lr = LeaveRequest.fromJson({
          ...baseJson,
          'start_time': '09:00',
          'end_time': '09:00',
        });
        expect(lr.durationText, '0m');
      });
    });
  });
}
