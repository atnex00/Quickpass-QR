import 'package:flutter/material.dart';
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
              child: Icon(Icons.admin_panel_settings, size: 22, color: QuickpassColors.darkOnPrimary),
            ),
            const SizedBox(width: 8),
            Text(
              'Quickpass',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: QuickpassColors.darkOnPrimary,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: QuickpassColors.darkOnPrimary),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(behavior: SnackBarBehavior.floating, content: Text('No new notifications')),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.logout, color: QuickpassColors.darkOnPrimary),
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
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: QuickpassColors.outlineVariant)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: QuickpassColors.surface,
          indicatorColor: QuickpassColors.darkPrimary.withValues(alpha: 0.15),
          height: 80,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
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
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  int get _total {
    if (_reportData == null) return 1;
    return (_reportData!['pending_count'] ?? 0) +
           (_reportData!['approved_count'] ?? 0) +
           (_reportData!['rejected_count'] ?? 0) +
           (_reportData!['completed_count'] ?? 0) +
           (_reportData!['active_count'] ?? 0);
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
                              style: TextStyle(
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
                                Text(
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
                                  style: TextStyle(
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
                                  child: Text(
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
                            value: '${_reportData?['employee_count'] ?? 0}',
                            color: QuickpassColors.secondary,
                          ),
                          const SizedBox(width: 8),
                          _StatCard(
                            icon: Icons.pending_actions,
                            label: 'Pending',
                            value: '${_reportData?['pending_count'] ?? 0}',
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
                            value: '${_reportData?['active_count'] ?? 0}',
                            color: QuickpassColors.success,
                          ),
                          const SizedBox(width: 8),
                          _StatCard(
                            icon: Icons.business,
                            label: 'Departments',
                            value: '${_reportData?['department_count'] ?? 0}',
                            color: QuickpassColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Text(
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

                      Text(
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
                            _statBar('Pending', _reportData?['pending_count'] ?? 0, QuickpassColors.warning, _total),
                            const SizedBox(height: 10),
                            _statBar('Approved', _reportData?['approved_count'] ?? 0, QuickpassColors.primary, _total),
                            const SizedBox(height: 10),
                            _statBar('Rejected', _reportData?['rejected_count'] ?? 0, QuickpassColors.error, _total),
                            const SizedBox(height: 10),
                            _statBar('Active', _reportData?['active_count'] ?? 0, QuickpassColors.success, _total),
                            const SizedBox(height: 10),
                            _statBar('Completed', _reportData?['completed_count'] ?? 0, QuickpassColors.secondary, _total),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Recent Activity',
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
                          color: QuickpassColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: QuickpassColors.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: QuickpassColors.neutralGray),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Detailed reporting with charts and export options coming soon.',
                                style: TextStyle(color: QuickpassColors.neutralGray),
                              ),
                            ),
                          ],
                        ),
                      ),
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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final empRes = await _api.listEmployees();
      if (empRes['success']) {
        _employees = List<Map<String, dynamic>>.from(empRes['data']);
      }
      final deps = await _api.getDepartments();
      _departments = List<Map<String, dynamic>>.from(deps);
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _employees;
    final q = _searchQuery.toLowerCase();
    return _employees.where((e) =>
      (e['full_name'] as String? ?? '').toLowerCase().contains(q) ||
      (e['employee_id'] as String? ?? '').toLowerCase().contains(q) ||
      (e['position'] as String? ?? '').toLowerCase().contains(q)
    ).toList();
  }

  void _showAddDialog() {
    final nameCtl = TextEditingController();
    final posCtl = TextEditingController();
    final emailCtl = TextEditingController();
    final passCtl = TextEditingController();
    String selectedDept = _departments.isNotEmpty ? _departments.first['department_id'] ?? '' : '';
    bool isSupervisor = false;
    bool isAdmin = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Employee'),
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
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                try {
                  await _api.createEmployee({
                    'full_name': nameCtl.text,
                    'position': posCtl.text,
                    'email': emailCtl.text,
                    'password': passCtl.text,
                    'department_id': selectedDept,
                    'is_supervisor': isSupervisor,
                    'is_admin': isAdmin,
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
                    await _api.updateEmployee(empId, {'is_admin': isAdmin});
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
    if (_isLoading) return const LoadingIndicator();

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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search employees...',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (v) => setState(() => _searchQuery = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: FilledButton(
                            onPressed: _showAddDialog,
                            style: FilledButton.styleFrom(
                              backgroundColor: QuickpassColors.darkPrimary,
                              foregroundColor: QuickpassColors.darkOnPrimary,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Icon(Icons.add, size: 24),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_filtered.isEmpty)
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
                            Icon(Icons.people_outline, size: 64, color: QuickpassColors.outlineVariant),
                            const SizedBox(height: 12),
                            const Text('No employees found',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: QuickpassColors.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            const Text('Add an employee to get started',
                              style: TextStyle(color: QuickpassColors.neutralGray, fontSize: 13)),
                          ],
                        ),
                      )
                    else
                      ...List.generate(_filtered.length, (i) {
                        final emp = _filtered[i];
                        final isActive = emp['is_active'] != false;
                        final badges = <Widget>[];
                        if (emp['is_admin'] == true) {
                          badges.add(_RoleBadge(label: 'Admin', color: QuickpassColors.error));
                        }
                        if (emp['is_supervisor'] == true) {
                          badges.add(_RoleBadge(label: 'Supervisor', color: QuickpassColors.tertiary));
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
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _showEditDialog(emp),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
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
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: isActive ? QuickpassColors.darkPrimary : QuickpassColors.neutralGray,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
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
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: isActive ? QuickpassColors.onSurface : QuickpassColors.neutralGray,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (!isActive) ...[
                                              const SizedBox(width: 6),
                                              Text('(inactive)',
                                                style: TextStyle(fontSize: 11, color: QuickpassColors.error, fontWeight: FontWeight.w500)),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${emp['employee_id']} | ${emp['position'] ?? ''}',
                                          style: const TextStyle(fontSize: 14, color: QuickpassColors.outline),
                                        ),
                                        if (badges.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Row(
                                              children: badges,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    color: QuickpassColors.error,
                                    onPressed: () => _confirmDelete(emp),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
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
    final nameCtl = TextEditingController();
    final codeCtl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Department'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Department Name')),
            const SizedBox(height: 12),
            TextField(controller: codeCtl, decoration: const InputDecoration(labelText: 'Department Code (optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (nameCtl.text.trim().isEmpty) return;
              try {
                await _api.createDepartment({'department_name': nameCtl.text.trim(), 'department_code': codeCtl.text.trim()});
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
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (_departments.isEmpty)
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
                            Icon(Icons.business_outlined, size: 64, color: QuickpassColors.outlineVariant),
                            const SizedBox(height: 12),
                            const Text('No departments yet',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: QuickpassColors.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            const Text('Add a department to get started',
                              style: TextStyle(color: QuickpassColors.neutralGray, fontSize: 13)),
                          ],
                        ),
                      )
                    else
                      ...List.generate(_departments.length, (i) {
                        final dept = _departments[i];
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
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 4,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: QuickpassColors.secondary.withValues(alpha: 0.12),
                                      child: const Icon(Icons.business, color: QuickpassColors.secondary),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            dept.departmentName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: QuickpassColors.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${dept.departmentCode ?? 'No code'}${dept.headOfDepartment != null ? ' \u2022 ${dept.headOfDepartment}' : ''}',
                                            style: const TextStyle(fontSize: 14, color: QuickpassColors.outline),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        dept.isActive ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20),
                                      color: QuickpassColors.error,
                                      onPressed: () => _confirmDelete(dept),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
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
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: QuickpassColors.onSurface)),
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

Widget _statBar(String label, int count, Color color, int total) {
  final ratio = total > 0 ? count / total : 0.0;
  return Row(
    children: [
      SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 13, color: QuickpassColors.neutralGray))),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: color.withValues(alpha: 0.1),
            color: color,
            minHeight: 8,
          ),
        ),
      ),
      const SizedBox(width: 12),
      SizedBox(width: 24, child: Text('$count', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color))),
    ],
  );
}
