import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../models/department.dart';
import '../../providers/auth_provider.dart';
import '../../providers/supervisor_provider.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';
import '../../utils/debounce.dart';
import '../../widgets/adaptive_scaffold.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/loading_indicator.dart';
import 'employee_detail_screen.dart';
import '../employee/dashboard_screen.dart';
import '../supervisor/supervisor_dashboard.dart';
import '../security/scanner_screen.dart';
import '../shared/settings_screen.dart';

Widget _buildAdminAppBar(BuildContext context, String tabKey) {
  return SliverAppBar(
      key: ValueKey(tabKey),
      pinned: true,
      toolbarHeight: 64,
      automaticallyImplyLeading: false,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.onPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset('assets/icon/app-icon.png',
                        width: 22, height: 22),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quickpass',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: context.onPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.notifications_outlined,
                        color: context.onPrimary),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text('No new notifications')),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: context.onPrimary),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ));
}

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      selectedIndex: _currentIndex,
      onDestinationSelected: (i) => setState(() => _currentIndex = i),
      destinations: const [
        AdaptiveDestination(
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          label: 'Overview',
        ),
        AdaptiveDestination(
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          label: 'Employees',
        ),
        AdaptiveDestination(
          icon: Icons.business_outlined,
          selectedIcon: Icons.business,
          label: 'Departments',
        ),
        AdaptiveDestination(
          icon: Icons.bar_chart_outlined,
          selectedIcon: Icons.bar_chart,
          label: 'Reports',
        ),
        AdaptiveDestination(
          icon: Icons.event_note_outlined,
          selectedIcon: Icons.event_note,
          label: 'Leaves',
        ),
      ],
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _OverviewTab(onSwitchTab: (i) => setState(() => _currentIndex = i)),
            const _EmployeeTab(),
            const _DepartmentTab(),
            const _ReportsTab(),
            const _LeaveTab(),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;
  const _OverviewTab({this.onSwitchTab});

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  late final ApiService _api;
  Map<String, dynamic>? _reportData;
  List<dynamic>? _departmentReport;
  bool _isLoading = true;
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
    setState(() => _isLoading = true);
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
      debugPrint('Failed to load overview reports: $e');
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
                  flex: 1,
                  child: Text('Total',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.outline))),
              Expanded(
                  flex: 1,
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
                      flex: 1,
                      child: Text('${dept['total_requests'] ?? 0}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.onSurface))),
                  Expanded(
                      flex: 1,
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
                _buildAdminAppBar(context, 'overview'),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _AdminProfileCard(
                          userName: userName,
                          photoUrl: AppConfig.photoUrl(userPhoto)),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else ...[
                        _OverviewStatGrid(
                          employeeCount: _employeeCount,
                          pendingCount: _pendingCount,
                          activeCount: _activeCount,
                          departmentCount: _departmentCount,
                        ),
                        const SizedBox(height: 24),
                        _QuickActionsSection(onSwitchTab: _switchToTab),
                        const SizedBox(height: 24),
                        const _SwitchViewSection(),
                        const SizedBox(height: 24),
                        _LeaveBreakdownSection(
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

class _AdminProfileCard extends StatelessWidget {
  final String userName;
  final String? photoUrl;
  const _AdminProfileCard({required this.userName, required this.photoUrl});

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

class _OverviewStatGrid extends StatelessWidget {
  final int employeeCount;
  final int pendingCount;
  final int activeCount;
  final int departmentCount;

  const _OverviewStatGrid({
    required this.employeeCount,
    required this.pendingCount,
    required this.activeCount,
    required this.departmentCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _StatCard(
              icon: Icons.people,
              label: 'Employees',
              value: '$employeeCount',
              color: context.secondary,
            ),
            const SizedBox(width: 8),
            _StatCard(
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
            _StatCard(
              icon: Icons.verified_user,
              label: 'Active',
              value: '$activeCount',
              color: context.success,
            ),
            const SizedBox(width: 8),
            _StatCard(
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

class _QuickActionsSection extends StatelessWidget {
  final void Function(int) onSwitchTab;
  const _QuickActionsSection({required this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.onSurface,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.people,
                title: 'Manage Employees',
                subtitle: 'CRUD operations',
                onTap: () => onSwitchTab(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
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
              child: _QuickActionCard(
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
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.settings,
                title: 'Settings',
                subtitle: 'Configuration',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text('Settings coming soon')),
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

class _SwitchViewSection extends StatelessWidget {
  const _SwitchViewSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Switch View',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.onSurface,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
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
              child: _QuickActionCard(
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
              child: _QuickActionCard(
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

class _LeaveBreakdownSection extends StatelessWidget {
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final int activeCount;
  final int completedCount;

  const _LeaveBreakdownSection({
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
    required this.activeCount,
    required this.completedCount,
  });

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
            fontSize: 16,
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
              _StatusLegend(
                  label: 'Pending',
                  count: pendingCount,
                  color: context.warning),
              const SizedBox(height: 4),
              _StatusLegend(
                  label: 'Approved',
                  count: approvedCount,
                  color: context.primaryBlue),
              const SizedBox(height: 4),
              _StatusLegend(
                  label: 'Rejected',
                  count: rejectedCount,
                  color: context.error),
              const SizedBox(height: 4),
              _StatusLegend(
                  label: 'Active', count: activeCount, color: context.success),
              const SizedBox(height: 4),
              _StatusLegend(
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

class _EmployeeTab extends StatefulWidget {
  const _EmployeeTab();

  @override
  State<_EmployeeTab> createState() => _EmployeeTabState();
}

class _EmployeeTabState extends State<_EmployeeTab> {
  late final ApiService _api;
  final Debouncer _searchDebouncer =
      Debouncer(delay: const Duration(milliseconds: 300));
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _departments = [];
  late final TextEditingController _searchCtl;
  bool _isLoading = true;
  bool _loadingError = false;

  String _searchQuery = '';
  String? _filterDepartment;
  String _filterStatus = '';
  String _filterRole = '';
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalEmployees = 0;

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiService>();
    _searchCtl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  static String? _empPhoto(Map<String, dynamic> emp) =>
      AppConfig.photoUrl(emp['profile_photo'] as String?);

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadingError = false;
    });
    try {
      final empRes = await _api.listEmployees(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        departmentId: _filterDepartment,
        status: _filterStatus.isNotEmpty ? _filterStatus : null,
        role: _filterRole.isNotEmpty ? _filterRole : null,
        page: _currentPage,
      );
      if (empRes['success']) {
        _employees = List<Map<String, dynamic>>.from(empRes['data'] ?? []);
        final pagination = empRes['pagination'] as Map<String, dynamic>?;
        _totalPages = int.tryParse('${pagination?['pages']}') ?? 1;
        _totalEmployees =
            int.tryParse('${pagination?['total']}') ?? _employees.length;
      }
      final deps = await _api.getDepartments();
      _departments = List<Map<String, dynamic>>.from(deps);
    } catch (e) {
      _loadingError = true;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _onSearchChanged(String v) {
    _searchQuery = v;
    _currentPage = 1;
    _searchDebouncer(() => _loadData());
  }

  void _showAddDialog() {
    showDialog<bool>(
      context: context,
      builder: (_) => _AddEmployeeDialog(departments: _departments),
    ).then((created) {
      if (created == true) _loadData();
    });
  }

  void _showEditDialog(Map<String, dynamic> emp) {
    _loadData().then((_) {
      if (!mounted) return;
      showDialog<bool>(
        context: context,
        builder: (_) =>
            _EditEmployeeDialog(emp: emp, departments: _departments),
      ).then((updated) {
        if (updated == true) if (mounted) _loadData();
      });
    });
  }

  void _showImportDialog() {
    showDialog<bool>(
      context: context,
      builder: (_) => const _ImportEmployeesDialog(),
    ).then((imported) {
      if (imported == true) _loadData();
    });
  }

  void _showPasswordResetDialog(Map<String, dynamic> emp) {
    showDialog<bool>(
      context: context,
      builder: (_) => _ResetPasswordDialog(emp: emp),
    );
  }

  void _confirmDelete(Map<String, dynamic> emp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Remove ${emp['full_name']}? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: ctx.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _api.deleteEmployee(emp['employee_id'] as String);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${emp['full_name']} deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final slivers = <Widget>[
      _buildAdminAppBar(context, 'employees'),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            // ── Search Bar ──
            TextField(
              controller: _searchCtl,
              decoration: const InputDecoration(
                hintText: 'Search by name, ID or position...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _showImportDialog,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Import HR Data'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.primary,
                    side: BorderSide(color: context.primary),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // ── Filter Row ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    width: 280,
                    child: DropdownButtonFormField<String>(
                      initialValue: _filterDepartment,
                      decoration: const InputDecoration(
                        labelText: 'Dept',
                        isDense: false,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                            value: null, child: Text('All')),
                        ..._departments.map((d) => DropdownMenuItem<String>(
                              value: d['department_id'] as String?,
                              child: Text(d['department_name'] as String? ?? '',
                                  overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _filterDepartment = v;
                          _currentPage = 1;
                        });
                        _loadData();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 280,
                    child: DropdownButtonFormField<String>(
                      initialValue:
                          _filterStatus.isEmpty ? null : _filterStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        isDense: false,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem<String>(
                            value: null, child: Text('All')),
                        DropdownMenuItem<String>(
                            value: 'active', child: Text('Active')),
                        DropdownMenuItem<String>(
                            value: 'inactive', child: Text('Inactive')),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _filterStatus = v ?? '';
                          _currentPage = 1;
                        });
                        _loadData();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 280,
                    child: DropdownButtonFormField<String>(
                      initialValue: _filterRole.isEmpty ? null : _filterRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        isDense: false,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem<String>(
                            value: null, child: Text('All')),
                        DropdownMenuItem<String>(
                            value: 'admin', child: Text('Admin')),
                        DropdownMenuItem<String>(
                            value: 'supervisor', child: Text('Supervisor')),
                        DropdownMenuItem<String>(
                            value: 'security', child: Text('Security')),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _filterRole = v ?? '';
                          _currentPage = 1;
                        });
                        _loadData();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Employee count ──
            if (_employees.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '$_totalEmployees employee${_totalEmployees == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 12, color: context.neutralGray),
                ),
              ),
            // ── Error / Loading / Empty states ──
            if (_loadingError)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.outlineVariant),
                ),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: context.error),
                    const SizedBox(height: 12),
                    const Text('Failed to load employees',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loadData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_isLoading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ))
            else if (_employees.isEmpty)
              const EmptyState(
                icon: Icons.people_outline,
                title: 'No employees found',
                subtitle: 'Try adjusting your search or filters',
              )
          ]),
        ),
      ),
    ];

    // ── Dynamic employee list (lazy-built) ──
    if (!_loadingError && !_isLoading && _employees.isNotEmpty) {
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _buildEmployeeItem(ctx, _employees[i]),
              childCount: _employees.length,
            ),
          ),
        ),
      );
    }

    // ── Pagination ──
    if (_employees.isNotEmpty && _totalPages > 1) {
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildPagination(context),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadData,
            child: CustomScrollView(slivers: slivers),
          ),
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              onPressed: _showAddDialog,
              backgroundColor: context.primary,
              foregroundColor: context.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeItem(BuildContext context, Map<String, dynamic> emp) {
    final isActive = emp['is_active'] != false;
    final badges = <Widget>[];
    if (emp['is_admin'] == true) {
      badges.add(_RoleBadge(label: 'Admin', color: context.error));
    }
    if (emp['is_supervisor'] == true) {
      badges.add(_RoleBadge(label: 'Supervisor', color: context.tertiary));
    }
    if (emp['is_security'] == true) {
      badges.add(_RoleBadge(label: 'Security', color: context.warning));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color:
            isActive ? context.surfaceContainerLowest : context.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? context.outlineVariant
              : context.error.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => EmployeeDetailScreen(employee: emp)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _empPhoto(emp) == null
                          ? (isActive
                              ? context.primary.withValues(alpha: 0.2)
                              : context.outlineVariant.withValues(alpha: 0.3))
                          : null,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: _empPhoto(emp) != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: Image.network(_empPhoto(emp)!,
                                fit: BoxFit.cover),
                          )
                        : Center(
                            child: Text(
                              (emp['full_name'] as String?)?[0] ?? '?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? context.primary
                                    : context.neutralGray,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                emp['full_name'] ?? '',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isActive
                                      ? context.onSurface
                                      : context.neutralGray,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => _showEditDialog(emp),
                              child: Icon(Icons.edit,
                                  size: 16, color: context.neutralGray),
                            ),
                            if (!isActive) ...[
                              const SizedBox(width: 6),
                              Text('inactive',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: context.error,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${emp['employee_id']} | ${emp['position'] ?? ''}',
                          style:
                              TextStyle(fontSize: 12, color: context.outline),
                        ),
                        if (badges.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(children: badges),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: context.error,
                    onPressed: () => _confirmDelete(emp),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              const Divider(height: 12),
              Row(
                children: [
                  _ActionButton(
                    icon: Icons.admin_panel_settings,
                    label: 'Admin',
                    active: emp['is_admin'] == true,
                    color: context.error,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await _api.toggleAdmin(emp['employee_id']);
                        if (!mounted) return;
                        _loadData();
                        messenger.showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Admin ${emp['is_admin'] == true ? 'removed' : 'granted'}')),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Failed to toggle admin: $e')),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  _ActionButton(
                    icon: Icons.supervisor_account,
                    label: 'Supervisor',
                    active: emp['is_supervisor'] == true,
                    color: context.tertiary,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await _api.toggleSupervisor(emp['employee_id']);
                        if (!mounted) return;
                        _loadData();
                        messenger.showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Supervisor ${emp['is_supervisor'] == true ? 'removed' : 'granted'}')),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                              content: Text('Failed to toggle supervisor: $e')),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  _ActionButton(
                    icon: Icons.check_circle_outline,
                    label: emp['is_active'] != false ? 'Active' : 'Inactive',
                    active: emp['is_active'] != false,
                    color: emp['is_active'] != false
                        ? context.success
                        : context.error,
                    onTap: () async {
                      try {
                        await _api.toggleActive(emp['employee_id']);
                        _loadData();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Failed to toggle status: $e')),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  _ActionButton(
                    icon: Icons.key,
                    label: 'Password',
                    active: false,
                    color: context.warning,
                    onTap: () => _showPasswordResetDialog(emp),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagination(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FilledButton.icon(
            onPressed: _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _loadData();
                  }
                : null,
            icon: const Icon(Icons.chevron_left, size: 18),
            label: const Text('Prev'),
            style: FilledButton.styleFrom(
              backgroundColor: context.primary,
              foregroundColor: context.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Page $_currentPage of $_totalPages',
              style: TextStyle(fontSize: 13, color: context.onSurfaceVariant),
            ),
          ),
          FilledButton.icon(
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() => _currentPage++);
                    _loadData();
                  }
                : null,
            icon: const Icon(Icons.chevron_right, size: 18),
            label: const Text('Next'),
            style: FilledButton.styleFrom(
              backgroundColor: context.primary,
              foregroundColor: context.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLegend extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatusLegend(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 13, color: context.neutralGray))),
        Text('$count',
            style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13, color: color)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.active,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: color.withValues(alpha: active ? 0.4 : 0.15)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: active ? color : context.neutralGray),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: active ? color : context.neutralGray),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportsTab extends StatefulWidget {
  const _ReportsTab();

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  late final ApiService _api;
  List<dynamic>? _reportData;
  List<dynamic>? _departmentReport;
  bool _isLoading = true;
  String _reportType = '';
  DateTime? _startDate;
  DateTime? _endDate;
  final _startCtl = TextEditingController();
  final _endCtl = TextEditingController();
  List<BarChartGroupData>? _cachedBarGroups;

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
    _startCtl.dispose();
    _endCtl.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final params = <String, dynamic>{};
      if (_reportType.isNotEmpty) params['type'] = _reportType;
      if (_startDate != null)
        params['start_date'] = DateFormatter.formatDateApi(_startDate!);
      if (_endDate != null)
        params['end_date'] = DateFormatter.formatDateApi(_endDate!);
      _reportData = (await _api.getReports(
          type: params['type'],
          startDate: params['start_date'],
          endDate: params['end_date']))['data'] as List?;
      final deptRes = await _api.getReports(type: 'department');
      _departmentReport = deptRes['data'] as List<dynamic>?;
      _computeCounts();
    } catch (e) {
      debugPrint('Failed to load report data: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _computeCounts() {
    _statusCounts = {};
    _cachedBarGroups = null;
    if (_reportData == null) return;
    for (final entry in _reportData!) {
      final s = entry['status'] as String? ?? 'unknown';
      _statusCounts[s] = (_statusCounts[s] ?? 0) + 1;
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          _startCtl.text = DateFormatter.formatDateApi(picked);
        } else {
          _endDate = picked;
          _endCtl.text = DateFormatter.formatDateApi(picked);
        }
      });
      _loadReports();
    }
  }

  Map<String, int> _statusCounts = {};

  double get _maxDeptCount {
    if (_departmentReport == null || _departmentReport!.isEmpty) return 10;
    double max = 0;
    for (final d in _departmentReport!) {
      for (final key in ['pending', 'approved', 'rejected', 'completed']) {
        final val = num.tryParse('${d[key]}')?.toDouble() ?? 0;
        if (val > max) max = val;
      }
    }
    return max < 10 ? 10 : max;
  }

  List<BarChartGroupData> _buildBarGroups() {
    if (_cachedBarGroups != null) return _cachedBarGroups!;
    if (_departmentReport == null) return [];
    _cachedBarGroups = List.generate(_departmentReport!.length, (i) {
      final d = _departmentReport![i];
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: num.tryParse('${d['pending']}')?.toDouble() ?? 0,
            color: context.warning,
            width: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: num.tryParse('${d['approved']}')?.toDouble() ?? 0,
            color: context.primaryBlue,
            width: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: num.tryParse('${d['rejected']}')?.toDouble() ?? 0,
            color: context.error,
            width: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: num.tryParse('${d['completed']}')?.toDouble() ?? 0,
            color: context.success,
            width: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        barsSpace: 3,
      );
    });
    return _cachedBarGroups!;
  }

  Widget _buildDepartmentBarChart() {
    if (_departmentReport == null || _departmentReport!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Department Overview',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.onSurface,
                  height: 1.5)),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _maxDeptCount * 1.3,
                groupsSpace: 16,
                barGroups: _buildBarGroups(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: context.outlineVariant.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 ||
                            idx >= (_departmentReport?.length ?? 0)) {
                          return const SizedBox.shrink();
                        }
                        final dept = _departmentReport![idx];
                        final code = dept['department_code'] as String? ??
                            dept['department_name'] as String? ??
                            '';
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            code,
                            style:
                                TextStyle(fontSize: 10, color: context.outline),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max) return const SizedBox.shrink();
                        return Text(
                          '${value.toInt()}',
                          style:
                              TextStyle(fontSize: 10, color: context.outline),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final dept = _departmentReport![group.x.toInt()];
                      final deptName = dept['department_name'] as String? ?? '';
                      final statusLabels = [
                        'Pending',
                        'Approved',
                        'Rejected',
                        'Completed'
                      ];
                      final statusColors = [
                        context.warning,
                        context.primaryBlue,
                        context.error,
                        context.success,
                      ];
                      return BarTooltipItem(
                        '$deptName\n',
                        TextStyle(
                            color: context.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 12),
                        children: [
                          TextSpan(
                            text: '${statusLabels[rodIndex]}: ',
                            style: TextStyle(
                                color: statusColors[rodIndex],
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                          ),
                          TextSpan(
                            text: '${rod.toY.toInt()}',
                            style: TextStyle(
                                color: context.onSurface, fontSize: 12),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildBarLegend(),
        ],
      ),
    );
  }

  Widget _buildBarLegend() {
    final entries = [
      ('Pending', context.warning),
      ('Approved', context.primaryBlue),
      ('Rejected', context.error),
      ('Completed', context.success),
    ];
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: entries.map((e) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: e.$2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(e.$1, style: TextStyle(fontSize: 11, color: context.outline)),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadReports,
            child: CustomScrollView(
              slivers: [
                _buildAdminAppBar(context, 'reports'),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _ReportsFilterBar(
                        startCtl: _startCtl,
                        endCtl: _endCtl,
                        reportType: _reportType,
                        onPickDate: _pickDate,
                        onFilterChanged: (type) {
                          setState(() => _reportType = type);
                          _loadReports();
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const Center(
                            child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ))
                      else ...[
                        _ReportsStatSummary(
                          statusCounts: _statusCounts,
                          departmentCount: _departmentReport?.length ?? 0,
                        ),
                        const SizedBox(height: 16),
                        _buildDepartmentBarChart(),
                        Text('Leave Requests',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: context.onSurface,
                                height: 1.5)),
                        const SizedBox(height: 8),
                        if (_reportData == null || _reportData!.isEmpty)
                          const EmptyState(
                            icon: Icons.inbox_outlined,
                            title: 'No leave requests found',
                          ),
                      ],
                    ]),
                  ),
                ),
                if (_reportData != null && _reportData!.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = _reportData![index];
                          final status =
                              entry['status'] as String? ?? 'pending';
                          final statusColor =
                              AppConstants.statusColors[status] ??
                                  context.neutralGray;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.outlineVariant),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${entry['employee_name'] ?? 'Unknown'}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: context.onSurface),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${entry['leave_date'] ?? ''} \u2022 ${entry['start_time'] ?? ''}-${entry['end_time'] ?? ''}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: context.outline),
                                      ),
                                      Text(
                                        entry['reason'] ?? '',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: context.neutralGray),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                        color:
                                            statusColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    AppConstants.statusLabels[status] ?? status,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: _reportData!.length.clamp(0, 50),
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

class _ReportsFilterBar extends StatelessWidget {
  final TextEditingController startCtl;
  final TextEditingController endCtl;
  final String reportType;
  final void Function(bool isStart) onPickDate;
  final void Function(String type) onFilterChanged;

  const _ReportsFilterBar({
    required this.startCtl,
    required this.endCtl,
    required this.reportType,
    required this.onPickDate,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: startCtl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Start Date',
                  prefixIcon: Icon(Icons.calendar_today, size: 18),
                  isDense: true,
                ),
                onTap: () => onPickDate(true),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('to', style: TextStyle(color: context.neutralGray)),
            ),
            Expanded(
              child: TextField(
                controller: endCtl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'End Date',
                  prefixIcon: Icon(Icons.calendar_today, size: 18),
                  isDense: true,
                ),
                onTap: () => onPickDate(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                  label: 'All',
                  selected: reportType.isEmpty,
                  onTap: () => onFilterChanged('')),
              const SizedBox(width: 8),
              _FilterChip(
                  label: 'Department',
                  selected: reportType == 'department',
                  onTap: () => onFilterChanged('department')),
              const SizedBox(width: 8),
              _FilterChip(
                  label: 'Employee',
                  selected: reportType == 'employee',
                  onTap: () => onFilterChanged('employee')),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportsStatSummary extends StatelessWidget {
  final Map<String, int> statusCounts;
  final int departmentCount;

  const _ReportsStatSummary({
    required this.statusCounts,
    required this.departmentCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _StatCard(
                icon: Icons.pending_actions,
                label: 'Pending',
                value: '${statusCounts['pending'] ?? 0}',
                color: context.warning),
            const SizedBox(width: 8),
            _StatCard(
                icon: Icons.check_circle,
                label: 'Approved',
                value: '${statusCounts['approved'] ?? 0}',
                color: context.success),
            const SizedBox(width: 8),
            _StatCard(
                icon: Icons.cancel,
                label: 'Rejected',
                value: '${statusCounts['rejected'] ?? 0}',
                color: context.error),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _StatCard(
                icon: Icons.timer,
                label: 'Active',
                value: '${statusCounts['active'] ?? 0}',
                color: context.primaryBlue),
            const SizedBox(width: 8),
            _StatCard(
                icon: Icons.check_circle_outline,
                label: 'Completed',
                value: '${statusCounts['completed'] ?? 0}',
                color: context.secondary),
            const SizedBox(width: 8),
            _StatCard(
                icon: Icons.business,
                label: 'Departments',
                value: '$departmentCount',
                color: context.tertiary),
          ],
        ),
      ],
    );
  }
}

class _LeaveTab extends StatefulWidget {
  const _LeaveTab();

  @override
  State<_LeaveTab> createState() => _LeaveTabState();
}

class _LeaveTabState extends State<_LeaveTab> {
  late final ApiService _api;
  List<dynamic>? _leaves;
  bool _isLoading = true;
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLeaves();
    });
  }

  Future<void> _loadLeaves() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.getReports();
      _leaves = res['data'] as List<dynamic>?;
    } catch (e) {
      debugPrint('Failed to load leaves: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<dynamic> get _filteredLeaves {
    if (_leaves == null) return [];
    if (_statusFilter.isEmpty) return _leaves!;
    return _leaves!.where((l) => l['status'] == _statusFilter).toList();
  }

  void _confirmDeleteLeave(Map<String, dynamic> leave) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Leave'),
        content: Text(
            'Remove leave request by ${leave['employee_name'] ?? 'Unknown'} on ${leave['leave_date'] ?? ''}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: ctx.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        _api.deleteLeave(leave['leave_id'] as String).then((_) {
          _loadLeaves();
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Leave deleted')));
          }
        }).catchError((e) {
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('$e')));
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLeaves;

    final slivers = <Widget>[
      _buildAdminAppBar(context, 'leaves'),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            // ── Status Filters ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                      label: 'All',
                      selected: _statusFilter.isEmpty,
                      onTap: () {
                        setState(() => _statusFilter = '');
                      }),
                  const SizedBox(width: 8),
                  _FilterChip(
                      label: 'Pending',
                      selected: _statusFilter == 'pending',
                      onTap: () {
                        setState(() => _statusFilter = 'pending');
                      }),
                  const SizedBox(width: 8),
                  _FilterChip(
                      label: 'Approved',
                      selected: _statusFilter == 'approved',
                      onTap: () {
                        setState(() => _statusFilter = 'approved');
                      }),
                  const SizedBox(width: 8),
                  _FilterChip(
                      label: 'Active',
                      selected: _statusFilter == 'active',
                      onTap: () {
                        setState(() => _statusFilter = 'active');
                      }),
                  const SizedBox(width: 8),
                  _FilterChip(
                      label: 'Completed',
                      selected: _statusFilter == 'completed',
                      onTap: () {
                        setState(() => _statusFilter = 'completed');
                      }),
                  const SizedBox(width: 8),
                  _FilterChip(
                      label: 'Rejected',
                      selected: _statusFilter == 'rejected',
                      onTap: () {
                        setState(() => _statusFilter = 'rejected');
                      }),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('${filtered.length} leave${filtered.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 12, color: context.neutralGray)),
            const SizedBox(height: 8),
            if (_isLoading)
              const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()))
            else if (filtered.isEmpty)
              const EmptyState(
                icon: Icons.inbox_outlined,
                title: 'No leave requests',
              ),
          ]),
        ),
      ),
    ];

    if (!_isLoading && filtered.isNotEmpty) {
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _buildLeaveItem(ctx, filtered[i]),
              childCount: filtered.length,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadLeaves,
            child: CustomScrollView(slivers: slivers),
          ),
        ],
      ),
    );
  }

  void _approveLeave(Map<String, dynamic> leave) async {
    final leaveId = leave['leave_id'] as String? ?? '';
    final name = leave['employee_name'] as String? ?? 'Unknown';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Approve Leave?'),
        content: Text(
            '$name \u2014 ${leave['leave_date'] ?? ''} (${leave['start_time'] ?? ''} - ${leave['end_time'] ?? ''})'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed == true && leaveId.isNotEmpty && mounted) {
      await context.read<SupervisorProvider>().approveLeave(leaveId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Approved leave for $name')));
        _loadLeaves();
      }
    }
  }

  void _rejectLeave(Map<String, dynamic> leave) async {
    final leaveId = leave['leave_id'] as String? ?? '';
    final name = leave['employee_name'] as String? ?? 'Unknown';
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Reject Leave'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reason for rejecting $name?'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                  hintText: 'Enter reason...', labelText: 'Rejection reason'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, ctrl.text.trim());
            },
            style: FilledButton.styleFrom(backgroundColor: ctx.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (reason != null && leaveId.isNotEmpty && mounted) {
      await context.read<SupervisorProvider>().rejectLeave(leaveId, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Rejected leave for $name')));
        _loadLeaves();
      }
    }
  }

  void _revokeApproval(Map<String, dynamic> leave) async {
    final leaveId = leave['leave_id'] as String? ?? '';
    final name = leave['employee_name'] as String? ?? 'Unknown';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Revoke Approval?'),
        content: Text("Move $name's leave back to pending?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed == true && leaveId.isNotEmpty && mounted) {
      await context.read<SupervisorProvider>().revokeApproval(leaveId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Revoked approval for $name')));
        _loadLeaves();
      }
    }
  }

  Widget _buildLeaveItem(BuildContext context, Map<String, dynamic> leave) {
    final status = leave['status'] as String? ?? 'pending';
    final statusColor =
        AppConstants.statusColors[status] ?? context.neutralGray;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(leave['employee_name'] ?? 'Unknown',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: context.onSurface)),
                    if ((leave['department_name'] as String?)?.isNotEmpty ==
                        true)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('${leave['department_name'] ?? ''}',
                            style: TextStyle(
                                fontSize: 12, color: context.neutralGray)),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  AppConstants.statusLabels[status] ?? status,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: context.neutralGray),
                const SizedBox(width: 4),
                Text('${leave['leave_date'] ?? ''}',
                    style: TextStyle(fontSize: 12, color: context.neutralGray)),
                const SizedBox(width: 12),
                Icon(Icons.access_time, size: 14, color: context.neutralGray),
                const SizedBox(width: 4),
                Text(
                    '${leave['start_time'] ?? ''} - ${leave['end_time'] ?? ''}',
                    style: TextStyle(fontSize: 12, color: context.neutralGray)),
              ],
            ),
          ),
          if ((leave['reason'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(leave['reason'] as String? ?? '',
                style: TextStyle(fontSize: 12, color: context.neutralGray),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
          if (status == 'pending' ||
              status == 'approved' ||
              status == 'active') ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: context.error, size: 20),
                  tooltip: 'Delete',
                  onPressed: () => _confirmDeleteLeave(leave),
                ),
                if (status == 'pending') ...[
                  OutlinedButton.icon(
                    onPressed: () => _rejectLeave(leave),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.error,
                      side: BorderSide(color: context.error),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _approveLeave(leave),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.primary,
                      foregroundColor: context.onPrimary,
                    ),
                  ),
                ],
                if (status == 'approved')
                  OutlinedButton.icon(
                    onPressed: () => _revokeApproval(leave),
                    icon: const Icon(Icons.undo, size: 18),
                    label: const Text('Revoke'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.warning,
                      side: BorderSide(color: context.warning),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? context.primary.withValues(alpha: 0.15)
              : context.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? context.primary : context.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? context.primary : context.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _DepartmentTab extends StatefulWidget {
  const _DepartmentTab();

  @override
  State<_DepartmentTab> createState() => _DepartmentTabState();
}

class _DepartmentTabState extends State<_DepartmentTab> {
  late final ApiService _api;
  List<Department> _departments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiService>();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() => _isLoading = true);
    try {
      final deps = await _api.getDepartments();
      _departments = deps
          .map((j) => Department.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Failed to load departments: $e');
    }
    setState(() => _isLoading = false);
  }

  void _showAddDialog() {
    showDialog<bool>(
      context: context,
      builder: (_) => const _AddDepartmentDialog(),
    ).then((created) {
      if (created == true) _loadDepartments();
    });
  }

  void _showEditDialog(Department dept) {
    showDialog<bool>(
      context: context,
      builder: (_) => _EditDepartmentDialog(dept: dept),
    ).then((updated) {
      if (updated == true) _loadDepartments();
    });
  }

  void _confirmDelete(Department dept) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Department'),
        content: Text(
            'Remove ${dept.departmentName}? Employees in this department may be affected.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: ctx.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _api.deleteDepartment(dept.departmentId);
        _loadDepartments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${dept.departmentName} deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingIndicator();

    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadDepartments,
            child: CustomScrollView(
              slivers: [
                _buildAdminAppBar(context, 'departments'),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  sliver: _departments.isEmpty
                      ? SliverList(
                          delegate: SliverChildListDelegate([
                            const EmptyState(
                              icon: Icons.business_outlined,
                              title: 'No departments yet',
                              subtitle: 'Add a department to get started',
                            ),
                          ]),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final dept = _departments[index];
                              final statusColor = dept.isActive
                                  ? context.success
                                  : context.error;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: context.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: context.outlineVariant),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                        left: 0,
                                        top: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 4,
                                          decoration: BoxDecoration(
                                              color: statusColor,
                                              borderRadius:
                                                  const BorderRadius.only(
                                                      topLeft:
                                                          Radius.circular(12),
                                                      bottomLeft:
                                                          Radius.circular(12))),
                                        )),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 14, 14, 14),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                              radius: 24,
                                              backgroundColor: context.secondary
                                                  .withValues(alpha: 0.12),
                                              child: Icon(Icons.business,
                                                  color: context.secondary)),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(dept.departmentName,
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            context.onSurface)),
                                                const SizedBox(height: 2),
                                                Text(
                                                    '${dept.departmentCode ?? 'No code'}${dept.headOfDepartment != null ? ' \u2022 ${dept.headOfDepartment}' : ''}',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            context.outline)),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                                color: statusColor.withValues(
                                                    alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                border: Border.all(
                                                    color:
                                                        statusColor.withValues(
                                                            alpha: 0.3))),
                                            child: Text(
                                                dept.isActive
                                                    ? 'Active'
                                                    : 'Inactive',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: statusColor)),
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                              icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 20),
                                              color: context.neutralGray,
                                              onPressed: () =>
                                                  _showEditDialog(dept)),
                                          const SizedBox(width: 4),
                                          IconButton(
                                              icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 20),
                                              color: context.error,
                                              onPressed: () =>
                                                  _confirmDelete(dept)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            childCount: _departments.length,
                          ),
                        ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'admin_add_department',
              onPressed: _showAddDialog,
              backgroundColor: context.primary,
              foregroundColor: context.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _RoleBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _AddDepartmentDialog extends StatefulWidget {
  const _AddDepartmentDialog();

  @override
  State<_AddDepartmentDialog> createState() => _AddDepartmentDialogState();
}

class _AddDepartmentDialogState extends State<_AddDepartmentDialog> {
  final _idCtl = TextEditingController();
  final _nameCtl = TextEditingController();
  final _codeCtl = TextEditingController();
  final _hodCtl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _idCtl.dispose();
    _nameCtl.dispose();
    _codeCtl.dispose();
    _hodCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Department'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _idCtl,
              decoration: const InputDecoration(labelText: 'Department ID'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtl,
              decoration: const InputDecoration(labelText: 'Department Name'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
                controller: _codeCtl,
                decoration: const InputDecoration(
                    labelText: 'Department Code (optional)')),
            const SizedBox(height: 12),
            TextFormField(
                controller: _hodCtl,
                decoration: const InputDecoration(
                    labelText: 'Head of Department (optional)')),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _create,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _create() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      await api.createDepartment({
        'department_id': _idCtl.text.trim(),
        'department_name': _nameCtl.text.trim(),
        'department_code': _codeCtl.text.trim(),
        'head_of_department': _hodCtl.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      String msg;
      if (e is DioException && e.response?.data is Map) {
        msg = (e.response!.data as Map)['message']?.toString() ??
            'Failed to create department';
      } else {
        msg = e.toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}

class _EditDepartmentDialog extends StatefulWidget {
  final Department dept;

  const _EditDepartmentDialog({required this.dept});

  @override
  State<_EditDepartmentDialog> createState() => _EditDepartmentDialogState();
}

class _EditDepartmentDialogState extends State<_EditDepartmentDialog> {
  late final _nameCtl = TextEditingController(text: widget.dept.departmentName);
  late final _codeCtl =
      TextEditingController(text: widget.dept.departmentCode ?? '');
  late final _hodCtl =
      TextEditingController(text: widget.dept.headOfDepartment ?? '');
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    _codeCtl.dispose();
    _hodCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.dept.departmentName}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtl,
              decoration: const InputDecoration(labelText: 'Department Name'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
                controller: _codeCtl,
                decoration: const InputDecoration(
                    labelText: 'Department Code (optional)')),
            const SizedBox(height: 12),
            TextFormField(
                controller: _hodCtl,
                decoration: const InputDecoration(
                    labelText: 'Head of Department (optional)')),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      await api.updateDepartment(widget.dept.departmentId, {
        'department_name': _nameCtl.text.trim(),
        'department_code': _codeCtl.text.trim(),
        'head_of_department': _hodCtl.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      String msg;
      if (e is DioException && e.response?.data is Map) {
        msg = (e.response!.data as Map)['message']?.toString() ??
            'Failed to update department';
      } else {
        msg = e.toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}

class _AddEmployeeDialog extends StatefulWidget {
  final List<Map<String, dynamic>> departments;

  const _AddEmployeeDialog({required this.departments});

  @override
  State<_AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<_AddEmployeeDialog> {
  final _idCtl = TextEditingController();
  final _nameCtl = TextEditingController();
  final _posCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedDept = '';
  bool _isSupervisor = false;
  bool _isAdmin = false;
  bool _isSecurity = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.departments.isNotEmpty) {
      _selectedDept =
          widget.departments.first['department_id'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _idCtl.dispose();
    _nameCtl.dispose();
    _posCtl.dispose();
    _emailCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Employee'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _idCtl,
                decoration: const InputDecoration(
                    labelText: 'Employee ID',
                    hintText: '000001',
                    helperText: '6-digit ID'),
                keyboardType: TextInputType.number,
                maxLength: 6,
                buildCounter: (context,
                        {required currentLength,
                        required isFocused,
                        maxLength}) =>
                    null,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length != 6 || int.tryParse(v.trim()) == null)
                    return 'Must be 6 digits';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _nameCtl,
                  decoration: const InputDecoration(
                      labelText: 'Full Name', hintText: 'e.g. Juan Dela Cruz'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _posCtl,
                  decoration: const InputDecoration(
                      labelText: 'Position',
                      hintText: 'e.g. Software Engineer'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _emailCtl,
                  decoration: const InputDecoration(
                      labelText: 'Email', hintText: 'e.g. juan@company.com'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _passCtl,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) =>
                      v == null || v.length < 4 ? 'Min 4 characters' : null),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedDept.isNotEmpty ? _selectedDept : null,
                decoration: const InputDecoration(labelText: 'Department'),
                items: widget.departments
                    .map<DropdownMenuItem<String>>((d) =>
                        DropdownMenuItem<String>(
                          value: d['department_id'] as String?,
                          child: Text(d['department_name'] as String? ?? ''),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedDept = v ?? ''),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Supervisor access'),
                value: _isSupervisor,
                onChanged: (v) => setState(() => _isSupervisor = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Admin access'),
                value: _isAdmin,
                onChanged: (v) => setState(() => _isAdmin = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Security access'),
                value: _isSecurity,
                onChanged: (v) => setState(() => _isSecurity = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _create,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _create() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      await api.createEmployee({
        'employee_id': _idCtl.text.trim(),
        'full_name': _nameCtl.text.trim(),
        'position': _posCtl.text.trim(),
        'email': _emailCtl.text.trim(),
        'password': _passCtl.text,
        'department_id': _selectedDept,
        'is_supervisor': _isSupervisor,
        'is_admin': _isAdmin,
        'is_security': _isSecurity,
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      String msg;
      if (e is DioException && e.response?.data is Map) {
        msg = (e.response!.data as Map)['message']?.toString() ??
            'Failed to create employee';
      } else {
        msg = e.toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}

class _EditEmployeeDialog extends StatefulWidget {
  final Map<String, dynamic> emp;
  final List<Map<String, dynamic>> departments;

  const _EditEmployeeDialog({required this.emp, required this.departments});

  @override
  State<_EditEmployeeDialog> createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends State<_EditEmployeeDialog> {
  late final TextEditingController _nameCtl;
  late final TextEditingController _posCtl;
  late final TextEditingController _emailCtl;
  final _formKey = GlobalKey<FormState>();
  late String _selectedDept;
  late bool _isSupervisor;
  late bool _isAdmin;
  late bool _isSecurity;
  late bool _isActive;
  late final String _empId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController(text: widget.emp['full_name'] ?? '');
    _posCtl = TextEditingController(text: widget.emp['position'] ?? '');
    _emailCtl = TextEditingController(text: widget.emp['email'] ?? '');
    _selectedDept = widget.emp['department_id'] ?? '';
    _isSupervisor = widget.emp['is_supervisor'] == true;
    _isAdmin = widget.emp['is_admin'] == true;
    _isSecurity = widget.emp['is_security'] == true;
    _isActive = widget.emp['is_active'] != false;
    _empId = widget.emp['employee_id'] as String;
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _posCtl.dispose();
    _emailCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.emp['full_name']}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                  controller: _nameCtl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _posCtl,
                  decoration: const InputDecoration(labelText: 'Position'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _emailCtl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedDept.isNotEmpty ? _selectedDept : null,
                decoration: const InputDecoration(labelText: 'Department'),
                items: [
                  const DropdownMenuItem<String>(
                      value: null, child: Text('No department')),
                  ...widget.departments.map((d) => DropdownMenuItem<String>(
                        value: d['department_id'] as String?,
                        child: Text(d['department_name'] as String? ?? ''),
                      )),
                ],
                onChanged: (v) => setState(() => _selectedDept = v ?? ''),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Supervisor access'),
                value: _isSupervisor,
                onChanged: (v) => setState(() => _isSupervisor = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Admin access'),
                value: _isAdmin,
                onChanged: (v) => setState(() => _isAdmin = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Security access'),
                value: _isSecurity,
                onChanged: (v) => setState(() => _isSecurity = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: Text('Active',
                    style: TextStyle(
                        color: _isActive ? context.success : context.error)),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v ?? true),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      await api.updateEmployee(_empId, {
        'full_name': _nameCtl.text.trim(),
        'position': _posCtl.text.trim(),
        'email': _emailCtl.text.trim(),
        'department_id': _selectedDept,
      });
      if (widget.emp['is_supervisor'] != _isSupervisor) {
        await api.toggleSupervisor(_empId);
      }
      if (widget.emp['is_admin'] != _isAdmin) {
        await api.toggleAdmin(_empId);
      }
      if ((widget.emp['is_active'] ?? true) != _isActive) {
        await api.toggleActive(_empId);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee updated')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      String msg;
      if (e is DioException && e.response?.data is Map) {
        msg = (e.response!.data as Map)['message']?.toString() ??
            'Failed to update employee';
      } else {
        msg = e.toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}

class _ImportEmployeesDialog extends StatefulWidget {
  const _ImportEmployeesDialog();

  @override
  State<_ImportEmployeesDialog> createState() => _ImportEmployeesDialogState();
}

class _ImportEmployeesDialogState extends State<_ImportEmployeesDialog> {
  final _ctl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import Employees'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paste employee JSON array:',
                style:
                    TextStyle(fontSize: 13, color: context.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextField(
              controller: _ctl,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText:
                    '[{"employee_id":"000010","full_name":"John Doe","position":"Engineer","department_id":"DEPT01","email":"john@company.com","password":"pass1234"}]',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 8),
            Text(
                'Required: employee_id, full_name, position, department_id, email, password',
                style: TextStyle(fontSize: 11, color: context.neutralGray)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _import,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Import'),
        ),
      ],
    );
  }

  Future<void> _import() async {
    final trimmed = _ctl.text.trim();
    if (trimmed.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final list = (jsonDecode(trimmed) as List).cast<Map<String, dynamic>>();
      if (list.isEmpty) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No employees found in data')));
        return;
      }
      final api = context.read<ApiService>();
      final result = await api.importEmployees(list);
      if (!mounted) return;
      Navigator.pop(context, true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Imported ${result['imported'] ?? list.length} employees')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      String msg;
      if (e is DioException && e.response?.data is Map) {
        msg = (e.response!.data as Map)['message']?.toString() ??
            'Failed to import employees';
      } else {
        msg = e.toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}

class _ResetPasswordDialog extends StatefulWidget {
  final Map<String, dynamic> emp;

  const _ResetPasswordDialog({required this.emp});

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _passCtl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('New password for ${widget.emp['full_name']}'),
          const SizedBox(height: 12),
          TextField(
            controller: _passCtl,
            decoration: const InputDecoration(
                labelText: 'New Password', hintText: 'Min 4 characters'),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _reset,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Reset'),
        ),
      ],
    );
  }

  Future<void> _reset() async {
    if (_passCtl.text.length < 4) return;
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      await api.resetPassword(
          widget.emp['employee_id'] as String, _passCtl.text);
      if (!mounted) return;
      Navigator.pop(context, true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      String msg;
      if (e is DioException && e.response?.data is Map) {
        msg = (e.response!.data as Map)['message']?.toString() ??
            'Failed to reset password';
      } else {
        msg = e.toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: context.onSurface)),
            Text(label,
                style: TextStyle(fontSize: 13, color: context.neutralGray)),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(icon, size: 22, color: context.primary),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.onSurface,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
