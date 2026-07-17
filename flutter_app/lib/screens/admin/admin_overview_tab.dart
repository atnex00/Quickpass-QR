import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/errors.dart';
import '../../utils/responsive.dart';
import '../employee/dashboard_screen.dart';
import '../security/scanner_screen.dart';
import '../supervisor/supervisor_dashboard.dart';
import 'admin_shared.dart';

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

class AdminProfileCard extends StatelessWidget {
  const AdminProfileCard({super.key, required this.userName, required this.photoUrl});
  final String userName;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor:
                photoUrl != null ? null : context.primary.withValues(alpha: 0.2),
            backgroundImage:
                photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null
                ? Text(
                    (userName.isNotEmpty ? userName[0] : 'A').toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: context.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Control',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.outline,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: context.onSurface,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: context.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Admin',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.error,
                    ),
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

class OverviewStatGrid extends StatelessWidget {

  const OverviewStatGrid({
    super.key,
    required this.employeeCount,
    required this.pendingCount,
    required this.activeCount,
    required this.departmentCount,
  });
  final int employeeCount;
  final int pendingCount;
  final int activeCount;
  final int departmentCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            AdminStatCard(
              icon: Icons.people,
              label: 'Employees',
              value: '$employeeCount',
              color: context.secondary,
            ),
            const SizedBox(width: 8),
            AdminStatCard(
              icon: Icons.pending_actions,
              label: 'Pending',
              value: '$pendingCount',
              color: context.warning,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            AdminStatCard(
              icon: Icons.verified_user,
              label: 'Active',
              value: '$activeCount',
              color: context.success,
            ),
            const SizedBox(width: 8),
            AdminStatCard(
              icon: Icons.business,
              label: 'Departments',
              value: '$departmentCount',
              color: context.primaryBlue,
            ),
          ],
        ),
      ],
    );
  }
}

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key, required this.onSwitchTab});
  final void Function(int) onSwitchTab;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: responsiveFontSize(context, 16),
            fontWeight: FontWeight.w600,
            color: context.onSurface,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AdminQuickActionCard(
                icon: Icons.people,
                title: 'Manage Employees',
                subtitle: 'CRUD operations',
                onTap: () => onSwitchTab(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdminQuickActionCard(
                icon: Icons.business,
                title: 'Departments',
                subtitle: 'Organize teams',
                onTap: () => onSwitchTab(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AdminQuickActionCard(
                icon: Icons.bar_chart,
                title: 'Reports',
                subtitle: 'View analytics',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text('Scroll down to view leave breakdown')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class SwitchViewSection extends StatelessWidget {
  const SwitchViewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Switch View',
          style: TextStyle(
            fontSize: responsiveFontSize(context, 16),
            fontWeight: FontWeight.w600,
            color: context.onSurface,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AdminQuickActionCard(
                icon: Icons.badge_outlined,
                title: 'Employee View',
                subtitle: 'Submit & track leaves',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EmployeeDashboard(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdminQuickActionCard(
                icon: Icons.rate_review_outlined,
                title: 'Supervisor View',
                subtitle: 'Approve & reject leaves',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SupervisorDashboard(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AdminQuickActionCard(
                icon: Icons.qr_code_scanner_outlined,
                title: 'Security View',
                subtitle: 'Scan QR codes at gates',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScannerScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }
}

class LeaveBreakdownSection extends StatelessWidget {

  const LeaveBreakdownSection({
    super.key,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
    required this.activeCount,
    required this.completedCount,
  });
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final int activeCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    final sections = <PieChartSectionData>[];
    final entries = [
      ('Pending', pendingCount, context.warning),
      ('Approved', approvedCount, context.primaryBlue),
      ('Rejected', rejectedCount, context.error),
      ('Active', activeCount, context.success),
      ('Completed', completedCount, context.secondary),
    ];
    for (final e in entries) {
      if (e.$2 > 0) {
        sections.add(PieChartSectionData(
          value: e.$2.toDouble(),
          title: '${e.$2}',
          color: e.$3,
          radius: 40,
          titleStyle: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
        ));
      }
    }
    if (sections.isEmpty) {
      sections.add(PieChartSectionData(
        value: 1,
        title: '0',
        color: context.neutralGray.withValues(alpha: 0.3),
        radius: 40,
        titleStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: context.neutralGray),
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Leave Breakdown',
          style: TextStyle(
            fontSize: responsiveFontSize(context, 16),
            fontWeight: FontWeight.w600,
            color: context.onSurface,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.outlineVariant),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 180,
                child: PieChart(
                    PieChartData(sections: sections, centerSpaceRadius: 30)),
              ),
              const SizedBox(height: 16),
              AdminStatusLegend(
                  label: 'Pending',
                  count: pendingCount,
                  color: context.warning),
              const SizedBox(height: 4),
              AdminStatusLegend(
                  label: 'Approved',
                  count: approvedCount,
                  color: context.primaryBlue),
              const SizedBox(height: 4),
              AdminStatusLegend(
                  label: 'Rejected',
                  count: rejectedCount,
                  color: context.error),
              const SizedBox(height: 4),
              AdminStatusLegend(
                  label: 'Active', count: activeCount, color: context.success),
              const SizedBox(height: 4),
              AdminStatusLegend(
                  label: 'Completed',
                  count: completedCount,
                  color: context.secondary),
            ],
          ),
        ),
      ],
    );
  }
}
