import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/scan_provider.dart';
import '../../widgets/loading_indicator.dart';
import 'scanner_screen.dart';

class ScanResultScreen extends StatefulWidget {
  final String qrData;

  const ScanResultScreen({super.key, required this.qrData});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  @override
  void initState() {
    super.initState();
    _validate();
  }

  Future<void> _validate() async {
    final scanProv = context.read<ScanProvider>();
    await scanProv.validateScan(widget.qrData);
  }

  @override
  Widget build(BuildContext context) {
    final scanProv = context.watch<ScanProvider>();

    return Scaffold(
      body: SafeArea(
        child: scanProv.isLoading
            ? const LoadingIndicator(message: 'Validating QR code...')
            : scanProv.lastResult != null && scanProv.lastResult!['success'] == true
                ? _buildSuccess(scanProv.lastResult!['data'] as Map<String, dynamic>?)
                : _buildError(scanProv.error ?? 'Invalid QR code'),
      ),
    );
  }

  Widget _buildSuccess(Map<String, dynamic>? data) {
    final isOut = data?['type'] == 'OUT';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: QuickpassColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, size: 60, color: QuickpassColors.success),
            ),
            const SizedBox(height: 24),
            Text(
              isOut ? 'Exit Recorded' : 'Entry Recorded',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: QuickpassColors.onSurface),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: (isOut ? QuickpassColors.primary : QuickpassColors.success).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isOut ? 'OUT SCAN' : 'IN SCAN',
                style: TextStyle(
                  color: isOut ? QuickpassColors.primary : QuickpassColors.success,
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
                  color: QuickpassColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: QuickpassColors.outlineVariant),
                ),
                child: Column(
                  children: [
                    _resultRow('Employee', data['employee_name'] ?? ''),
                    _resultRow('ID', data['employee_id'] ?? ''),
                    _resultRow('Time', '${data['start_time']} - ${data['end_time']}'),
                    _resultRow('Status', data['new_status'] ?? ''),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ScannerScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: QuickpassColors.darkPrimary,
                  foregroundColor: QuickpassColors.darkOnPrimary,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Scan Next', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: QuickpassColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel, size: 60, color: QuickpassColors.error),
            ),
            const SizedBox(height: 24),
            const Text('Invalid QR Code', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: QuickpassColors.onSurface)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: QuickpassColors.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: QuickpassColors.onErrorContainer, fontSize: 14),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ScannerScreen())),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: QuickpassColors.neutralGray)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: QuickpassColors.onSurface)),
        ],
      ),
    );
  }
}
