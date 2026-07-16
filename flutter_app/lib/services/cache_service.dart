import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/leave_request.dart';

class CacheService {
  factory CacheService() => _instance;
  CacheService._();
  static final CacheService _instance = CacheService._();

  static const _keyLeaves = 'cache_leaves';
  static const _keyActiveLeave = 'cache_active_leave';
  static const _keyPending = 'cache_pending';
  static const _keyApproved = 'cache_approved';
  static const _keyProfile = 'cache_profile';

  // ── Leave History ──
  Future<void> saveLeaves(List<LeaveRequest> leaves) async {
    final data = leaves.map((l) => l.toJson()).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLeaves, jsonEncode(data));
  }

  Future<List<LeaveRequest>?> loadLeaves() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyLeaves);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List;
    return list.map((j) => LeaveRequest.fromJson(j)).toList();
  }

  // ── Active Leave ──
  Future<void> saveActiveLeave(LeaveRequest? leave) async {
    final prefs = await SharedPreferences.getInstance();
    if (leave == null) {
      await prefs.remove(_keyActiveLeave);
    } else {
      await prefs.setString(_keyActiveLeave, jsonEncode(leave.toJson()));
    }
  }

  Future<LeaveRequest?> loadActiveLeave() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyActiveLeave);
    if (raw == null) return null;
    return LeaveRequest.fromJson(jsonDecode(raw));
  }

  // ── Supervisor Pending ──
  Future<void> savePendingRequests(List<LeaveRequest> leaves) async {
    final data = leaves.map((l) => l.toJson()).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPending, jsonEncode(data));
  }

  Future<List<LeaveRequest>?> loadPendingRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPending);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List;
    return list.map((j) => LeaveRequest.fromJson(j)).toList();
  }

  // ── Supervisor Approved ──
  Future<void> saveApprovedLeaves(List<LeaveRequest> leaves) async {
    final data = leaves.map((l) => l.toJson()).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApproved, jsonEncode(data));
  }

  Future<List<LeaveRequest>?> loadApprovedLeaves() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyApproved);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List;
    return list.map((j) => LeaveRequest.fromJson(j)).toList();
  }

  // ── Profile ──
  Future<void> saveProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfile, jsonEncode(profile));
  }

  Future<Map<String, dynamic>?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyProfile);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ── Clear ──
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLeaves);
    await prefs.remove(_keyActiveLeave);
    await prefs.remove(_keyPending);
    await prefs.remove(_keyApproved);
    await prefs.remove(_keyProfile);
  }
}
