import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../models/employee.dart';
import '../models/leave_request.dart';
import 'cache_service.dart';
import 'device_service.dart';

class ApiService {
  Dio? _dio;

  Dio get dio => _dio ?? (throw StateError(
        'ApiService not initialized. Call init() first.',
      ));

  @visibleForTesting
  void setDio(Dio value) => _dio = value;

  final _storage = const FlutterSecureStorage();
  String? _cachedToken;
  bool _isRefreshing = false;
  final _pendingRequests = <_PendingRequest>[];
  int _refreshRetryCount = 0;
  VoidCallback? onForceLogout;

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Quickpass/1.0 Flutter/Dart',
      },
    ));

    if (AppConfig.apiBaseUrl.isEmpty) {
      throw ArgumentError(
        'API_BASE_URL is not set. Pass it via --dart-define=API_BASE_URL=https://...',
      );
    }

    if (!kIsWeb) {
      (_dio!.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        return HttpClient();
      };
    }

    _storage.read(key: 'auth_token').then((t) => _cachedToken = t);

    _dio!.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = _cachedToken ?? await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode != 401) {
          return handler.next(error);
        }

        if (error.requestOptions.extra['_retry'] == true) {
          _cachedToken = null;
          await _storage.delete(key: 'auth_token');
          return handler.next(error);
        }

        if (_isRefreshing) {
          _pendingRequests.add(_PendingRequest(
            options: error.requestOptions,
            handler: handler,
          ));
          return;
        }

        _isRefreshing = true;
        try {
          final oldToken = await _storage.read(key: 'auth_token');
          if (oldToken == null) {
            return handler.next(error);
          }

          final refreshDio = Dio(BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: AppConfig.connectTimeout,
            receiveTimeout: AppConfig.receiveTimeout,
          ));
          final refreshSid = await _storage.read(key: 'refresh_sid');
          final refreshData = <String, dynamic>{};
          if (refreshSid != null) refreshData['refresh_sid'] = refreshSid;
          final res = await refreshDio.post(
            '/auth/refresh',
            data: refreshData.isNotEmpty ? refreshData : null,
            options: Options(headers: {
              'Authorization': 'Bearer $oldToken',
              'x-device-id': await DeviceService.getFingerprint(),
            }),
          );
          final rawToken = res.data?['token'];
          if (rawToken is! String || rawToken.isEmpty) {
            throw Exception('Invalid token response from refresh endpoint');
          }
          final newToken = rawToken;
          _cachedToken = newToken;
          await _storage.write(key: 'auth_token', value: newToken);
          final rawRefreshSid = res.data?['refresh_sid'];
          if (rawRefreshSid is String && rawRefreshSid.isNotEmpty) {
            await _storage.write(key: 'refresh_sid', value: rawRefreshSid);
          }
          _refreshRetryCount = 0;

          error.requestOptions.extra['_retry'] = true;
          error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          try {
            final retryResponse = await dio.fetch(error.requestOptions);
            handler.resolve(retryResponse);
          } catch (retryError) {
            handler.reject(retryError as DioException);
          }

          while (_pendingRequests.isNotEmpty) {
            final p = _pendingRequests.removeAt(0);
            p.options.extra['_retry'] = true;
            p.options.headers['Authorization'] = 'Bearer $newToken';
            try {
              final response = await dio.fetch(p.options);
              p.handler.resolve(response);
            } catch (e) {
              p.handler.reject(e as DioException);
            }
          }
        } catch (_) {
          _refreshRetryCount++;
          if (_refreshRetryCount >= 3) {
            _refreshRetryCount = 0;
            await clearLocalAuth();
            while (_pendingRequests.isNotEmpty) {
              _pendingRequests.removeAt(0).handler.next(error);
            }
            onForceLogout?.call();
            return;
          }
          while (_pendingRequests.isNotEmpty) {
            _pendingRequests.removeAt(0).handler.next(error);
          }
          return handler.next(error);
        } finally {
          _isRefreshing = false;
        }
      },
      onResponse: (response, handler) async {
        if (response.data is Map && response.data['force_logout'] == true) {
          await clearLocalAuth();
          onForceLogout?.call();
          return;
        }
        return handler.next(response);
      },
    ));
  }

  // ── Auth ──
  Future<Map<String, dynamic>> login(String employeeId, String password) async {
    final deviceId = await DeviceService.getFingerprint();
    final res = await dio.post('/auth/login',
        data: {
          'employee_id': employeeId,
          'password': password,
        },
        options: Options(headers: {'x-device-id': deviceId}));
    final data = res.data;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Login failed');
    }
    _cachedToken = data['token'] as String?;
    await _storage.write(key: 'auth_token', value: _cachedToken);
    await _storage.write(key: 'employee_id', value: employeeId);
    await _storage.write(key: 'user_data', value: jsonEncode(data['user']));
    if (data['refresh_sid'] != null) {
      await _storage.write(key: 'refresh_sid', value: data['refresh_sid']);
    }
    return data;
  }

  Future<void> clearLocalAuth() async {
    _cachedToken = null;
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'refresh_sid');
    await _storage.delete(key: 'user_data');
    await _storage.delete(key: 'employee_id');
    await CacheService().clearAll();
  }

  Future<void> logout() async {
    if (_dio != null) {
      try {
        await dio.post('/auth/logout');
      } catch (e) {
        debugPrint('logout: server session invalidation failed: $e');
      }
    }
    await clearLocalAuth();
  }

  Future<Map<String, dynamic>?> getStoredUser() async {
    final data = await _storage.read(key: 'user_data');
    if (data != null) return jsonDecode(data);
    return null;
  }

  Future<String?> getStoredToken() async {
    return _cachedToken ?? await _storage.read(key: 'auth_token');
  }

  // ── Employee ──
  Future<Employee> getProfile() async {
    final res = await dio.get('/auth/profile');
    final d = res.data['data'];
    if (d == null) throw Exception('Invalid profile response');
    return Employee.fromJson(d);
  }

  Future<Employee> updateProfile(Map<String, dynamic> data) async {
    final res = await dio.put('/auth/profile', data: data);
    final d = res.data['data'];
    if (d == null) throw Exception('Invalid update profile response');
    return Employee.fromJson(d);
  }

  Future<Employee> uploadProfilePhoto(String filePath) async {
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(filePath, filename: 'profile.jpg'),
    });
    final res = await dio.post('/auth/profile/photo', data: formData);
    final d = res.data['data'];
    if (d == null) throw Exception('Invalid photo upload response');
    return Employee.fromJson(d);
  }

  // ── Notifications ──
  Future<void> updateFcmToken(String token) async {
    await dio.put('/auth/fcm-token', data: {'fcm_token': token});
  }

  // ── Leave Requests ──
  Future<LeaveRequest> submitLeave({
    required String leaveDate,
    required String startTime,
    required String endTime,
    required String reason,
  }) async {
    final res = await dio.post('/leave/request', data: {
      'leave_date': leaveDate,
      'start_time': startTime,
      'end_time': endTime,
      'reason': reason,
    });
    final d = res.data['data'];
    if (d == null) throw Exception('Invalid leave submission response');
    return LeaveRequest.fromJson(d);
  }

  Future<Map<String, dynamic>> getLeaveHistory(
      {String? status, int page = 1, int limit = 20}) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null) params['status'] = status;
    final res = await dio.get('/leave/history', queryParameters: params);
    return res.data;
  }

  Future<LeaveRequest?> getActiveLeave() async {
    try {
      final res = await dio.get('/leave/active');
      return LeaveRequest.fromJson(res.data['data']);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<LeaveRequest> getLeaveById(String id) async {
    final res = await dio.get('/leave/$id');
    final d = res.data['data'];
    if (d == null) throw Exception('Leave not found');
    return LeaveRequest.fromJson(d);
  }

  Future<Uint8List> getQrImageBytes(String leaveId, String type) async {
    final res = await dio.get(
      '/leave/$leaveId/qr/$type',
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data as Uint8List;
  }

  // ── Supervisor ──
  Future<List<LeaveRequest>> getPendingRequests() async {
    final res = await dio.get('/supervisor/pending');
    final list = res.data['data'];
    if (list == null) return [];
    return (list as List).map((j) => LeaveRequest.fromJson(j)).toList();
  }

  Future<LeaveRequest> approveLeave(String leaveId) async {
    final res = await dio.post('/supervisor/approve/$leaveId');
    final d = res.data['data'];
    if (d == null) throw Exception('Failed to approve leave');
    return LeaveRequest.fromJson(d);
  }

  Future<LeaveRequest> rejectLeave(String leaveId, String reason) async {
    final res = await dio
        .post('/supervisor/reject/$leaveId', data: {'reason': reason});
    final d = res.data['data'];
    if (d == null) throw Exception('Failed to reject leave');
    return LeaveRequest.fromJson(d);
  }

  Future<List<LeaveRequest>> getApprovedLeaves() async {
    final res = await dio.get('/supervisor/approved');
    final list = res.data['data'];
    if (list == null) return [];
    return (list as List).map((j) => LeaveRequest.fromJson(j)).toList();
  }

  Future<List<LeaveRequest>> getSupervisorHistory() async {
    final res = await dio.get('/supervisor/history');
    final list = res.data['data'];
    if (list == null) return [];
    return (list as List).map((j) => LeaveRequest.fromJson(j)).toList();
  }

  Future<LeaveRequest> revokeApproval(String leaveId) async {
    final res = await dio.post('/supervisor/revoke/$leaveId');
    final d = res.data['data'];
    if (d == null) throw Exception('Failed to revoke approval');
    return LeaveRequest.fromJson(d);
  }

  Future<List<LeaveRequest>> getTeamLeaves({
    String? date,
    String? startDate,
    String? endDate,
  }) async {
    final params = <String, dynamic>{};
    if (date != null) params['date'] = date;
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    final res =
        await dio.get('/supervisor/team-leaves', queryParameters: params);
    final list = res.data['data'];
    if (list == null) return [];
    return (list as List).map((j) => LeaveRequest.fromJson(j)).toList();
  }

  // ── Team & Directory ──
  Future<List<Employee>> getMyTeam() async {
    final res = await dio.get('/team');
    final list = res.data['data'];
    if (list == null) return [];
    return (list as List).map((j) => Employee.fromJson(j)).toList();
  }

  Future<List<Employee>> getDirectory() async {
    final res = await dio.get('/directory');
    final list = res.data['data'];
    if (list == null) return [];
    return (list as List).map((j) => Employee.fromJson(j)).toList();
  }

  Future<List<LeaveRequest>> getTeamMemberLeaves(String employeeId) async {
    final res = await dio.get('/team/$employeeId/leaves');
    final list = res.data['data'];
    if (list == null) return [];
    return (list as List).map((j) => LeaveRequest.fromJson(j)).toList();
  }

  // ── Scan ──
  Future<Map<String, dynamic>> validateScan(String qrData) async {
    final res = await dio.post('/scan/validate', data: {'qr_data': qrData});
    return res.data;
  }

  Future<Map<String, dynamic>> getScanHistory(
      {int page = 1, int limit = 50}) async {
    final res = await dio
        .get('/scan/history', queryParameters: {'page': page, 'limit': limit});
    return res.data;
  }

  Future<Map<String, dynamic>> getScanStats() async {
    final res = await dio.get('/scan/stats');
    return res.data;
  }

  // ── Admin ──
  Future<Map<String, dynamic>> createEmployee(Map<String, dynamic> data) async {
    final res = await dio.post('/admin/employees', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> listEmployees(
      {String? search,
      String? departmentId,
      String? isActive,
      String? role,
      int page = 1,
      int limit = 20}) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (search != null) params['search'] = search;
    if (departmentId != null) params['department_id'] = departmentId;
    if (isActive != null) params['is_active'] = isActive;
    if (role != null) params['role'] = role;
    final res = await dio.get('/admin/employees', queryParameters: params);
    return res.data;
  }

  Future<Map<String, dynamic>> updateEmployee(
      String id, Map<String, dynamic> data) async {
    final res = await dio.put('/admin/employees/$id', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> toggleSupervisor(String id) async {
    final res = await dio.put('/admin/employees/$id/supervisor');
    return res.data;
  }

  Future<Map<String, dynamic>> toggleAdmin(String id) async {
    final res = await dio.put('/admin/employees/$id/admin');
    return res.data;
  }

  Future<void> toggleActive(String id) async {
    await dio.put('/admin/employees/$id/status');
  }

  Future<void> deleteEmployee(String id) async {
    await dio.delete('/admin/employees/$id');
  }

  Future<void> resetPassword(String id, String password) async {
    await dio.put('/admin/employees/$id',
        data: {'password': password});
  }

  Future<void> cancelLeave(String leaveId) async {
    await dio.post('/leave/$leaveId/cancel');
  }

  Future<void> deleteLeave(String leaveId) async {
    await dio.delete('/leave/$leaveId');
  }

  Future<Map<String, dynamic>> importEmployees(
      List<Map<String, dynamic>> employees) async {
    final res =
        await dio.post('/admin/import/hr', data: {'employees': employees});
    return res.data;
  }

  Future<List<dynamic>> getDepartments() async {
    final res = await dio.get('/admin/departments');
    return res.data['data'];
  }

  Future<void> createDepartment(Map<String, dynamic> data) async {
    await dio.post('/admin/departments', data: data);
  }

  Future<void> updateDepartment(String id, Map<String, dynamic> data) async {
    await dio.put('/admin/departments/$id', data: data);
  }

  Future<void> deleteDepartment(String id) async {
    await dio.delete('/admin/departments/$id');
  }

  Future<Map<String, dynamic>> getReports(
      {String? type, String? startDate, String? endDate}) async {
    final params = <String, dynamic>{};
    if (type != null) params['type'] = type;
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    final res = await dio.get('/admin/reports', queryParameters: params);
    return res.data;
  }
}

class _PendingRequest {

  _PendingRequest({required this.options, required this.handler});
  final RequestOptions options;
  final ErrorInterceptorHandler handler;
}
