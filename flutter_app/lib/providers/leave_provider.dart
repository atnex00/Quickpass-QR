import 'package:flutter/foundation.dart';
import '../models/leave_request.dart';
import '../services/api_service.dart';

class LeaveProvider extends ChangeNotifier {
  final ApiService _api;

  LeaveProvider({required ApiService api}) : _api = api;

  List<LeaveRequest> _history = [];
  LeaveRequest? _activeLeave;
  bool _isLoading = false;
  String? _error;
  int _pendingCount = 0;
  int _approvedCount = 0;
  int _completedCount = 0;

  List<LeaveRequest> get history => _history;
  LeaveRequest? get activeLeave => _activeLeave;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get pendingCount => _pendingCount;
  int get approvedCount => _approvedCount;
  int get completedCount => _completedCount;

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

  Future<void> loadHistory({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.getLeaveHistory(status: status);
      final list = data['data'] as List? ?? [];
      _history = list.map((j) => LeaveRequest.fromJson(j)).toList();
      _recomputeCounts();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
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
    } catch (e) {
      _activeLeave = null;
      _error = e.toString().replaceFirst('Exception: ', '');
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
      notifyListeners();
      return leave;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteLeave(String leaveId) async {
    try {
      await _api.deleteLeave(leaveId);
      _history.removeWhere((l) => l.leaveId == leaveId);
      _recomputeCounts();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    await Future.wait([loadHistory(), loadActiveLeave()]);
  }
}
