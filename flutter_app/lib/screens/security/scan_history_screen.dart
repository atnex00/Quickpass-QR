import 'package:flutter/material.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: _isLoading
            ? const LoadingIndicator()
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                          const SizedBox(height: 16),
                          Text('Failed to load history', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                          const SizedBox(height: 8),
                          Text(_error!, style: TextStyle(color: colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 24),
                          FilledButton(onPressed: _loadHistory, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  )
                : _logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.qr_code_scanner_outlined, size: 64, color: colorScheme.outlineVariant),
                            const SizedBox(height: 12),
                            Text('No scan history', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Text('Scanned QR codes will appear here', style: TextStyle(color: colorScheme.outline, fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _logs.length,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          final isSuccess = log.isValid;
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isSuccess
                                          ? colorScheme.primaryContainer
                                          : colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isSuccess ? Icons.check_circle : Icons.cancel,
                                      color: isSuccess ? colorScheme.primary : colorScheme.error,
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
                                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colorScheme.onSurface),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${log.qrType} \u2022 ${DateFormatter.formatDateTime(log.scanTime)}',
                                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                        ),
                                        if (log.validationMessage != null)
                                          Text(
                                            log.validationMessage!,
                                            style: TextStyle(fontSize: 11, color: isSuccess ? colorScheme.primary : colorScheme.error),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isSuccess
                                          ? colorScheme.primaryContainer
                                          : colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      isSuccess ? 'Valid' : 'Invalid',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isSuccess ? colorScheme.primary : colorScheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
