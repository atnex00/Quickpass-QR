import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/scan_log.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../utils/date_formatter.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  final _api = ApiService();
  List<ScanLog> _logs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 64,
            backgroundColor: QuickpassColors.darkPrimary,
            foregroundColor: QuickpassColors.darkOnPrimary,
            automaticallyImplyLeading: false,
            flexibleSpace: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: QuickpassColors.darkOnPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.qr_code_scanner, size: 18, color: QuickpassColors.darkOnPrimary),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Scan History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: QuickpassColors.darkOnPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.notifications_outlined, color: QuickpassColors.darkOnPrimary),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text('No new notifications'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: LoadingIndicator()))
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: QuickpassColors.error),
                      const SizedBox(height: 16),
                      const Text('Failed to load history',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: QuickpassColors.onSurface)),
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: QuickpassColors.neutralGray)),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _loadHistory,
                        style: FilledButton.styleFrom(
                          backgroundColor: QuickpassColors.darkPrimary,
                          foregroundColor: QuickpassColors.darkOnPrimary,
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
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner_outlined, size: 64, color: QuickpassColors.outlineVariant),
                    const SizedBox(height: 12),
                    Text('No scan history',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: QuickpassColors.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text('Scanned QR codes will appear here',
                      style: TextStyle(color: QuickpassColors.neutralGray, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final log = _logs[index];
                    final isSuccess = log.isValid;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: QuickpassColors.outlineVariant),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              decoration: BoxDecoration(
                                color: isSuccess ? QuickpassColors.success : QuickpassColors.error,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
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
                                            ? QuickpassColors.success.withValues(alpha: 0.12)
                                            : QuickpassColors.error.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        isSuccess ? Icons.check_circle : Icons.cancel,
                                        color: isSuccess ? QuickpassColors.success : QuickpassColors.error,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            log.employeeName ?? 'Unknown',
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: QuickpassColors.onSurface),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${log.qrType} \u2022 ${DateFormatter.formatDateTime(log.scanTime)}',
                                            style: const TextStyle(fontSize: 12, color: QuickpassColors.neutralGray),
                                          ),
                                          if (log.validationMessage != null)
                                            Text(
                                              log.validationMessage!,
                                              style: TextStyle(fontSize: 11, color: isSuccess ? QuickpassColors.success : QuickpassColors.error),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isSuccess
                                            ? QuickpassColors.success.withValues(alpha: 0.12)
                                            : QuickpassColors.error.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        isSuccess ? 'Valid' : 'Invalid',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isSuccess ? QuickpassColors.success : QuickpassColors.error,
                                        ),
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
                  },
                  childCount: _logs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
