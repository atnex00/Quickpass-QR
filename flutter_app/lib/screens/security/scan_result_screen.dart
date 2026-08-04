import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scan_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../shared/settings_screen.dart';
import 'scan_history_screen.dart';

class ScanResultScreen extends StatefulWidget {

  const ScanResultScreen({super.key, required this.qrData});
  final String qrData;

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  ScanProvider? _scanProv;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scanProv = context.read<ScanProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _validate());
  }

  Future<void> _validate() async {
    final scanProv = context.read<ScanProvider>();
    scanProv.clearResult();
    await scanProv.validateScan(widget.qrData);
  }

  @override
  void dispose() {
    _scanProv?.clearResult();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanProv = context.watch<ScanProvider>();
    final isSuccess =
        scanProv.lastResult != null && scanProv.lastResult!['success'] == true;
    final data = isSuccess
        ? scanProv.lastResult!['data'] as Map<String, dynamic>?
        : null;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: scanProv.isLoading
                    ? [const Color(0xFF1E3A5F), const Color(0xFF0F1E33)]
                    : isSuccess
                        ? [const Color(0xFF064E3B), const Color(0xFF022C22)]
                        : [const Color(0xFF450A0A), const Color(0xFF1A0000)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: scanProv.isLoading
                      ? const LoadingIndicator(message: 'Validating QR code...')
                      : isSuccess
                          ? _buildSuccess(data)
                          : _buildError(scanProv.error ?? 'Invalid QR code'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: ColorFiltered(
                colorFilter: ColorFilter.mode(context.onSurface, BlendMode.srcIn),
                child:
                    Image.asset('assets/icon/app-icon.png', width: 16, height: 16)),
          ),
          const SizedBox(width: 8),
          const Text(
            'Quickpass',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            color: context.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) async {
              switch (value) {
                case 'settings':
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()));
                  break;
                case 'history':
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ScanHistoryScreen()));
                  break;
                case 'logout':
                  final errorColor = context.error;
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel')),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(
                              backgroundColor: errorColor),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    context.read<AuthProvider>().logout();
                  }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Consumer<AuthProvider>(
                  builder: (_, auth, __) => Text(
                    auth.user?.fullName ?? 'Guard',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: context.onSurface),
                  ),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings, color: context.onSurface),
                  title: const Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              PopupMenuItem(
                value: 'history',
                child: ListTile(
                  leading: Icon(Icons.history, color: context.onSurface),
                  title: const Text('Scan History'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: context.error),
                  title: Text('Logout', style: TextStyle(color: context.error)),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(Map<String, dynamic>? data) {
    final isOut = data?['type'] == 'OUT';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: context.success.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, size: 60, color: context.success),
            ),
            const SizedBox(height: 24),
            Text(
              isOut ? 'Exit Recorded' : 'Entry Recorded',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: (isOut ? context.primaryBlue : context.success)
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isOut ? 'OUT SCAN' : 'IN SCAN',
                style: TextStyle(
                  color: isOut ? context.primaryBlue : context.success,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            if (data != null) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _ResultRow(
                        label: 'Employee', value: data['employee_name'] ?? ''),
                    _ResultRow(label: 'ID', value: data['employee_id'] ?? ''),
                    if (data['position'] != null)
                      _ResultRow(label: 'Position', value: data['position']),
                    if (data['department_name'] != null)
                      _ResultRow(
                          label: 'Department', value: data['department_name']),
                    if (data['leave_date'] != null)
                      _ResultRow(label: 'Date', value: data['leave_date']),
                    _ResultRow(
                        label: 'Time',
                        value: '${data['start_time'] ?? '--'} - ${data['end_time'] ?? '--'}'),
                    _ResultRow(
                        label: 'Status', value: data['new_status'] ?? ''),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF064E3B),
                ),
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                child: const Text('Scan Next',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: context.error.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cancel, size: 60, color: context.error),
            ),
            const SizedBox(height: 24),
            const Text('Invalid QR Code',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Try Again',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: context.neutralGray)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: context.onSurface)),
          ),
        ],
      ),
    );
  }
}
