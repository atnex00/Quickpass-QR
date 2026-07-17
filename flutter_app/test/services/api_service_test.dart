import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quickpass/models/leave_request.dart';
import 'package:quickpass/services/api_service.dart';

import '../helpers/test_setup.dart';

Map<String, dynamic> _mockResponse({Map<String, dynamic>? data, bool success = true, String? message}) {
  return {'success': success, 'data': data, 'message': message};
}

void main() {
  late ApiService api;
  late Dio dio;

  setUp(() async {
    await setupTestInfrastructure();
    api = ApiService();
    dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.next(options);
      },
    ));
    api.setDio(dio);
  });

  group('auth', () {
    test('login returns data and stores credentials', () async {
      const employeeId = '000001';
      const token = 'test-jwt-token';
      const refreshSid = 'test-refresh-sid';
      final userJson = {
        'employee_id': employeeId,
        'full_name': 'Alice Chen',
        'position': 'Engineer',
        'department_id': '1',
        'department_name': 'Engineering',
        'email': 'alice@test.com',
        'is_supervisor': false,
        'is_admin': false,
        'is_security': false,
        'is_active': true,
      };

      dio.interceptors.clear();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'token': token,
              'refresh_sid': refreshSid,
              'user': userJson,
            },
          ));
        },
      ));

      final result = await api.login(employeeId, 'pass1234');

      expect(result['success'], true);
      expect(result['token'], token);
      expect(result['user']['employee_id'], employeeId);
    });

    test('login throws on failed auth', () async {
      dio.interceptors.clear();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 401,
            data: {'success': false, 'message': 'Invalid credentials'},
          ));
        },
      ));

      expect(() => api.login('000001', 'wrong'), throwsException);
    });

    test('clearLocalAuth deletes stored keys', () async {
      await api.clearLocalAuth();
    });

    test('logout clears local auth even if API call fails', () async {
      dio.interceptors.clear();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(DioException(requestOptions: options, type: DioExceptionType.connectionError));
        },
      ));

      await api.logout();
    });
  });

  group('employee', () {
    test('getProfile returns Employee', () async {
      dio.interceptors.clear();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: _mockResponse(data: {
              'employee_id': '000001',
              'full_name': 'Alice Chen',
              'position': 'Engineer',
              'department_id': '1',
              'department_name': 'Engineering',
              'email': 'alice@test.com',
              'is_supervisor': false,
              'is_admin': false,
              'is_security': false,
              'is_active': true,
            }),
          ));
        },
      ));

      final employee = await api.getProfile();

      expect(employee.employeeId, '000001');
      expect(employee.fullName, 'Alice Chen');
      expect(employee.position, 'Engineer');
      expect(employee.departmentName, 'Engineering');
    });

    test('getProfile throws on missing data', () async {
      dio.interceptors.clear();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {'success': true},
          ));
        },
      ));

      expect(() => api.getProfile(), throwsException);
    });
  });

  group('leave requests', () {
    test('submitLeave returns LeaveRequest', () async {
      dio.interceptors.clear();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: _mockResponse(data: {
              'leave_id': 'l1',
              'employee_id': '000001',
              'employee_name': 'Alice Chen',
              'department_id': '1',
              'supervisor_id': 'sup1',
              'supervisor_name': 'David Kim',
              'leave_date': '2025-07-15',
              'start_time': '09:00',
              'end_time': '12:00',
              'reason': 'Medical appointment',
              'status': 'pending',
              'created_at': '2025-07-14T10:00:00Z',
              'updated_at': '2025-07-14T10:00:00Z',
            }),
          ));
        },
      ));

      final leave = await api.submitLeave(
        leaveDate: '2025-07-15',
        startTime: '09:00',
        endTime: '12:00',
        reason: 'Medical appointment',
      );

      expect(leave.leaveId, 'l1');
      expect(leave.status, LeaveStatus.pending);
      expect(leave.durationMinutes, 180);
    });
  });

  group('supervisor', () {
    test('getPendingRequests returns list', () async {
      dio.interceptors.clear();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': [
                {
                  'leave_id': 'l1',
                  'employee_id': '000001',
                  'employee_name': 'Alice Chen',
                  'department_id': '1',
                  'supervisor_id': 'sup1',
                  'supervisor_name': 'David Kim',
                  'leave_date': '2025-07-15',
                  'start_time': '09:00',
                  'end_time': '12:00',
                  'reason': 'Sick leave',
                  'status': 'pending',
                  'created_at': '2025-07-14T10:00:00Z',
                  'updated_at': '2025-07-14T10:00:00Z',
                },
              ],
            },
          ));
        },
      ));

      final list = await api.getPendingRequests();

      expect(list.length, 1);
      expect(list.first.leaveId, 'l1');
    });

    test('getPendingRequests returns empty on null data', () async {
      dio.interceptors.clear();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {'success': true},
          ));
        },
      ));

      final list = await api.getPendingRequests();

      expect(list, isEmpty);
    });
  });

  group('scan', () {
    test('validateScan returns result', () async {
      dio.interceptors.clear();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'message': 'Valid QR code',
              'data': {'type': 'OUT', 'employee_name': 'Alice Chen'},
            },
          ));
        },
      ));

      final result = await api.validateScan('qr-data');

      expect(result['success'], true);
      expect(result['data']['type'], 'OUT');
    });
  });

  group('admin', () {
    test('listEmployees returns data', () async {
      dio.interceptors.clear();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': [
                {
                  'employee_id': '000001',
                  'full_name': 'Alice Chen',
                  'position': 'Engineer',
                  'department_id': '1',
                  'department_name': 'Engineering',
                  'email': 'alice@test.com',
                  'is_supervisor': false,
                  'is_admin': false,
                  'is_security': false,
                  'is_active': true,
                },
              ],
            },
          ));
        },
      ));

      final result = await api.listEmployees();

      expect(result['success'], true);
    });

    test('getDepartments returns list', () async {
      dio.interceptors.clear();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {'success': true, 'data': [
              {'department_id': '1', 'department_name': 'Engineering', 'department_code': 'ENG', 'is_active': true},
            ]},
          ));
        },
      ));

      final list = await api.getDepartments();

      expect(list.length, 1);
      expect(list.first['department_name'], 'Engineering');
    });
  });

  group('error handling', () {
    test('getActiveLeave returns null on exception', () async {
      dio.interceptors.clear();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(DioException(requestOptions: options, type: DioExceptionType.badResponse));
        },
      ));

      final result = await api.getActiveLeave();

      expect(result, isNull);
    });
  });
}
