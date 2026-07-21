import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/models/employee.dart';

void main() {
  group('Employee', () {
    final validJson = {
      'employee_id': '000001',
      'full_name': 'Alice Chen',
      'position': 'Engineer',
      'department_id': '1',
      'department_name': 'Engineering',
      'email': 'alice@example.com',
      'is_supervisor': false,
      'is_admin': false,
      'is_security': false,
      'is_active': true,
      'profile_photo': null,
      'hire_date': '2024-01-15',
    };

    test('fromJson parses all fields correctly', () {
      final employee = Employee.fromJson(validJson);

      expect(employee.employeeId, '000001');
      expect(employee.fullName, 'Alice Chen');
      expect(employee.position, 'Engineer');
      expect(employee.departmentId, '1');
      expect(employee.departmentName, 'Engineering');
      expect(employee.email, 'alice@example.com');
      expect(employee.isSupervisor, false);
      expect(employee.isAdmin, false);
      expect(employee.isSecurity, false);
      expect(employee.isActive, true);
      expect(employee.profilePhoto, isNull);
      expect(employee.hireDate, isNotNull);
    });

    test('fromJson handles missing fields with defaults', () {
      final employee = Employee.fromJson({});

      expect(employee.employeeId, '');
      expect(employee.fullName, '');
      expect(employee.position, '');
      expect(employee.departmentId, '');
      expect(employee.departmentName, '');
      expect(employee.email, '');
      expect(employee.isSupervisor, false);
      expect(employee.isAdmin, false);
      expect(employee.isSecurity, false);
      expect(employee.isActive, false);
      expect(employee.profilePhoto, isNull);
      expect(employee.hireDate, isNull);
    });

    test('fromJson coerces truthy values to bool', () {
      final employee = Employee.fromJson({
        'is_supervisor': true,
        'is_admin': false,
        'is_security': null,
        'is_active': true,
      });

      expect(employee.isSupervisor, true);
      expect(employee.isAdmin, false);
      expect(employee.isSecurity, false);
      expect(employee.isActive, true);
    });

    test('toJson produces correct map', () {
      final employee = Employee.fromJson(validJson);
      final json = employee.toJson();

      expect(json['employee_id'], '000001');
      expect(json['full_name'], 'Alice Chen');
      expect(json['hire_date'], '2024-01-15');
    });

    test('toJson round-trips correctly', () {
      final original = Employee.fromJson(validJson);
      final json = original.toJson();
      final restored = Employee.fromJson(json);

      expect(restored.employeeId, original.employeeId);
      expect(restored.fullName, original.fullName);
      expect(restored.hireDate, original.hireDate);
    });

    test('isValidId returns true for 6-digit strings', () {
      expect(Employee.isValidId('000001'), true);
      expect(Employee.isValidId('123456'), true);
      expect(Employee.isValidId('999999'), true);
    });

    test('isValidId returns false for invalid IDs', () {
      expect(Employee.isValidId('12345'), false);
      expect(Employee.isValidId('1234567'), false);
      expect(Employee.isValidId('abcdef'), false);
      expect(Employee.isValidId(''), false);
    });

    test('formattedId pads to 6 digits', () {
      final emp1 = Employee.fromJson({...validJson, 'employee_id': '123'});
      expect(emp1.formattedId, '000123');

      final emp2 = Employee.fromJson({...validJson, 'employee_id': '000001'});
      expect(emp2.formattedId, '000001');
    });
  });
}
