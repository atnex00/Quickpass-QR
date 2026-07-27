import 'package:flutter/widgets.dart';

import '../models/employee.dart';
import '../services/analytics_service.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../utils/errors.dart';

class AuthProvider extends ChangeNotifier {

  AuthProvider({required ApiService api}) : _api = api;
  final ApiService _api;
  VoidCallback? onLoggedOut;
  VoidCallback? onLoggedIn;

  Employee? _user;
  bool _isLoading = true;
  bool _loginLoading = false;
  bool _isAuthenticated = false;
  String? _error;
  bool _isInitializing = false;

  Employee? get user => _user;
  bool get isLoading => _isLoading;
  bool get loginLoading => _loginLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  bool get isSupervisor => _user?.isSupervisor ?? false;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isSecurity => _user?.isSecurity ?? false;
  bool get isScanner => _user?.isSecurity == true;

  Future<void> initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _api.getStoredToken();
      if (token != null) {
        final user = await _api.getProfile();
        _user = user;
        _isAuthenticated = true;
        CacheService().saveProfile(user.toJson());
      }
    } catch (e) {
      try {
        final cached = await CacheService().loadProfile();
        if (cached != null) {
          _user = Employee.fromJson(cached);
          _isAuthenticated = true;
        } else {
          await _api.clearLocalAuth();
        }
      } catch (cacheError) {
      }
    } finally {
      _isLoading = false;
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<bool> login(String employeeId, String password) async {
    _loginLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.login(employeeId, password);
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Login failed');
      }
      _user = Employee.fromJson(data['user']);
      _isAuthenticated = true;
      _loginLoading = false;
      notifyListeners();
      onLoggedIn?.call();
      final role = isAdmin ? 'admin' : isSupervisor ? 'supervisor' : isSecurity ? 'security' : 'employee';
      AnalyticsService().logLogin(role: role);
      return true;
    } catch (e) {
      _error = friendlyError(e);
      _isAuthenticated = false;
      _loginLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    _isAuthenticated = false;
    _user = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
    AnalyticsService().logLogout();
    onLoggedOut?.call();
  }

  Future<void> clearAuth() async {
    _isAuthenticated = false;
    _user = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final user = await _api.updateProfile(data);
      _user = user;
      notifyListeners();
      return true;
    } catch (e) {
      _error = friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadProfilePhoto(String filePath) async {
    try {
      final user = await _api.uploadProfilePhoto(filePath);
      _user = user;
      notifyListeners();
      return true;
    } catch (e) {
      _error = friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @visibleForTesting
  void setUserForTest(Employee user) {
    _user = user;
    _isAuthenticated = true;
    _isLoading = false;
    notifyListeners();
  }
}
