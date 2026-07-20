import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/theme.dart';
import '../../../services/api_service.dart';

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
        'is_supervisor': _isSupervisor,
        'is_admin': _isAdmin,
        'is_active': _isActive,
      });
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
