import 'package:flutter/foundation.dart';
import '../models/leave_request.dart';
import '../services/api_service.dart';

class LeaveProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<LeaveRequest> _history = [];
  LeaveRequest? _activeLeave;
  bool _isLoading = false;
  String? _error;

  List<LeaveRequest> get history => _history;
  LeaveRequest? get activeLeave => _activeLeave;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get pendingCount => _history.where((l) => l.status == LeaveStatus.pending).length;
  int get approvedCount => _history.where((l) => l.status == LeaveStatus.approved).length;
  int get completedCount => _history.where((l) => l.status == LeaveStatus.completed).length;

  Future<void> loadHistory({String? status}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.getLeaveHistory(status: status);
      _history = (data['data'] as List).map((j) => LeaveRequest.fromJson(j)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadActiveLeave() async {
    try {
      _activeLeave = await _api.getActiveLeave();
    } catch (_) {
      _activeLeave = null;
    }
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

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadHistory();
    await loadActiveLeave();
  }
}
