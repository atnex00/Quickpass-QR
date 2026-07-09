import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

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
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const _ProfileAppBar(),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _UserAvatarCard(user: user),
                  const SizedBox(height: 12),
                  _AccountInfoCard(user: user),
                  const SizedBox(height: 12),
                  _PersonalInfoForm(
                    nameCtl: _nameCtl,
                    posCtl: _posCtl,
                    emailCtl: _emailCtl,
                    passCtl: _passCtl,
                    saving: _saving,
                    onSave: _save,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAppBar extends StatelessWidget {
  const _ProfileAppBar();

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      toolbarHeight: 64,
      backgroundColor: context.primary,
      foregroundColor: context.onPrimary,
      automaticallyImplyLeading: false,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.onPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset('assets/icon/app-icon.png', width: 22, height: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'My Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: context.onPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.logout, color: context.onPrimary),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: FilledButton.styleFrom(backgroundColor: context.error),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        context.read<AuthProvider>().logout();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserAvatarCard extends StatelessWidget {
  final dynamic user;
  const _UserAvatarCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: context.primaryBlue.withValues(alpha: 0.1),
            child: Text(
              (user?.fullName ?? 'U')[0].toUpperCase(),
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: context.primaryBlue),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.fullName ?? '',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: context.onSurface)),
                Text(user?.position ?? '',
                  style: TextStyle(color: context.neutralGray, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  final dynamic user;
  const _AccountInfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account Information',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: context.onSurface)),
          Divider(color: context.outlineVariant),
          _ReadOnlyRow(label: 'Employee ID', value: user?.employeeId ?? ''),
          _ReadOnlyRow(label: 'Department', value: user?.departmentName ?? 'N/A'),
        ],
      ),
    );
  }
}

class _PersonalInfoForm extends StatelessWidget {
  final TextEditingController nameCtl;
  final TextEditingController posCtl;
  final TextEditingController emailCtl;
  final TextEditingController passCtl;
  final bool saving;
  final VoidCallback onSave;

  const _PersonalInfoForm({
    required this.nameCtl,
    required this.posCtl,
    required this.emailCtl,
    required this.passCtl,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Personal Information',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: context.onSurface)),
          Divider(color: context.outlineVariant),
          const SizedBox(height: 4),
          TextField(
            controller: nameCtl,
            decoration: const InputDecoration(labelText: 'Full Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: posCtl,
            decoration: const InputDecoration(labelText: 'Position'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailCtl,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passCtl,
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
              onPressed: saving ? null : onSave,
              style: FilledButton.styleFrom(
                backgroundColor: context.primary,
                foregroundColor: context.onPrimary,
              ),
              child: saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: MediaQuery.of(context).size.width * 0.3, child: Text(label, style: TextStyle(color: context.neutralGray, fontSize: 13))),
          Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: context.onSurface))),
        ],
      ),
    );
  }
}