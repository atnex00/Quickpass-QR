import 'package:flutter/foundation.dart';

import '../models/leave_request.dart';
import '../services/analytics_service.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../utils/errors.dart';

class LeaveProvider extends ChangeNotifier {

  LeaveProvider({required ApiService api}) : _api = api;
  final ApiService _api;

  List<LeaveRequest> _history = [];
  LeaveRequest? _activeLeave;
  bool _isLoading = false;
  bool _fromCache = false;
  String? _error;
  int _pendingCount = 0;
  int _approvedCount = 0;
  int _completedCount = 0;
  int _historyPage = 1;
  int _historyTotal = 0;
  int _historyPages = 1;

  List<LeaveRequest> get history => _history;
  LeaveRequest? get activeLeave => _activeLeave;
  bool get isLoading => _isLoading;
  bool get fromCache => _fromCache;
  String? get error => _error;
  int get pendingCount => _pendingCount;
  int get approvedCount => _approvedCount;
  int get completedCount => _completedCount;
  int get historyPage => _historyPage;
  int get historyTotal => _historyTotal;
  int get historyPages => _historyPages;

  void _recomputeCounts() {
    _pendingCount = 0;
    _approvedCount = 0;
    _completedCount = 0;
    for (final l in _history) {
      if (l.status == LeaveStatus.pending) {
        _pendingCount++;
      } else if (l.status == LeaveStatus.approved) {
        _approvedCount++;
      } else if (l.status == LeaveStatus.completed) {
        _completedCount++;
      }
    }
  }

  Future<void> loadHistory({String? status, int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.getLeaveHistory(status: status, page: page);
      final list = data['data'] as List? ?? [];
      _history = list.map((j) => LeaveRequest.fromJson(j)).toList();
      final p = data['pagination'] as Map<String, dynamic>?;
      _historyTotal = int.tryParse('${p?['total']}') ?? _history.length;
      _historyPage = int.tryParse('${p?['page']}') ?? page;
      _historyPages = int.tryParse('${p?['pages']}') ?? 1;
      _recomputeCounts();
      _fromCache = false;
      CacheService().saveLeaves(_history);
    } catch (e) {
      _error = friendlyError(e);
      final cached = await CacheService().loadLeaves();
      if (cached != null && cached.isNotEmpty) {
        _history = cached;
        _recomputeCounts();
        _fromCache = true;
        _error = null;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadActiveLeave() async {
    _isLoading = true;
    notifyListeners();

    try {
      _activeLeave = await _api.getActiveLeave();
      _error = null;
      _fromCache = false;
      CacheService().saveActiveLeave(_activeLeave);
    } catch (e) {
      _error = friendlyError(e);
      final cached = await CacheService().loadActiveLeave();
      if (cached != null) {
        _activeLeave = cached;
        _fromCache = true;
        _error = null;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<LeaveRequest?> submitLeave({
    required String leaveDate,
    required String startTime,
    required String endTime,
    required String reason,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final leave = await _api.submitLeave(
        leaveDate: leaveDate,
        startTime: startTime,
        endTime: endTime,
        reason: reason,
      );
      _history = [leave, ..._history];
      _recomputeCounts();
      _isLoading = false;
      _fromCache = false;
      CacheService().saveLeaves(_history);
      notifyListeners();
      AnalyticsService().logLeaveSubmitted();
      return leave;
    } catch (e) {
      _error = friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> cancelLeave(String leaveId) async {
    await _api.cancelLeave(leaveId);
    _history.removeWhere((l) => l.leaveId == leaveId);
    if (_activeLeave?.leaveId == leaveId) _activeLeave = null;
    _recomputeCounts();
    CacheService().saveLeaves(_history);
    CacheService().saveActiveLeave(_activeLeave);
    notifyListeners();
  }

  Future<void> deleteLeave(String leaveId) async {
    await _api.deleteLeave(leaveId);
    _history.removeWhere((l) => l.leaveId == leaveId);
    _recomputeCounts();
    CacheService().saveLeaves(_history);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    await Future.wait([loadHistory(), loadActiveLeave()]);
  }

  void reset() {
    _history = [];
    _activeLeave = null;
    _isLoading = false;
    _error = null;
    _pendingCount = 0;
    _approvedCount = 0;
    _completedCount = 0;
    _historyPage = 1;
    _historyTotal = 0;
    _historyPages = 1;
    notifyListeners();
  }
}
