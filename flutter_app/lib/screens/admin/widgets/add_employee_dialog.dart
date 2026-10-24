import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/api_service.dart';

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
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())) {
                      return 'Invalid email format';
                    }
                    return null;
                  }),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _passCtl,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.length < 8) return 'Min 8 characters';
                    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(v)) {
                      return 'Must contain uppercase, lowercase, and number';
                    }
                    return null;
                  }),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedDept.isNotEmpty ? _selectedDept : null,
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
