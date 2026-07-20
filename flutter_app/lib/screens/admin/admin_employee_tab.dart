import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../utils/debounce.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/shimmer_list.dart';
import 'admin_shared.dart';
import 'employee_detail_screen.dart';
import 'widgets/add_employee_dialog.dart';
import 'widgets/edit_employee_dialog.dart';
import 'widgets/reset_password_dialog.dart';

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
        departmentId: _filterDepartment?.isNotEmpty == true ? _filterDepartment : null,
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
      if (created == true && mounted) _loadData();
    });
  }

  void _showEditDialog(Map<String, dynamic> emp) {
    showDialog<bool>(
      context: context,
      builder: (_) =>
          EditEmployeeDialog(emp: emp, departments: _departments),
    ).then((updated) {
      if (updated == true && mounted) _loadData();
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
            // ── Filter Row ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    width: 280,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('dept_$_filterDepartment'),
                      initialValue: _filterDepartment,
                      decoration: const InputDecoration(
                        labelText: 'Dept',
                        isDense: false,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                            value: '', child: Text('All')),
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
                      key: ValueKey('status_$_filterStatus'),
                      initialValue: _filterStatus.isEmpty ? null : _filterStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        isDense: false,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem<String>(
                            value: '', child: Text('All')),
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
                      key: ValueKey('role_$_filterRole'),
                      initialValue: _filterRole.isEmpty ? null : _filterRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        isDense: false,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem<String>(
                            value: '', child: Text('All')),
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
              const SliverFillRemaining(
                child: ShimmerList(
                    itemCount: 5,
                    itemBuilder: _employeeRowPlaceholder,
                    scrollable: false),
              )
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
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
                        if (mounted) _loadData();
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
                    icon: Icons.shield_outlined,
                    label: 'Security',
                    active: emp['is_security'] == true,
                    color: context.warning,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await _api.updateEmployee(emp['employee_id'] as String, {
                          'is_security': emp['is_security'] != true,
                        });
                        if (!mounted) return;
                        _loadData();
                        final was = emp['is_security'] == true;
                        messenger.showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Security ${was ? 'removed' : 'granted'}')),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                              content: Text('Failed to toggle security: $e')),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  AdminActionButton(
                    icon: Icons.key,
                    label: 'Password',
                    active: false,
                    color: context.tertiary,
                    onTap: () => _showPasswordResetDialog(emp),
                  ),
                  ],
                ),
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

Widget _employeeRowPlaceholder(int _) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 140,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 60,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ],
    ),
  );
}

