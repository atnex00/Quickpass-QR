import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/errors.dart';
import 'admin_shared.dart';
import 'widgets/admin_profile_card.dart';
import 'widgets/leave_breakdown_section.dart';
import 'widgets/overview_stat_grid.dart';
import 'widgets/quick_actions_section.dart';
import 'widgets/switch_view_section.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key, this.onSwitchTab});
  final ValueChanged<int>? onSwitchTab;

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  late final ApiService _api;
  Map<String, dynamic>? _reportData;
  List<dynamic>? _departmentReport;
  bool _isLoading = true;
  String? _error;
  Map<String, int> _cachedStatusCounts = {};
  int _employeeCount = 0;

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReports();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      _reportData = await _api.getReports();
      final deptRes = await _api.getReports(type: 'department');
      _departmentReport = deptRes['data'] as List<dynamic>?;
      _computeCounts();

      final empRes = await _api.listEmployees(limit: 1);
      final pagination = empRes['pagination'] as Map<String, dynamic>?;
      _employeeCount = int.tryParse('${pagination?['total']}') ?? 0;

      final depts = await _api.getDepartments();
      _departmentCount = depts.length;
    } catch (e) {
      _error = friendlyError(e);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _computeCounts() {
    _cachedStatusCounts = {};
    if (_reportData == null) return;
    final data = _reportData!['data'] as List? ?? [];
    for (final entry in data) {
      final s = entry['status'] as String? ?? 'unknown';
      _cachedStatusCounts[s] = (_cachedStatusCounts[s] ?? 0) + 1;
    }
  }

  int get _pendingCount => _cachedStatusCounts['pending'] ?? 0;
  int get _approvedCount => _cachedStatusCounts['approved'] ?? 0;
  int get _rejectedCount => _cachedStatusCounts['rejected'] ?? 0;
  int get _completedCount => _cachedStatusCounts['completed'] ?? 0;
  int get _activeCount => _cachedStatusCounts['active'] ?? 0;

  int _departmentCount = 0;

  Widget _buildDepartmentTable() {
    if (_departmentReport == null || _departmentReport!.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: context.neutralGray),
            const SizedBox(width: 12),
            Expanded(
              child: Text('No department data available.',
                  style: TextStyle(color: context.neutralGray)),
            ),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                  width: 24,
                  child: Text('ID',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.outline))),
              Expanded(
                  flex: 3,
                  child: Text('Department',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.outline))),
              Expanded(
                  child: Text('Total',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.outline))),
              Expanded(
                  child: Text('Pending',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.outline))),
            ],
          ),
          const SizedBox(height: 8),
          ..._departmentReport!.map((dept) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text('${dept['department_id'] ?? ''}',
                        style: TextStyle(
                            fontSize: 12, color: context.neutralGray)),
                  ),
                  Expanded(
                      flex: 3,
                      child: Text('${dept['department_name'] ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: context.onSurface))),
                  Expanded(
                      child: Text('${dept['total_requests'] ?? 0}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.onSurface))),
                  Expanded(
                      child: Text('${dept['pending'] ?? 0}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.warning))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _switchToTab(int index) {
    widget.onSwitchTab?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final userName =
        context.select((AuthProvider a) => a.user?.fullName ?? 'Admin');
    final userPhoto =
        context.select((AuthProvider a) => a.user?.profilePhoto);

    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadReports,
            child: CustomScrollView(
              slivers: [
                buildAdminAppBar(context, 'overview'),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      AdminProfileCard(
                          userName: userName,
                          photoUrl: AppConfig.photoUrl(userPhoto)),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_error != null)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(Icons.error_outline, size: 48, color: context.error),
                              const SizedBox(height: 12),
                              Text(_error!, textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 15)),
                              const SizedBox(height: 16),
                              FilledButton(onPressed: _loadReports, child: const Text('Retry')),
                            ],
                          ),
                        )
                      else ...[
                        OverviewStatGrid(
                          employeeCount: _employeeCount,
                          pendingCount: _pendingCount,
                          activeCount: _activeCount,
                          departmentCount: _departmentCount,
                        ),
                        const SizedBox(height: 24),
                        QuickActionsSection(onSwitchTab: _switchToTab),
                        const SizedBox(height: 24),
                        const SwitchViewSection(),
                        const SizedBox(height: 24),
                        LeaveBreakdownSection(
                          pendingCount: _pendingCount,
                          approvedCount: _approvedCount,
                          rejectedCount: _rejectedCount,
                          activeCount: _activeCount,
                          completedCount: _completedCount,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Department Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.onSurface,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDepartmentTable(),
                        const SizedBox(height: 24),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


