import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class ScanProvider extends ChangeNotifier {

  ScanProvider({required ApiService api}) : _api = api;
  final ApiService _api;

  Map<String, dynamic>? _lastResult;
  bool _isScanning = false;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get lastResult => _lastResult;
  bool get isScanning => _isScanning;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> validateScan(String qrData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.validateScan(qrData);
      _lastResult = result;
      _isLoading = false;
      notifyListeners();
      return result['success'] ?? false;
    } catch (e) {
      _lastResult = null;
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void setScanning(bool value) {
    _isScanning = value;
    notifyListeners();
  }

  void clearResult() {
    _lastResult = null;
    _error = null;
    notifyListeners();
  }

  void reset() {
    _lastResult = null;
    _isScanning = false;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
