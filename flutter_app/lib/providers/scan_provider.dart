import 'package:flutter/foundation.dart';

import '../models/scan_log.dart';
import '../services/analytics_service.dart';
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

  int _todayTotal = 0;
  int _todayValid = 0;
  int _todayInvalid = 0;
  int _todayOut = 0;
  int _todayIn = 0;
  List<ScanLog> _recentScans = [];
  bool _statsLoading = false;

  Map<String, dynamic>? get lastResult => _lastResult;
  bool get isScanning => _isScanning;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ScanLog> get history => _history;
  bool get historyLoading => _historyLoading;
  int get historyPage => _historyPage;
  int get historyTotal => _historyTotal;
  int get historyPages => _historyPages;

  int get todayTotal => _todayTotal;
  int get todayValid => _todayValid;
  int get todayInvalid => _todayInvalid;
  int get todayOut => _todayOut;
  int get todayIn => _todayIn;
  List<ScanLog> get recentScans => _recentScans;
  bool get statsLoading => _statsLoading;

  Future<bool> validateScan(String qrData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.validateScan(qrData);
      _lastResult = result;
      _isLoading = false;
      notifyListeners();
      final qrType = result['data']?['qr_type'] as String? ?? 'unknown';
      final isValid = result['success'] == true;
      AnalyticsService().logQrScan(qrType: qrType, isValid: isValid);
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

  Future<void> loadStats() async {
    _statsLoading = true;
    notifyListeners();

    try {
      final data = await _api.getScanStats();
      final stats = data['data'] as Map<String, dynamic>?;
      if (stats != null) {
        _todayTotal = stats['today_total'] as int? ?? 0;
        _todayValid = stats['today_valid'] as int? ?? 0;
        _todayInvalid = stats['today_invalid'] as int? ?? 0;
        _todayOut = stats['today_out'] as int? ?? 0;
        _todayIn = stats['today_in'] as int? ?? 0;
        final recent = stats['recent'] as List? ?? [];
        _recentScans = recent.map((j) => ScanLog.fromJson(j)).toList();
      }
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _statsLoading = false;
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
    _todayTotal = 0;
    _todayValid = 0;
    _todayInvalid = 0;
    _todayOut = 0;
    _todayIn = 0;
    _recentScans = [];
    _statsLoading = false;
    notifyListeners();
  }
}
