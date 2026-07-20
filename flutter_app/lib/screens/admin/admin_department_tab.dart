import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/department.dart';
import '../../services/api_service.dart';
import '../../utils/errors.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/loading_indicator.dart';
import 'admin_shared.dart';

class DepartmentTab extends StatefulWidget {
  const DepartmentTab({super.key});

  @override
  State<DepartmentTab> createState() => _DepartmentTabState();
}

class _DepartmentTabState extends State<DepartmentTab> {
  late final ApiService _api;
  List<Department> _departments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiService>();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final deps = await _api.getDepartments();
      _departments = deps
          .map((j) => Department.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = friendlyError(e);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showAddDialog() {
    showDialog<bool>(
      context: context,
      builder: (_) => const AddDepartmentDialog(),
    ).then((created) {
      if (created == true && mounted) _loadDepartments();
    });
  }

  void _showEditDialog(Department dept) {
    showDialog<bool>(
      context: context,
      builder: (_) => EditDepartmentDialog(dept: dept),
    ).then((updated) {
      if (updated == true && mounted) _loadDepartments();
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
              .showSnackBar(const SnackBar(content: Text('Failed to delete department')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingIndicator();

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: context.error),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 16),
                FilledButton(onPressed: _loadDepartments, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadDepartments,
            child: CustomScrollView(
              slivers: [
                buildAdminAppBar(context, 'departments'),
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

class AddDepartmentDialog extends StatefulWidget {
  const AddDepartmentDialog({super.key});

  @override
  State<AddDepartmentDialog> createState() => _AddDepartmentDialogState();
}

class _AddDepartmentDialogState extends State<AddDepartmentDialog> {
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

class EditDepartmentDialog extends StatefulWidget {

  const EditDepartmentDialog({super.key, required this.dept});
  final Department dept;

  @override
  State<EditDepartmentDialog> createState() => _EditDepartmentDialogState();
}

class _EditDepartmentDialogState extends State<EditDepartmentDialog> {
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
