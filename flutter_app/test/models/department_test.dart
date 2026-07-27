import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/models/department.dart';

void main() {
  group('Department', () {
    test('fromJson parses all fields with snake_case keys', () {
      final dept = Department.fromJson({
        'department_id': 'DEP-001',
        'department_name': 'ISD · Institutional Services Department',
        'department_code': 'ISD',
        'head_of_department': 'Alex Turner',
        'is_active': true,
      });

      expect(dept.departmentId, 'DEP-001');
      expect(dept.departmentName, 'ISD · Institutional Services Department');
      expect(dept.departmentCode, 'ISD');
      expect(dept.headOfDepartment, 'Alex Turner');
      expect(dept.isActive, true);
    });

    test('fromJson handles missing fields with defaults', () {
      final dept = Department.fromJson({});

      expect(dept.departmentId, '');
      expect(dept.departmentName, '');
      expect(dept.departmentCode, isNull);
      expect(dept.headOfDepartment, isNull);
      expect(dept.isActive, false);
    });

    test('toJson produces correct map', () {
      final dept = Department(
        departmentId: 'DEP-001',
        departmentName: 'ISD · Institutional Services Department',
        departmentCode: 'ISD',
        headOfDepartment: 'Alex Turner',
        isActive: true,
      );

      final json = dept.toJson();
      expect(json['department_id'], 'DEP-001');
      expect(json['department_name'], 'ISD · Institutional Services Department');
      expect(json['department_code'], 'ISD');
      expect(json['head_of_department'], 'Alex Turner');
      expect(json['is_active'], true);
    });

    test('fromJson handles nullable fields as null', () {
      final dept = Department.fromJson({
        'department_id': 'DEP-001',
        'department_name': 'ISD · Institutional Services Department',
        'is_active': true,
      });

      expect(dept.departmentCode, isNull);
      expect(dept.headOfDepartment, isNull);
    });

    test('toJson round-trips correctly', () {
      final original = Department(
        departmentId: 'DEP-001',
        departmentName: 'ISD · Institutional Services Department',
        departmentCode: 'ISD',
        headOfDepartment: 'Alex Turner',
        isActive: true,
      );

      final json = original.toJson();
      final restored = Department.fromJson(json);

      expect(restored.departmentId, original.departmentId);
      expect(restored.departmentName, original.departmentName);
    });
  });
}
