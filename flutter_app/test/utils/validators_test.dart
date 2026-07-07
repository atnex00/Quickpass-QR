import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/utils/validators.dart';

void main() {
  group('Validators', () {
    group('employeeId', () {
      test('returns error for null', () {
        expect(Validators.employeeId(null), 'Employee ID is required');
      });

      test('returns error for empty string', () {
        expect(Validators.employeeId(''), 'Employee ID is required');
      });

      test('returns error for non-6-digit string', () {
        expect(Validators.employeeId('123'), 'Must be exactly 6 digits');
        expect(Validators.employeeId('12345'), 'Must be exactly 6 digits');
        expect(Validators.employeeId('1234567'), 'Must be exactly 6 digits');
        expect(Validators.employeeId('abcdef'), 'Must be exactly 6 digits');
      });

      test('returns null for valid 6-digit ID', () {
        expect(Validators.employeeId('000001'), isNull);
        expect(Validators.employeeId('123456'), isNull);
        expect(Validators.employeeId('999999'), isNull);
      });
    });

    group('password', () {
      test('returns error for null', () {
        expect(Validators.password(null), 'Password is required');
      });

      test('returns error for empty string', () {
        expect(Validators.password(''), 'Password is required');
      });

      test('returns error for too short password', () {
        expect(Validators.password('abc'), 'Password must be at least 4 characters');
      });

      test('returns null for valid password', () {
        expect(Validators.password('abcd'), isNull);
        expect(Validators.password('password123'), isNull);
      });
    });

    group('isRequired', () {
      test('returns error for null', () {
        expect(Validators.isRequired(null), 'This field is required');
      });

      test('returns error for empty string', () {
        expect(Validators.isRequired(''), 'This field is required');
      });

      test('returns null for non-empty string', () {
        expect(Validators.isRequired('value'), isNull);
      });

      test('uses custom field name', () {
        expect(Validators.isRequired('', 'Name'), 'Name is required');
      });
    });

    group('timeRange', () {
      test('returns null if either time is null', () {
        expect(Validators.timeRange(null, '14:00'), isNull);
        expect(Validators.timeRange('09:00', null), isNull);
        expect(Validators.timeRange(null, null), isNull);
      });

      test('returns error if start >= end', () {
        expect(Validators.timeRange('14:00', '09:00'), 'End time must be after start time');
        expect(Validators.timeRange('09:00', '09:00'), 'End time must be after start time');
      });

      test('returns null if start < end', () {
        expect(Validators.timeRange('09:00', '17:00'), isNull);
      });
    });
  });
}
