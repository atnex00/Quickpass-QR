import 'package:flutter/foundation.dart';
import '../models/employee.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

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
      }
    } catch (_) {
      await _api.logout();
    }

    _isLoading = false;
    _isInitializing = false;
    notifyListeners();
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
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isAuthenticated = false;
      _loginLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _user = null;
    _error = null;
    notifyListeners();
    _api.logout();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final user = await _api.updateProfile(data);
      _user = user;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
