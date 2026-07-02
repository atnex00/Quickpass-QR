import 'package:flutter/material.dart';
import '../../models/department.dart';
import '../../services/api_service.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.onPrimary,
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: colorScheme.onPrimary.withValues(alpha: 0.6),
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Employees'),
            Tab(icon: Icon(Icons.business), text: 'Departments'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _EmployeeTab(),
          _DepartmentTab(),
          _ReportsTab(),
        ],
      ),
    );
  }
}

// ─── Employee Tab ───────────────────────────────────────────────────────────

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
                  value: selectedDept.isNotEmpty ? selectedDept : null,
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
                  Navigator.pop(ctx);
                  _loadData();
                } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
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
              FloatingActionButton.small(
                onPressed: _showAddDialog,
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final emp = _filtered[i];
                final badges = <Widget>[];
                if (emp['is_admin'] == true) {
                  badges.add(_RoleBadge(label: 'Admin', color: colorScheme.error));
                }
                if (emp['is_supervisor'] == true) {
                  badges.add(_RoleBadge(label: 'Supervisor', color: colorScheme.tertiary));
                }

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primary,
                      child: Text(
                        (emp['full_name'] as String?)?[0] ?? '?',
                        style: TextStyle(color: colorScheme.onPrimary),
                      ),
                    ),
                    title: Text(emp['full_name'] ?? '', style: TextStyle(color: colorScheme.onSurface)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${emp['employee_id']} | ${emp['position'] ?? ''}', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        if (badges.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: badges,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
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
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Department Tab ─────────────────────────────────────────────────────────

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
                    Navigator.pop(ctx);
                    _loadDepartments();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Spacer(),
              FloatingActionButton.small(
                onPressed: _showAddDialog,
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDepartments,
            child: _departments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.business_outlined, size: 64, color: colorScheme.outlineVariant),
                        const SizedBox(height: 12),
                        Text('No departments yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text('Add a department to get started', style: TextStyle(color: colorScheme.outline, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _departments.length,
                    itemBuilder: (_, i) {
                      final dept = _departments[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.secondaryContainer,
                            child: Icon(Icons.business, color: colorScheme.secondary),
                          ),
                          title: Text(dept.departmentName, style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                          subtitle: Text(
                            '${dept.departmentCode ?? 'No code'}${dept.headOfDepartment != null ? ' \u2022 Head: ${dept.headOfDepartment}' : ''}',
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: dept.isActive ? colorScheme.primaryContainer : colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              dept.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: dept.isActive ? colorScheme.primary : colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

// ─── Reports Tab ────────────────────────────────────────────────────────────

class _ReportsTab extends StatefulWidget {
  const _ReportsTab();

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
            const SizedBox(height: 12),
            Row(
              children: [
                _ReportCard(
                  icon: Icons.pending_actions,
                  label: 'Pending',
                  value: '${_reportData?['pending_count'] ?? 0}',
                  color: colorScheme.tertiary,
                ),
                const SizedBox(width: 12),
                _ReportCard(
                  icon: Icons.check_circle,
                  label: 'Approved',
                  value: '${_reportData?['approved_count'] ?? 0}',
                  color: colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ReportCard(
                  icon: Icons.cancel,
                  label: 'Rejected',
                  value: '${_reportData?['rejected_count'] ?? 0}',
                  color: colorScheme.error,
                ),
                const SizedBox(width: 12),
                _ReportCard(
                  icon: Icons.people,
                  label: 'Employees',
                  value: '${_reportData?['employee_count'] ?? 0}',
                  color: colorScheme.secondary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Detailed reporting with charts and export options coming soon.',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ReportCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
              Text(label, style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
