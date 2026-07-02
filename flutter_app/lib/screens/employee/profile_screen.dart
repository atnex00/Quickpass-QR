import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameCtl;
  late TextEditingController _posCtl;
  late TextEditingController _emailCtl;
  late TextEditingController _passCtl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtl = TextEditingController(text: user?.fullName ?? '');
    _posCtl = TextEditingController(text: user?.position ?? '');
    _emailCtl = TextEditingController(text: user?.email ?? '');
    _passCtl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _posCtl.dispose();
    _emailCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final data = <String, dynamic>{};
    final user = context.read<AuthProvider>().user;
    if (_nameCtl.text != user?.fullName) data['full_name'] = _nameCtl.text;
    if (_posCtl.text != user?.position) data['position'] = _posCtl.text;
    if (_emailCtl.text != user?.email) data['email'] = _emailCtl.text;
    if (_passCtl.text.isNotEmpty) data['password'] = _passCtl.text;

    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes to save')),
      );
      return;
    }

    setState(() => _saving = true);
    final ok = await context.read<AuthProvider>().updateProfile(data);
    setState(() => _saving = false);

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      _passCtl.clear();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<AuthProvider>().error ?? 'Could not update profile'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: const QuickpassAppBar(title: 'My Profile', showBack: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: colorScheme.primary,
                          child: Text(
                            (user?.fullName ?? 'U')[0].toUpperCase(),
                            style: TextStyle(fontSize: 28, color: colorScheme.onPrimary, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user?.fullName ?? '', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: colorScheme.onSurface)),
                              Text(user?.position ?? '', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Account Information', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colorScheme.onSurface)),
                    const Divider(),
                    _readOnlyRow('Employee ID', user?.employeeId ?? '', colorScheme),
                    _readOnlyRow('Department', user?.departmentName ?? 'N/A', colorScheme),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Personal Information', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colorScheme.onSurface)),
                    const Divider(),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameCtl,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _posCtl,
                      decoration: const InputDecoration(labelText: 'Position'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailCtl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passCtl,
                      decoration: const InputDecoration(
                        labelText: 'New Password (leave blank to keep)',
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Save Changes'),
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

  Widget _readOnlyRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13))),
          Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: colorScheme.onSurface))),
        ],
      ),
    );
  }
}
