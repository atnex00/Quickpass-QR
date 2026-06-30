import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../models/employee.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: "Employees"),
            Tab(icon: Icon(Icons.business), text: "Departments"),
            Tab(icon: Icon(Icons.bar_chart), text: "Reports"),
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
    String selectedDept = _departments.isNotEmpty ? _departments.first['department_id'] : '';
    bool isSupervisor = false;
    bool isAdmin = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text("Add Employee"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtl, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: posCtl, decoration: const InputDecoration(labelText: "Position", border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: emailCtl, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: passCtl, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()), obscureText: true),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedDept.isNotEmpty ? selectedDept : null,
                  decoration: const InputDecoration(labelText: "Department", border: OutlineInputBorder()),
                  items: _departments.map<DropdownMenuItem<String>>((d) => DropdownMenuItem<String>(
                    value: d['department_id'] as String?,
                    child: Text(d['department_name'] as String? ?? ''),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedDept = v ?? ''),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text("Supervisor access"),
                  value: isSupervisor,
                  onChanged: (v) => setDialogState(() => isSupervisor = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text("Admin access"),
                  value: isAdmin,
                  onChanged: (v) => setDialogState(() => isAdmin = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
                }
              },
              child: const Text("Create"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    hintText: "Search employees...",
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton.small(
                onPressed: _showAddDialog,
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
                  badges.add(_RoleBadge(label: 'Admin', color: QuickpassColors.error));
                }
                if (emp['is_supervisor'] == true) {
                  badges.add(_RoleBadge(label: 'Supervisor', color: QuickpassColors.accent));
                }

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: QuickpassColors.primary,
                      child: Text(
                        (emp['full_name'] as String?)?[0] ?? "?",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(emp['full_name'] ?? ""),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${emp['employee_id']} | ${emp['position'] ?? ""}"),
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
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _DepartmentTab extends StatelessWidget {
  const _DepartmentTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Department Management"));
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Reports & Analytics"));
  }
}
