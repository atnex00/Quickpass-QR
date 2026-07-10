import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/scan_log.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/loading_indicator.dart';
import '../../utils/date_formatter.dart';
import 'scanner_screen.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  late final ApiService _api;
  List<ScanLog> _logs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiService>();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getScanHistory();
      _logs = (data['data'] as List).map((j) => ScanLog.fromJson(j)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHistory,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                toolbarHeight: 64,
                automaticallyImplyLeading: false,
                flexibleSpace: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon:
                              Icon(Icons.arrow_back, color: context.onPrimary),
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ScannerScreen()),
                          ),
                        ),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: context.onPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Image.asset('assets/icon/app-icon.png',
                              width: 16, height: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Quickpass',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: context.onPrimary),
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: context.onPrimary),
                          color: context.surface,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          onSelected: (value) async {
                            if (value == 'logout') {
                              final errorColor = context.error;
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  title: const Text('Logout'),
                                  content: const Text(
                                      'Are you sure you want to logout?'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
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
                                      fontWeight: FontWeight.w600,
                                      color: context.onSurface),
                                ),
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'logout',
                              child: ListTile(
                                leading:
                                    Icon(Icons.logout, color: context.error),
                                title: Text('Logout',
                                    style: TextStyle(color: context.error)),
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                    child: Center(child: LoadingIndicator()))
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48, color: context.error),
                          const SizedBox(height: 16),
                          Text('Failed to load history',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: context.onSurface)),
                          const SizedBox(height: 8),
                          Text(_error!,
                              style: TextStyle(color: context.neutralGray)),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _loadHistory,
                            style: FilledButton.styleFrom(
                              backgroundColor: context.primary,
                              foregroundColor: context.onPrimary,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_logs.isEmpty)
                SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.qr_code_scanner_outlined,
                    title: 'No scan history',
                    subtitle: 'Scanned QR codes will appear here',
                    action: FilledButton.icon(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ScannerScreen()),
                      ),
                      icon: const Icon(Icons.qr_code_scanner, size: 18),
                      label: const Text('Scan QR'),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == 0) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: context.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.outlineVariant),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.qr_code_scanner,
                                    size: 28, color: context.primaryBlue),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${_logs.length}',
                                        style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                            color: context.onSurface)),
                                    Text('Total Scans',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: context.neutralGray)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }
                        final logIndex = index - 1;
                        final log = _logs[logIndex];
                        final isSuccess = log.isValid;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: context.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.outlineVariant),
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  decoration: BoxDecoration(
                                    color: isSuccess
                                        ? context.success
                                        : context.error,
                                    borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        bottomLeft: Radius.circular(12)),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: isSuccess
                                                ? context.success
                                                    .withValues(alpha: 0.12)
                                                : context.error
                                                    .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                              isSuccess
                                                  ? Icons.check_circle
                                                  : Icons.cancel,
                                              color: isSuccess
                                                  ? context.success
                                                  : context.error,
                                              size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  log.employeeName ?? 'Unknown',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                      color:
                                                          context.onSurface)),
                                              const SizedBox(height: 2),
                                              Text(
                                                  '${log.qrType} \u2022 ${DateFormatter.formatDateTime(log.scanTime)}',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          context.neutralGray)),
                                              if (log.validationMessage != null)
                                                Text(log.validationMessage!,
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: isSuccess
                                                            ? context.success
                                                            : context.error)),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isSuccess
                                                ? context.success
                                                    .withValues(alpha: 0.12)
                                                : context.error
                                                    .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                              isSuccess ? 'Valid' : 'Invalid',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: isSuccess
                                                      ? context.success
                                                      : context.error)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: _logs.length + 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
