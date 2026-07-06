import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../models/employee.dart';
import '../models/leave_request.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  final _storage = const FlutterSecureStorage();

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    if (!kIsWeb) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () => HttpClient();
    }

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await _storage.deleteAll();
        }
        return handler.next(error);
      },
      onResponse: (response, handler) async {
        if (response.data is Map && response.data['force_logout'] == true) {
          await _storage.deleteAll();
        }
        return handler.next(response);
      },
    ));
  }

  // ── Auth ──
  Future<Map<String, dynamic>> login(String employeeId, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'employee_id': employeeId,
      'password': password,
    });
    final data = res.data;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Login failed');
    }
    await _storage.write(key: 'auth_token', value: data['token']);
    await _storage.write(key: 'employee_id', value: employeeId);
    await _storage.write(key: 'user_data', value: jsonEncode(data['user']));
    return data;
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    await _storage.deleteAll();
  }

  Future<Map<String, dynamic>?> getStoredUser() async {
    final data = await _storage.read(key: 'user_data');
    if (data != null) return jsonDecode(data);
    return null;
  }

  Future<String?> getStoredToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // ── Employee ──
  Future<Employee> getProfile() async {
    final res = await _dio.get('/auth/profile');
    final d = res.data['data'];
    if (d == null) throw Exception('Invalid profile response');
    return Employee.fromJson(d);
  }

  Future<Employee> updateProfile(Map<String, dynamic> data) async {
    final res = await _dio.put('/auth/profile', data: data);
    final d = res.data['data'];
    if (d == null) throw Exception('Invalid update profile response');
    return Employee.fromJson(d);
  }

  // ── Leave Requests ──
  Future<LeaveRequest> submitLeave({
    required String leaveDate,
    required String startTime,
    required String endTime,
    required String reason,
  }) async {
    final res = await _dio.post('/leave/request', data: {
      'leave_date': leaveDate,
      'start_time': startTime,
      'end_time': endTime,
      'reason': reason,
    });
    final d = res.data['data'];
    if (d == null) throw Exception('Invalid leave submission response');
    return LeaveRequest.fromJson(d);
  }

  Future<Map<String, dynamic>> getLeaveHistory({String? status, int page = 1, int limit = 20}) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null) params['status'] = status;
    final res = await _dio.get('/leave/history', queryParameters: params);
    return res.data;
  }

  Future<LeaveRequest?> getActiveLeave() async {
    try {
      final res = await _dio.get('/leave/active');
      return LeaveRequest.fromJson(res.data['data']);
    } catch (_) {
      return null;
    }
  }

  Future<LeaveRequest> getLeaveById(String id) async {
    final res = await _dio.get('/leave/$id');
    final d = res.data['data'];
    if (d == null) throw Exception('Leave not found');
    return LeaveRequest.fromJson(d);
  }

  // ── Supervisor ──
  Future<List<LeaveRequest>> getPendingRequests() async {
    final res = await _dio.get('/supervisor/pending');
    final list = res.data['data'];
    if (list == null) return [];
    return (list as List).map((j) => LeaveRequest.fromJson(j)).toList();
  }

  Future<LeaveRequest> approveLeave(String leaveId) async {
    final res = await _dio.post('/supervisor/approve/$leaveId');
    final d = res.data['data'];
    if (d == null) throw Exception('Failed to approve leave');
    return LeaveRequest.fromJson(d);
  }

  Future<LeaveRequest> rejectLeave(String leaveId, String reason) async {
    final res = await _dio.post('/supervisor/reject/$leaveId', data: {'reason': reason});
    final d = res.data['data'];
    if (d == null) throw Exception('Failed to reject leave');
    return LeaveRequest.fromJson(d);
  }

  Future<List<LeaveRequest>> getApprovedLeaves() async {
    final res = await _dio.get('/supervisor/approved');
    final list = res.data['data'];
    if (list == null) return [];
    return (list as List).map((j) => LeaveRequest.fromJson(j)).toList();
  }

  Future<LeaveRequest> revokeApproval(String leaveId) async {
    final res = await _dio.post('/supervisor/revoke/$leaveId');
    final d = res.data['data'];
    if (d == null) throw Exception('Failed to revoke approval');
    return LeaveRequest.fromJson(d);
  }

  Future<List<LeaveRequest>> getTeamLeaves({String? date}) async {
    final params = <String, dynamic>{};
    if (date != null) params['date'] = date;
    final res = await _dio.get('/supervisor/team-leaves', queryParameters: params);
    final list = res.data['data'];
    if (list == null) return [];
    return (list as List).map((j) => LeaveRequest.fromJson(j)).toList();
  }

  // ── Scan ──
  Future<Map<String, dynamic>> validateScan(String qrData) async {
    final res = await _dio.post('/scan/validate', data: {'qr_data': qrData});
    return res.data;
  }

  Future<Map<String, dynamic>> getScanHistory({int page = 1, int limit = 50}) async {
    final res = await _dio.get('/scan/history', queryParameters: {'page': page, 'limit': limit});
    return res.data;
  }

  // ── Admin ──
  Future<Map<String, dynamic>> createEmployee(Map<String, dynamic> data) async {
    final res = await _dio.post('/admin/employees', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> listEmployees({String? search, String? departmentId, String? status, String? role, int page = 1, int limit = 20}) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (search != null) params['search'] = search;
    if (departmentId != null) params['department_id'] = departmentId;
    if (status != null) params['status'] = status;
    if (role != null) params['role'] = role;
    final res = await _dio.get('/admin/employees', queryParameters: params);
    return res.data;
  }

  Future<Map<String, dynamic>> updateEmployee(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/admin/employees/$id', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> toggleSupervisor(String id) async {
    final res = await _dio.put('/admin/employees/$id/supervisor');
    return res.data;
  }

  Future<Map<String, dynamic>> toggleAdmin(String id) async {
    final res = await _dio.put('/admin/employees/$id/admin');
    return res.data;
  }

  Future<void> toggleActive(String id) async {
    await _dio.put('/admin/employees/$id/status');
  }

  Future<void> deleteEmployee(String id) async {
    await _dio.delete('/admin/employees/$id');
  }

  Future<void> resetPassword(String id, String password) async {
    await _dio.put('/admin/employees/$id/reset-password', data: {'password': password});
  }

  Future<void> deleteLeave(String leaveId) async {
    await _dio.delete('/leave/$leaveId');
  }

  Future<Map<String, dynamic>> importEmployees(List<Map<String, dynamic>> employees) async {
    final res = await _dio.post('/admin/import/hr', data: {'employees': employees});
    return res.data;
  }

  Future<List<dynamic>> getDepartments() async {
    final res = await _dio.get('/admin/departments');
    return res.data['data'];
  }

  Future<void> createDepartment(Map<String, dynamic> data) async {
    await _dio.post('/admin/departments', data: data);
  }

  Future<void> deleteDepartment(String id) async {
    await _dio.delete('/admin/departments/$id');
  }

  Future<Map<String, dynamic>> getReports({String? type, String? startDate, String? endDate}) async {
    final params = <String, dynamic>{};
    if (type != null) params['type'] = type;
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    final res = await _dio.get('/admin/reports', queryParameters: params);
    return res.data;
  }
}
