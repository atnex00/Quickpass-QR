import 'package:flutter/foundation.dart';
import '../models/leave_request.dart';
import '../services/api_service.dart';

class SupervisorProvider extends ChangeNotifier {
  final ApiService _api;

  SupervisorProvider({ApiService? api}) : _api = api ?? ApiService();

  List<LeaveRequest> _pendingRequests = [];
  List<LeaveRequest> _approvedLeaves = [];
  bool _isLoading = false;
  String? _error;

  List<LeaveRequest> get pendingRequests => _pendingRequests;
  List<LeaveRequest> get approvedLeaves => _approvedLeaves;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get pendingCount => _pendingRequests.length;

  Future<void> loadPendingRequests() async {
    _isLoading = true;
    notifyListeners();

    try {
      _pendingRequests = await _api.getPendingRequests();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<LeaveRequest?> approveLeave(String leaveId) async {
    try {
      final leave = await _api.approveLeave(leaveId);
      _pendingRequests.removeWhere((l) => l.leaveId == leaveId);
      _approvedLeaves.insert(0, leave);
      notifyListeners();
      return leave;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<void> loadApprovedLeaves() async {
    try {
      _approvedLeaves = await _api.getApprovedLeaves();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<LeaveRequest?> revokeApproval(String leaveId) async {
    try {
      final leave = await _api.revokeApproval(leaveId);
      _approvedLeaves.removeWhere((l) => l.leaveId == leaveId);
      notifyListeners();
      return leave;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<LeaveRequest?> rejectLeave(String leaveId, String reason) async {
    try {
      final leave = await _api.rejectLeave(leaveId, reason);
      _pendingRequests.removeWhere((l) => l.leaveId == leaveId);
      notifyListeners();
      return leave;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
