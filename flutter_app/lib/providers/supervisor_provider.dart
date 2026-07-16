import 'package:flutter/foundation.dart';

import '../models/leave_request.dart';
import '../services/analytics_service.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../utils/errors.dart';

class SupervisorProvider extends ChangeNotifier {

  SupervisorProvider({required ApiService api}) : _api = api;
  final ApiService _api;

  List<LeaveRequest> _pendingRequests = [];
  List<LeaveRequest> _approvedLeaves = [];
  int _loadingCount = 0;
  bool _fromCache = false;
  String? _error;

  List<LeaveRequest> get pendingRequests => _pendingRequests;
  List<LeaveRequest> get approvedLeaves => _approvedLeaves;
  bool get isLoading => _loadingCount > 0;
  bool get fromCache => _fromCache;
  String? get error => _error;
  int get pendingCount => _pendingRequests.length;

  Future<void> loadPendingRequests() async {
    _loadingCount++;
    notifyListeners();

    try {
      _pendingRequests = await _api.getPendingRequests();
      _error = null;
      _fromCache = false;
      CacheService().savePendingRequests(_pendingRequests);
    } catch (e) {
      _error = friendlyError(e);
      final cached = await CacheService().loadPendingRequests();
      if (cached != null && cached.isNotEmpty) {
        _pendingRequests = cached;
        _fromCache = true;
        _error = null;
      }
    } finally {
      _loadingCount--;
      notifyListeners();
    }
  }

  Future<LeaveRequest?> approveLeave(String leaveId) async {
    try {
      final leave = await _api.approveLeave(leaveId);
      _pendingRequests.removeWhere((l) => l.leaveId == leaveId);
      _approvedLeaves.insert(0, leave);
      notifyListeners();
      AnalyticsService().logLeaveApproved();
      return leave;
    } catch (e) {
      _error = friendlyError(e);
      notifyListeners();
      return null;
    }
  }

  Future<void> loadApprovedLeaves() async {
    _loadingCount++;
    notifyListeners();

    try {
      _approvedLeaves = await _api.getApprovedLeaves();
      _error = null;
      _fromCache = false;
      CacheService().saveApprovedLeaves(_approvedLeaves);
    } catch (e) {
      _error = friendlyError(e);
      final cached = await CacheService().loadApprovedLeaves();
      if (cached != null && cached.isNotEmpty) {
        _approvedLeaves = cached;
        _fromCache = true;
        _error = null;
      }
    } finally {
      _loadingCount--;
      notifyListeners();
    }
  }

  Future<LeaveRequest?> revokeApproval(String leaveId) async {
    try {
      final leave = await _api.revokeApproval(leaveId);
      _approvedLeaves.removeWhere((l) => l.leaveId == leaveId);
      _pendingRequests.insert(0, leave);
      notifyListeners();
      AnalyticsService().logLeaveRevoked();
      return leave;
    } catch (e) {
      _error = friendlyError(e);
      notifyListeners();
      return null;
    }
  }

  Future<LeaveRequest?> rejectLeave(String leaveId, String reason) async {
    try {
      final leave = await _api.rejectLeave(leaveId, reason);
      _pendingRequests.removeWhere((l) => l.leaveId == leaveId);
      notifyListeners();
      AnalyticsService().logLeaveRejected();
      return leave;
    } catch (e) {
      _error = friendlyError(e);
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _pendingRequests = [];
    _approvedLeaves = [];
    _loadingCount = 0;
    _error = null;
    notifyListeners();
  }
}
