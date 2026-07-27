import 'package:flutter/foundation.dart';

import '../models/scan_log.dart';
import '../services/api_service.dart';
import '../utils/errors.dart';

class ScanProvider extends ChangeNotifier {

  ScanProvider({required ApiService api}) : _api = api;
  final ApiService _api;

  Map<String, dynamic>? _lastResult;
  bool _isScanning = false;
  bool _isLoading = false;
  String? _error;
  List<ScanLog> _history = [];
  bool _historyLoading = false;
  int _historyPage = 1;
  int _historyTotal = 0;
  int _historyPages = 1;

  Map<String, dynamic>? get lastResult => _lastResult;
  bool get isScanning => _isScanning;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ScanLog> get history => _history;
  bool get historyLoading => _historyLoading;
  int get historyPage => _historyPage;
  int get historyTotal => _historyTotal;
  int get historyPages => _historyPages;

  Future<bool> validateScan(String qrData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.validateScan(qrData);
      _lastResult = result;
      _isLoading = false;
      notifyListeners();
      return isValid;
    } catch (e) {
      _lastResult = null;
      _error = friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadHistory({int page = 1}) async {
    _historyLoading = true;
    notifyListeners();

    try {
      final data = await _api.getScanHistory(page: page);
      _history = (data['data'] as List?)?.map((j) => ScanLog.fromJson(j)).toList() ?? [];
      final p = data['pagination'] as Map<String, dynamic>?;
      _historyTotal = int.tryParse('${p?['total']}') ?? _history.length;
      _historyPage = int.tryParse('${p?['page']}') ?? page;
      _historyPages = int.tryParse('${p?['pages']}') ?? 1;
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _historyLoading = false;
    notifyListeners();
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
    _history = [];
    _historyLoading = false;
    _historyPage = 1;
    _historyTotal = 0;
    _historyPages = 1;
    notifyListeners();
  }
}
