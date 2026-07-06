import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/models/department.dart';

void main() {
  group('Department', () {
    test('fromJson parses all fields with snake_case keys', () {
      final dept = Department.fromJson({
        'department_id': '1',
        'department_name': 'Engineering',
        'department_code': 'ENG',
        'head_of_department': 'David Kim',
        'is_active': true,
      });

      expect(dept.departmentId, '1');
      expect(dept.departmentName, 'Engineering');
      expect(dept.departmentCode, 'ENG');
      expect(dept.headOfDepartment, 'David Kim');
      expect(dept.isActive, true);
    });

    test('fromJson parses all fields with camelCase keys', () {
      final dept = Department.fromJson({
        'departmentId': '2',
        'departmentName': 'HR',
        'department_code': 'HR',
        'head_of_department': 'Jane Doe',
        'is_active': false,
      });

      expect(dept.departmentId, '2');
      expect(dept.departmentName, 'HR');
    });

    test('fromJson handles missing fields with defaults', () {
      final dept = Department.fromJson({});

      expect(dept.departmentId, '');
      expect(dept.departmentName, '');
      expect(dept.departmentCode, isNull);
      expect(dept.headOfDepartment, isNull);
      expect(dept.isActive, true);
    });

    test('toJson produces correct map', () {
      final dept = Department(
        departmentId: '1',
        departmentName: 'Engineering',
        departmentCode: 'ENG',
        headOfDepartment: 'David Kim',
        isActive: true,
      );

      final json = dept.toJson();
      expect(json['department_id'], '1');
      expect(json['department_name'], 'Engineering');
      expect(json['department_code'], 'ENG');
      expect(json['head_of_department'], 'David Kim');
      expect(json['is_active'], true);
    });

    test('toJson round-trips correctly', () {
      final original = Department(
        departmentId: '1',
        departmentName: 'Engineering',
        departmentCode: 'ENG',
        headOfDepartment: 'David Kim',
        isActive: true,
      );

      final json = original.toJson();
      final restored = Department.fromJson(json);

      expect(restored.departmentId, original.departmentId);
      expect(restored.departmentName, original.departmentName);
    });
  });
}
