import 'package:flutter/foundation.dart';
import '../models/employee.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _api = ApiService();
  Employee? _user;
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String? _error;

  Employee? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  bool get isSupervisor => _user?.isSupervisor ?? false;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    final token = await _api.getStoredToken();
    if (token != null) {
      try {
        final user = await _api.getProfile();
        _user = user;
        _isAuthenticated = true;
      } catch (_) {
        await _api.logout();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String employeeId, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.login(employeeId, password);
      _user = Employee.fromJson(data['user']);
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _api.logout();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
