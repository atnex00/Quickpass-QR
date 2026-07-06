import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/department.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_indicator.dart';

Widget _buildAdminAppBar(BuildContext context) {
  return SliverAppBar(
    pinned: true,
    toolbarHeight: 64,
    backgroundColor: QuickpassColors.darkPrimary,
    foregroundColor: QuickpassColors.darkOnPrimary,
    automaticallyImplyLeading: false,
    flexibleSpace: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: QuickpassColors.darkOnPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset('assets/icon/app-icon.png', width: 22, height: 22),
            ),
            const SizedBox(width: 8),
            const Text(
              'Quickpass',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: QuickpassColors.darkOnPrimary,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: QuickpassColors.darkOnPrimary),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(behavior: SnackBarBehavior.floating, content: Text('No new notifications')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: QuickpassColors.darkOnPrimary),
              onPressed: () => context.read<AuthProvider>().logout(),
            ),
          ],
        ),
      ),
    ),
  );
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
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: const [
              _OverviewTab(),
              _EmployeeTab(),
              _DepartmentTab(),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: QuickpassColors.outlineVariant)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: QuickpassColors.surface,
          indicatorColor: QuickpassColors.darkPrimary.withValues(alpha: 0.15),
          height: 80,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: QuickpassColors.onSurfaceVariant),
              selectedIcon: Icon(Icons.dashboard, color: QuickpassColors.darkPrimary),
              label: 'Overview',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline, color: QuickpassColors.onSurfaceVariant),
              selectedIcon: Icon(Icons.people, color: QuickpassColors.darkPrimary),
              label: 'Employees',
            ),
            NavigationDestination(
              icon: Icon(Icons.business_outlined, color: QuickpassColors.onSurfaceVariant),
              selectedIcon: Icon(Icons.business, color: QuickpassColors.darkPrimary),
              label: 'Departments',
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatefulWidget {
  const _OverviewTab();

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  final _api = ApiService();
  Map<String, dynamic>? _reportData;
  List<dynamic>? _departmentReport;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      _reportData = await _api.getReports();
      final deptRes = await _api.getReports(type: 'department');
      _departmentReport = deptRes['data'] as List<dynamic>?;
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Map<String, int> get _statusCounts {
    if (_reportData == null) return {};
    final data = _reportData!['data'] as List? ?? [];
    final counts = <String, int>{};
    for (final entry in data) {
      final s = entry['status'] as String? ?? 'unknown';
      counts[s] = (counts[s] ?? 0) + 1;
    }
    return counts;
  }

  int get _pendingCount => _statusCounts['pending'] ?? 0;
  int get _approvedCount => _statusCounts['approved'] ?? 0;
  int get _rejectedCount => _statusCounts['rejected'] ?? 0;
  int get _completedCount => _statusCounts['completed'] ?? 0;
  int get _activeCount => _statusCounts['active'] ?? 0;

  int get _employeeCount {
    if (_reportData == null) return 0;
    final data = _reportData!['data'] as List? ?? [];
    return data.map((e) => e['employee_id']).toSet().length;
  }

  int get _departmentCount => _departmentReport?.length ?? 0;

  Widget _buildPieChart() {
    final sections = <PieChartSectionData>[];
    final entries = [
      ('Pending', _pendingCount, QuickpassColors.warning),
      ('Approved', _approvedCount, QuickpassColors.primary),
      ('Rejected', _rejectedCount, QuickpassColors.error),
      ('Active', _activeCount, QuickpassColors.success),
      ('Completed', _completedCount, QuickpassColors.secondary),
    ];
    for (final e in entries) {
      if (e.$2 > 0) {
        sections.add(PieChartSectionData(
          value: e.$2.toDouble(),
          title: '${e.$2}',
          color: e.$3,
          radius: 40,
          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
        ));
      }
    }
    if (sections.isEmpty) {
      sections.add(PieChartSectionData(
        value: 1,
        title: '0',
        color: QuickpassColors.neutralGray.withValues(alpha: 0.3),
        radius: 40,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: QuickpassColors.neutralGray),
      ));
    }
    return PieChart(PieChartData(sections: sections, centerSpaceRadius: 30));
  }

  Widget _buildDepartmentTable() {
    if (_departmentReport == null || _departmentReport!.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: QuickpassColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: QuickpassColors.outlineVariant),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: QuickpassColors.neutralGray),
            SizedBox(width: 12),
            Expanded(
              child: Text('No department data available.', style: TextStyle(color: QuickpassColors.neutralGray)),
            ),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuickpassColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QuickpassColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SizedBox(width: 24, child: Text('ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: QuickpassColors.outline))),
              Expanded(child: Text('Department', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: QuickpassColors.outline))),
              SizedBox(width: 48, child: Text('Total', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: QuickpassColors.outline))),
              SizedBox(width: 48, child: Text('Pending', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: QuickpassColors.outline))),
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
                    child: Text('${dept['department_id'] ?? ''}', style: const TextStyle(fontSize: 12, color: QuickpassColors.neutralGray)),
                  ),
                  Expanded(child: Text('${dept['department_name'] ?? ''}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: QuickpassColors.onSurface))),
                  SizedBox(width: 48, child: Text('${dept['total_requests'] ?? 0}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: QuickpassColors.onSurface))),
                  SizedBox(width: 48, child: Text('${dept['pending'] ?? 0}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: QuickpassColors.warning))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _switchToTab(int index) {
    final parent = context.findAncestorStateOfType<_AdminPanelState>();
    parent?.setState(() => parent._currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.fullName ?? 'Admin';

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAdminAppBar(context),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: QuickpassColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: QuickpassColors.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: QuickpassColors.darkPrimary.withValues(alpha: 0.2),
                            child: Text(
                              (userName.isNotEmpty ? userName[0] : 'A').toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: QuickpassColors.darkPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Admin Control',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: QuickpassColors.outline,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: QuickpassColors.onSurface,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: QuickpassColors.error.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: QuickpassColors.error.withValues(alpha: 0.3)),
                                  ),
                                  child: const Text(
                                    'Admin',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: QuickpassColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      Row(
                        children: [
                          _StatCard(
                            icon: Icons.people,
                            label: 'Employees',
                            value: '$_employeeCount',
                            color: QuickpassColors.secondary,
                          ),
                          const SizedBox(width: 8),
                          _StatCard(
                            icon: Icons.pending_actions,
                            label: 'Pending',
                            value: '$_pendingCount',
                            color: QuickpassColors.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _StatCard(
                            icon: Icons.verified_user,
                            label: 'Active',
                            value: '$_activeCount',
                            color: QuickpassColors.success,
                          ),
                          const SizedBox(width: 8),
                          _StatCard(
                            icon: Icons.business,
                            label: 'Departments',
                            value: '$_departmentCount',
                            color: QuickpassColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: QuickpassColors.onSurface,
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
                              onTap: () => _switchToTab(1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.business,
                              title: 'Departments',
                              subtitle: 'Organize teams',
                              onTap: () => _switchToTab(2),
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
                                  const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Scroll down to view leave breakdown')),
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
                                  const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Settings coming soon')),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Leave Breakdown',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: QuickpassColors.onSurface,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: QuickpassColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: QuickpassColors.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 180,
                              child: _buildPieChart(),
                            ),
                            const SizedBox(height: 16),
_StatusLegend(label: 'Pending', count: _pendingCount, color: QuickpassColors.warning),
                            const SizedBox(height: 4),
                            _StatusLegend(label: 'Approved', count: _approvedCount, color: QuickpassColors.primary),
                            const SizedBox(height: 4),
                            _StatusLegend(label: 'Rejected', count: _rejectedCount, color: QuickpassColors.error),
                            const SizedBox(height: 4),
                            _StatusLegend(label: 'Active', count: _activeCount, color: QuickpassColors.success),
                            const SizedBox(height: 4),
                            _StatusLegend(label: 'Completed', count: _completedCount, color: QuickpassColors.secondary),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Department Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: QuickpassColors.onSurface,
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
        ],
      ),
    );
  }
}

class _EmployeeTab extends StatefulWidget {
  const _EmployeeTab();

  @override
  State<_EmployeeTab> createState() => _EmployeeTabState();
}

class _EmployeeTabState extends State<_EmployeeTab> {
  final _api = ApiService();
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _departments = [];
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
    _loadData();
  }

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
        _totalPages = pagination?['pages'] as int? ?? 1;
        _totalEmployees = pagination?['total'] as int? ?? _employees.length;
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
    _loadData();
  }

  void _showAddDialog() {
    final nameCtl = TextEditingController();
    final posCtl = TextEditingController();
    final emailCtl = TextEditingController();
    final passCtl = TextEditingController();
    String selectedDept = _departments.isNotEmpty ? _departments.first['department_id'] ?? '' : '';
    bool isSupervisor = false;
    bool isAdmin = false;
    bool isSecurity = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Employee'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Full Name', hintText: 'e.g. Juan Dela Cruz')),
                const SizedBox(height: 12),
                TextField(controller: posCtl, decoration: const InputDecoration(labelText: 'Position', hintText: 'e.g. Software Engineer')),
                const SizedBox(height: 12),
                TextField(controller: emailCtl, decoration: const InputDecoration(labelText: 'Email', hintText: 'e.g. juan@company.com')),
                const SizedBox(height: 12),
                TextField(controller: passCtl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedDept.isNotEmpty ? selectedDept : null,
                  decoration: const InputDecoration(labelText: 'Department'),
                  items: _departments.map<DropdownMenuItem<String>>((d) => DropdownMenuItem<String>(
                    value: d['department_id'] as String?,
                    child: Text(d['department_name'] as String? ?? ''),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedDept = v ?? ''),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Supervisor access'),
                  value: isSupervisor,
                  onChanged: (v) => setDialogState(() => isSupervisor = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Admin access'),
                  value: isAdmin,
                  onChanged: (v) => setDialogState(() => isAdmin = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Security access'),
                  value: isSecurity,
                  onChanged: (v) => setDialogState(() => isSecurity = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameCtl.text.trim().isEmpty) return;
                try {
                  await _api.createEmployee({
                    'full_name': nameCtl.text.trim(),
                    'position': posCtl.text.trim(),
                    'email': emailCtl.text.trim(),
                    'password': passCtl.text,
                    'department_id': selectedDept,
                    'is_supervisor': isSupervisor,
                    'is_admin': isAdmin,
                    'is_security': isSecurity,
                  });
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  _loadData();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> emp) {
    final nameCtl = TextEditingController(text: emp['full_name'] ?? '');
    final posCtl = TextEditingController(text: emp['position'] ?? '');
    final emailCtl = TextEditingController(text: emp['email'] ?? '');
    String selectedDept = emp['department_id'] ?? '';
    bool isSupervisor = emp['is_supervisor'] == true;
    bool isAdmin = emp['is_admin'] == true;
    bool isSecurity = emp['is_security'] == true;
    bool isActive = emp['is_active'] != false;
    final empId = emp['employee_id'] as String;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit ${emp['full_name']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 12),
                TextField(controller: posCtl, decoration: const InputDecoration(labelText: 'Position')),
                const SizedBox(height: 12),
                TextField(controller: emailCtl, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedDept.isNotEmpty ? selectedDept : null,
                  decoration: const InputDecoration(labelText: 'Department'),
                  items: const [DropdownMenuItem<String>(value: '', child: Text('No department'))],
                  onChanged: (v) => setDialogState(() => selectedDept = v ?? ''),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Supervisor access'),
                  value: isSupervisor,
                  onChanged: (v) => setDialogState(() => isSupervisor = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Admin access'),
                  value: isAdmin,
                  onChanged: (v) => setDialogState(() => isAdmin = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Security access'),
                  value: isSecurity,
                  onChanged: (v) => setDialogState(() => isSecurity = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: Text('Active', style: TextStyle(color: isActive ? QuickpassColors.success : QuickpassColors.error)),
                  value: isActive,
                  onChanged: (v) => setDialogState(() => isActive = v ?? true),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                try {
                  await _api.updateEmployee(empId, {
                    'full_name': nameCtl.text,
                    'position': posCtl.text,
                    'email': emailCtl.text,
                    'department_id': selectedDept,
                  });
                  if (emp['is_supervisor'] != isSupervisor) {
                    await _api.toggleSupervisor(empId);
                  }
                  if (emp['is_admin'] != isAdmin) {
                    await _api.toggleAdmin(empId);
                  }
                  if ((emp['is_active'] ?? true) != isActive) {
                    await _api.toggleActive(empId);
                  }
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Employee updated')),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPasswordResetDialog(Map<String, dynamic> emp) {
    final passCtl = TextEditingController();
    final empId = emp['employee_id'] as String;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('New password for ${emp['full_name']}'),
            const SizedBox(height: 12),
            TextField(
              controller: passCtl,
              decoration: const InputDecoration(labelText: 'New Password', hintText: 'Min 4 characters'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (passCtl.text.length < 4) return;
              try {
                await _api.resetPassword(empId, passCtl.text);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset successfully')),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> emp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Remove ${emp['full_name']}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: QuickpassColors.error),
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _employees.isEmpty) return const LoadingIndicator();

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAdminAppBar(context),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Search Bar ──
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search by name, ID or position...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                    const SizedBox(height: 12),

                    // ── Filter Row ──
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Department filter
                          Container(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: DropdownButtonFormField<String>(
                              initialValue: _filterDepartment,
                              decoration: const InputDecoration(
                                labelText: 'Dept',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              items: [
                                const DropdownMenuItem<String>(value: null, child: Text('All')),
                                ..._departments.map((d) => DropdownMenuItem<String>(
                                  value: d['department_id'] as String?,
                                  child: Text(d['department_name'] as String? ?? '', overflow: TextOverflow.ellipsis),
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
                          // Status filter
                          Container(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: DropdownButtonFormField<String>(
                              initialValue: _filterStatus.isEmpty ? null : _filterStatus,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              items: const [
                                DropdownMenuItem<String>(value: null, child: Text('All')),
                                DropdownMenuItem<String>(value: 'active', child: Text('Active')),
                                DropdownMenuItem<String>(value: 'inactive', child: Text('Inactive')),
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
                          // Role filter
                          Container(
                            constraints: const BoxConstraints(maxWidth: 140),
                            child: DropdownButtonFormField<String>(
                              initialValue: _filterRole.isEmpty ? null : _filterRole,
                              decoration: const InputDecoration(
                                labelText: 'Role',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              items: const [
                                DropdownMenuItem<String>(value: null, child: Text('All')),
                                DropdownMenuItem<String>(value: 'admin', child: Text('Admin')),
                                DropdownMenuItem<String>(value: 'supervisor', child: Text('Supervisor')),
                                DropdownMenuItem<String>(value: 'security', child: Text('Security')),
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
                          style: const TextStyle(fontSize: 12, color: QuickpassColors.neutralGray),
                        ),
                      ),

                    // ── Employee List ──
                    if (_loadingError)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: QuickpassColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: QuickpassColors.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: QuickpassColors.error),
                            const SizedBox(height: 12),
                            const Text('Failed to load employees',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _loadData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    else if (_isLoading)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ))
                    else if (_employees.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: QuickpassColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: QuickpassColors.outlineVariant),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.people_outline, size: 64, color: QuickpassColors.outlineVariant),
                            SizedBox(height: 12),
                            Text('No employees found',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: QuickpassColors.onSurfaceVariant)),
                            SizedBox(height: 4),
                            Text('Try adjusting your search or filters',
                              style: TextStyle(color: QuickpassColors.neutralGray, fontSize: 13)),
                          ],
                        ),
                      )
                    else
                      ...List.generate(_employees.length, (i) {
                        final emp = _employees[i];
                        final isActive = emp['is_active'] != false;
                        final badges = <Widget>[];
                        if (emp['is_admin'] == true) {
                          badges.add(const _RoleBadge(label: 'Admin', color: QuickpassColors.error));
                        }
                        if (emp['is_supervisor'] == true) {
                          badges.add(const _RoleBadge(label: 'Supervisor', color: QuickpassColors.tertiary));
                        }
                        if (emp['is_security'] == true) {
                          badges.add(const _RoleBadge(label: 'Security', color: QuickpassColors.warning));
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isActive ? QuickpassColors.surfaceContainerLowest : QuickpassColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive ? QuickpassColors.outlineVariant : QuickpassColors.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                // ── Main row ──
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? QuickpassColors.darkPrimary.withValues(alpha: 0.2)
                                            : QuickpassColors.outlineVariant.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Center(
                                        child: Text(
                                          (emp['full_name'] as String?)?[0] ?? '?',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isActive ? QuickpassColors.darkPrimary : QuickpassColors.neutralGray,
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
                                                    color: isActive ? QuickpassColors.onSurface : QuickpassColors.neutralGray,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              InkWell(
                                                onTap: () => _showEditDialog(emp),
                                                child: const Icon(Icons.edit, size: 16, color: QuickpassColors.neutralGray),
                                              ),
                                              if (!isActive) ...[
                                                const SizedBox(width: 6),
                                                const Text('inactive',
                                                  style: TextStyle(fontSize: 11, color: QuickpassColors.error, fontWeight: FontWeight.w500)),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${emp['employee_id']} | ${emp['position'] ?? ''}',
                                            style: const TextStyle(fontSize: 12, color: QuickpassColors.outline),
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
                                      color: QuickpassColors.error,
                                      onPressed: () => _confirmDelete(emp),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    ),
                                  ],
                                ),
                                // ── Action buttons row ──
                                const Divider(height: 12),
                                Row(
                                  children: [
                                    _ActionButton(
                                      icon: Icons.admin_panel_settings,
                                      label: 'Admin',
                                      active: emp['is_admin'] == true,
                                      color: QuickpassColors.error,
                                      onTap: () async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        try {
                                          await _api.toggleAdmin(emp['employee_id']);
                                          if (!mounted) return;
                                          _loadData();
                                          messenger.showSnackBar(
                                            SnackBar(content: Text('Admin ${emp['is_admin'] == true ? 'removed' : 'granted'}')),
                                          );
                                        } catch (_) {}
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    _ActionButton(
                                      icon: Icons.supervisor_account,
                                      label: 'Supervisor',
                                      active: emp['is_supervisor'] == true,
                                      color: QuickpassColors.tertiary,
                                      onTap: () async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        try {
                                          await _api.toggleSupervisor(emp['employee_id']);
                                          if (!mounted) return;
                                          _loadData();
                                          messenger.showSnackBar(
                                            SnackBar(content: Text('Supervisor ${emp['is_supervisor'] == true ? 'removed' : 'granted'}')),
                                          );
                                        } catch (_) {}
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    _ActionButton(
                                      icon: Icons.check_circle_outline,
                                      label: emp['is_active'] != false ? 'Active' : 'Inactive',
                                      active: emp['is_active'] != false,
                                      color: emp['is_active'] != false ? QuickpassColors.success : QuickpassColors.error,
                                      onTap: () async {
                                        try {
                                          await _api.toggleActive(emp['employee_id']);
                                          _loadData();
                                        } catch (_) {}
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    _ActionButton(
                                      icon: Icons.key,
                                      label: 'Password',
                                      active: false,
                                      color: QuickpassColors.warning,
                                      onTap: () => _showPasswordResetDialog(emp),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                    // ── Pagination ──
                    if (_employees.isNotEmpty && _totalPages > 1)
                      Padding(
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
                                backgroundColor: QuickpassColors.darkPrimary,
                                foregroundColor: QuickpassColors.darkOnPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                textStyle: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Page $_currentPage of $_totalPages',
                                style: const TextStyle(fontSize: 13, color: QuickpassColors.onSurfaceVariant),
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
                                backgroundColor: QuickpassColors.darkPrimary,
                                foregroundColor: QuickpassColors.darkOnPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                textStyle: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          ),

          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              onPressed: _showAddDialog,
              backgroundColor: QuickpassColors.darkPrimary,
              foregroundColor: QuickpassColors.darkOnPrimary,
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

class _StatusLegend extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatusLegend({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: QuickpassColors.neutralGray))),
        Text('$count', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
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
  const _ActionButton({required this.icon, required this.label, required this.active, required this.color, required this.onTap});

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
            border: Border.all(color: color.withValues(alpha: active ? 0.4 : 0.15)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: active ? color : QuickpassColors.neutralGray),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: active ? color : QuickpassColors.neutralGray)),
            ],
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
  final _api = ApiService();
  List<Department> _departments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() => _isLoading = true);
    try {
      final deps = await _api.getDepartments();
      _departments = deps.map((j) => Department.fromJson(j as Map<String, dynamic>)).toList();
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _showAddDialog() {
    final idCtl = TextEditingController();
    final nameCtl = TextEditingController();
    final codeCtl = TextEditingController();
    final hodCtl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Department'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: idCtl, decoration: const InputDecoration(labelText: 'Department ID')),
            const SizedBox(height: 12),
            TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Department Name')),
            const SizedBox(height: 12),
            TextField(controller: codeCtl, decoration: const InputDecoration(labelText: 'Department Code (optional)')),
            const SizedBox(height: 12),
            TextField(controller: hodCtl, decoration: const InputDecoration(labelText: 'Head of Department (optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (idCtl.text.trim().isEmpty || nameCtl.text.trim().isEmpty) return;
              try {
                await _api.createDepartment({
                  'department_id': idCtl.text.trim(),
                  'department_name': nameCtl.text.trim(),
                  'department_code': codeCtl.text.trim(),
                  'head_of_department': hodCtl.text.trim(),
                });
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _loadDepartments();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Department dept) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Department'),
        content: Text('Remove ${dept.departmentName}? Employees in this department may be affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: QuickpassColors.error),
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
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
          CustomScrollView(
            slivers: [
              _buildAdminAppBar(context),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                sliver: _departments.isEmpty
                    ? SliverList(
                        delegate: SliverChildListDelegate([
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: QuickpassColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: QuickpassColors.outlineVariant),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.business_outlined, size: 64, color: QuickpassColors.outlineVariant),
                                SizedBox(height: 12),
                                Text('No departments yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: QuickpassColors.onSurfaceVariant)),
                                SizedBox(height: 4),
                                Text('Add a department to get started', style: TextStyle(color: QuickpassColors.neutralGray, fontSize: 13)),
                              ],
                            ),
                          ),
                        ]),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final dept = _departments[index];
                            final statusColor = dept.isActive ? QuickpassColors.success : QuickpassColors.error;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: QuickpassColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: QuickpassColors.outlineVariant),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(left: 0, top: 0, bottom: 0, child: Container(
                                    width: 4,
                                    decoration: BoxDecoration(color: statusColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12))),
                                  )),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                                    child: Row(
                                      children: [
                                        CircleAvatar(radius: 24, backgroundColor: QuickpassColors.secondary.withValues(alpha: 0.12), child: const Icon(Icons.business, color: QuickpassColors.secondary)),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(dept.departmentName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: QuickpassColors.onSurface)),
                                              const SizedBox(height: 2),
                                              Text('${dept.departmentCode ?? 'No code'}${dept.headOfDepartment != null ? ' \u2022 ${dept.headOfDepartment}' : ''}', style: const TextStyle(fontSize: 14, color: QuickpassColors.outline)),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
                                          child: Text(dept.isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(icon: const Icon(Icons.delete_outline, size: 20), color: QuickpassColors.error, onPressed: () => _confirmDelete(dept)),
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

          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              onPressed: _showAddDialog,
              backgroundColor: QuickpassColors.darkPrimary,
              foregroundColor: QuickpassColors.darkOnPrimary,
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
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: QuickpassColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: QuickpassColors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: QuickpassColors.onSurface)),
            Text(label, style: const TextStyle(fontSize: 13, color: QuickpassColors.neutralGray)),
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
        color: QuickpassColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QuickpassColors.outlineVariant),
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
                  color: QuickpassColors.darkPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(icon, size: 22, color: QuickpassColors.darkPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: QuickpassColors.onSurface,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: QuickpassColors.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


