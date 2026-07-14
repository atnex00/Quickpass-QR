import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../utils/debounce.dart';
import '../../widgets/custom_widgets.dart';
import 'admin_shared.dart';
import 'employee_detail_screen.dart';

class EmployeeTab extends StatefulWidget {
  const EmployeeTab({super.key});

  @override
  State<EmployeeTab> createState() => _EmployeeTabState();
}

class _EmployeeTabState extends State<EmployeeTab> {
  late final ApiService _api;
  final Debouncer _searchDebouncer =
      Debouncer();
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
      builder: (_) => AddEmployeeDialog(departments: _departments),
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
            EditEmployeeDialog(emp: emp, departments: _departments),
      ).then((updated) {
        if (updated == true) if (mounted) _loadData();
      });
    });
  }

  void _showImportDialog() {
    showDialog<bool>(
      context: context,
      builder: (_) => const ImportEmployeesDialog(),
    ).then((imported) {
      if (imported == true) _loadData();
    });
  }

  void _showPasswordResetDialog(Map<String, dynamic> emp) {
    showDialog<bool>(
      context: context,
      builder: (_) => ResetPasswordDialog(emp: emp),
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
              .showSnackBar(const SnackBar(content: Text('Failed to delete employee')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final slivers = <Widget>[
      buildAdminAppBar(context, 'employees'),
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
                            child: Text('All')),
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
                            child: Text('All')),
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
                            child: Text('All')),
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
      badges.add(AdminRoleBadge(label: 'Admin', color: context.error));
    }
    if (emp['is_supervisor'] == true) {
      badges.add(AdminRoleBadge(label: 'Supervisor', color: context.tertiary));
    }
    if (emp['is_security'] == true) {
      badges.add(AdminRoleBadge(label: 'Security', color: context.warning));
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
                  AdminActionButton(
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
                  AdminActionButton(
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
                  AdminActionButton(
                    icon: Icons.check_circle_outline,
                    label: emp['is_active'] != false ? 'Active' : 'Inactive',
                    active: emp['is_active'] != false,
                    color: emp['is_active'] != false
                        ? context.success
                        : context.error,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await _api.toggleActive(emp['employee_id']);
                        _loadData();
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                                content: Text('Failed to toggle status: $e')),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  AdminActionButton(
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

class AddEmployeeDialog extends StatefulWidget {

  const AddEmployeeDialog({super.key, required this.departments});
  final List<Map<String, dynamic>> departments;

  @override
  State<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<AddEmployeeDialog> {
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
                  if (v.trim().length != 6 || int.tryParse(v.trim()) == null) {
                    return 'Must be 6 digits';
                  }
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

class EditEmployeeDialog extends StatefulWidget {

  const EditEmployeeDialog({super.key, required this.emp, required this.departments});
  final Map<String, dynamic> emp;
  final List<Map<String, dynamic>> departments;

  @override
  State<EditEmployeeDialog> createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends State<EditEmployeeDialog> {
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
                      child: Text('No department')),
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

class ImportEmployeesDialog extends StatefulWidget {
  const ImportEmployeesDialog({super.key});

  @override
  State<ImportEmployeesDialog> createState() => _ImportEmployeesDialogState();
}

class _ImportEmployeesDialogState extends State<ImportEmployeesDialog> {
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

class ResetPasswordDialog extends StatefulWidget {

  const ResetPasswordDialog({super.key, required this.emp});
  final Map<String, dynamic> emp;

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
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
