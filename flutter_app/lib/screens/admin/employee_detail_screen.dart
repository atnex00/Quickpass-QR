import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> employee;

  const EmployeeDetailScreen({super.key, required this.employee});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  late final ApiService _api;
  Map<String, dynamic>? _employee;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiService>();
    _employee = widget.employee;
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.listEmployees(search: _employee!['employee_id']);
      if (res['success'] &&
          res['data'] != null &&
          (res['data'] as List).isNotEmpty) {
        _employee = (res['data'] as List).first as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Failed to load employee detail: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  static String? _empPhoto(Map<String, dynamic>? emp) =>
      AppConfig.photoUrl(emp?['profile_photo'] as String?);

  void _showEditDialog() {
    final emp = _employee!;
    final nameCtl = TextEditingController(text: emp['full_name'] ?? '');
    final posCtl = TextEditingController(text: emp['position'] ?? '');
    final emailCtl = TextEditingController(text: emp['email'] ?? '');
    bool isSupervisor = emp['is_supervisor'] == true;
    bool isAdmin = emp['is_admin'] == true;
    bool isSecurity = emp['is_security'] == true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Employee'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtl,
                    decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 12),
                TextField(
                    controller: posCtl,
                    decoration: const InputDecoration(labelText: 'Position')),
                const SizedBox(height: 12),
                TextField(
                    controller: emailCtl,
                    decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Supervisor access'),
                  value: isSupervisor,
                  onChanged: (v) =>
                      setDialogState(() => isSupervisor = v ?? false),
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
                  onChanged: (v) =>
                      setDialogState(() => isSecurity = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                try {
                  await _api.updateEmployee(emp['employee_id'], {
                    'full_name': nameCtl.text,
                    'position': posCtl.text,
                    'email': emailCtl.text,
                  });
                  if (emp['is_supervisor'] != isSupervisor)
                    await _api.toggleSupervisor(emp['employee_id']);
                  if (emp['is_admin'] != isAdmin)
                    await _api.toggleAdmin(emp['employee_id']);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  _refresh();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Employee updated')));
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('$e')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPasswordResetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _PasswordResetDialog(
        employee: _employee!,
        api: _api,
      ),
    );
  }

  void _confirmDelete() {
    final emp = _employee!;
    showDialog<bool>(
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
    ).then((confirmed) async {
      if (confirmed == true && mounted) {
        try {
          await _api.deleteEmployee(emp['employee_id']);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${emp['full_name']} deleted')));
            Navigator.pop(context, true);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('$e')));
          }
        }
      }
    });
  }

  Widget _badge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emp = _employee!;
    final isActive = emp['is_active'] != false;

    return Scaffold(
      appBar: AppBar(
        title: Text(emp['full_name'] ?? 'Employee Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showEditDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: context.error,
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── Profile Header ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: context.primary.withValues(alpha: 0.2),
                          backgroundImage: _empPhoto(emp) != null
                              ? NetworkImage(_empPhoto(emp)!)
                              : null,
                          child: _empPhoto(emp) == null
                              ? Text(
                                  ((emp['full_name'] as String?) ?? '?')[0]
                                      .toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: context.primary),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(emp['full_name'] ?? '',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: context.onSurface)),
                        const SizedBox(height: 4),
                        Text(emp['employee_id'] ?? '',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: context.outline,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isActive ? context.success : context.error)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color:
                                    (isActive ? context.success : context.error)
                                        .withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color:
                                    isActive ? context.success : context.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Info Card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Employee Information',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: context.onSurface,
                                height: 1.5)),
                        const SizedBox(height: 12),
                        _InfoItem(
                            label: 'Position', value: emp['position'] ?? 'N/A'),
                        _InfoItem(label: 'Email', value: emp['email'] ?? 'N/A'),
                        _InfoItem(
                            label: 'Department',
                            value: emp['department_name'] ??
                                emp['department_id'] ??
                                'N/A'),
                        _InfoItem(
                            label: 'Employee ID',
                            value: emp['employee_id'] ?? 'N/A'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Roles Card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Roles & Permissions',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: context.onSurface,
                                height: 1.5)),
                        const SizedBox(height: 12),
                        Wrap(
                          children: [
                            if (emp['is_admin'] == true)
                              _badge('Admin', context.error),
                            if (emp['is_supervisor'] == true)
                              _badge('Supervisor', QuickpassColors.tertiary),
                            if (emp['is_security'] == true)
                              _badge('Security', context.warning),
                            if (emp['is_admin'] != true &&
                                emp['is_supervisor'] != true &&
                                emp['is_security'] != true)
                              Text('Standard Employee',
                                  style: TextStyle(
                                      color: context.neutralGray,
                                      fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Actions ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quick Actions',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: context.onSurface,
                                height: 1.5)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _showPasswordResetDialog,
                            icon: const Icon(Icons.key, size: 18),
                            label: const Text('Reset Password'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final messenger = ScaffoldMessenger.of(context);
                              _api.toggleActive(emp['employee_id']).then((_) {
                                _refresh();
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                        content: Text(isActive
                                            ? 'Employee deactivated'
                                            : 'Employee activated')),
                                  );
                                }
                              }).catchError((_) {});
                            },
                            icon: Icon(
                                isActive
                                    ? Icons.block
                                    : Icons.check_circle_outline,
                                size: 18),
                            label: Text(isActive ? 'Deactivate' : 'Activate'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  isActive ? context.error : context.success,
                              side: BorderSide(
                                  color: isActive
                                      ? context.error
                                      : context.success),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PasswordResetDialog extends StatefulWidget {
  final Map<String, dynamic> employee;
  final ApiService api;

  const _PasswordResetDialog({
    required this.employee,
    required this.api,
  });

  @override
  State<_PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<_PasswordResetDialog> {
  late final TextEditingController _passCtl;

  @override
  void initState() {
    super.initState();
    _passCtl = TextEditingController();
  }

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
          Text('New password for ${widget.employee['full_name']}'),
          const SizedBox(height: 12),
          TextField(
              controller: _passCtl,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            if (_passCtl.text.length < 4) return;
            try {
              await widget.api.resetPassword(
                  widget.employee['employee_id'], _passCtl.text);
              if (!context.mounted) return;
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset')));
              }
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('$e')));
            }
          },
          child: const Text('Reset'),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.32,
              child: Text(label,
                  style: TextStyle(fontSize: 13, color: context.neutralGray))),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.onSurface))),
        ],
      ),
    );
  }
}
