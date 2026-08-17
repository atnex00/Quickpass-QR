import 'package:flutter/foundation.dart';

import '../models/employee.dart';
import '../models/leave_request.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../utils/errors.dart';

class DirectoryProvider extends ChangeNotifier {
  DirectoryProvider({required ApiService api}) : _api = api;
  final ApiService _api;

  List<Employee> _team = [];
  List<Employee> _directory = [];
  final Map<String, List<LeaveRequest>> _teamLeaves = {};
  int _loadingCount = 0;
  bool _fromCache = false;
  String? _error;

  List<Employee> get team => _team;
  List<Employee> get directory => _directory;
  bool get isLoading => _loadingCount > 0;
  bool get fromCache => _fromCache;
  String? get error => _error;

  List<LeaveRequest>? teamLeavesOf(String employeeId) => _teamLeaves[employeeId];

  Future<void> loadTeam() async {
    _loadingCount++;
    notifyListeners();

    try {
      _team = await _api.getMyTeam();
      _error = null;
      _fromCache = false;
      CacheService().saveTeam(_team);
    } catch (e) {
      _error = friendlyError(e);
      final cached = await CacheService().loadTeam();
      if (cached != null && cached.isNotEmpty) {
        _team = cached;
        _fromCache = true;
        _error = null;
      }
    } finally {
      _loadingCount--;
      notifyListeners();
    }
  }

  Future<void> loadDirectory() async {
    _loadingCount++;
    notifyListeners();

    try {
      _directory = await _api.getDirectory();
      _error = null;
      _fromCache = false;
      CacheService().saveDirectory(_directory);
    } catch (e) {
      _error = friendlyError(e);
      final cached = await CacheService().loadDirectory();
      if (cached != null && cached.isNotEmpty) {
        _directory = cached;
        _fromCache = true;
        _error = null;
      }
    } finally {
      _loadingCount--;
      notifyListeners();
    }
  }

  Future<void> loadTeamMemberLeaves(String employeeId) async {
    try {
      _teamLeaves[employeeId] = await _api.getTeamMemberLeaves(employeeId);
      CacheService().saveTeamLeaves(employeeId, _teamLeaves[employeeId]!);
    } catch (e) {
      final cached = await CacheService().loadTeamLeaves(employeeId);
      if (cached != null) {
        _teamLeaves[employeeId] = cached;
      } else {
        _teamLeaves[employeeId] = [];
      }
    }
    notifyListeners();
  }

  void reset() {
    _team = [];
    _directory = [];
    _teamLeaves.clear();
    _loadingCount = 0;
    _fromCache = false;
    _error = null;
    notifyListeners();
  }
}