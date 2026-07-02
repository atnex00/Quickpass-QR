import 'package:flutter/material.dart';
import '../../models/leave_request.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/qr_code_widget.dart';

class QrDisplayScreen extends StatelessWidget {
  final LeaveRequest leave;

  const QrDisplayScreen({super.key, required this.leave});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateStr = leave.leaveDate.toIso8601String().split('T').first;

    return Scaffold(
      appBar: const QuickpassAppBar(title: 'Gate Pass', showBack: true),
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
                        Icon(Icons.info_outline, color: colorScheme.primary, size: 18),
                        const SizedBox(width: 8),
                        Text('Leave Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: colorScheme.onSurface)),
                      ],
                    ),
                    const Divider(),
                    _detailRow('Date', dateStr, colorScheme),
                    _detailRow('Time', '${leave.startTime} - ${leave.endTime}', colorScheme),
                    _detailRow('Duration', leave.durationText, colorScheme),
                    _detailRow('Reason', leave.reason, colorScheme),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (leave.outQrCode != null)
              QrCodeWidget(
                qrData: leave.outQrCode!,
                label: AppConstants.outQrLabel,
                color: colorScheme.primary,
                date: dateStr,
                time: leave.startTime,
                priorScanTime: leave.outScanTime,
                employeeName: leave.employeeName,
                employeePosition: leave.employeePosition,
                isOut: true,
              ),
            const SizedBox(height: 16),
            if (leave.inQrCode != null)
              QrCodeWidget(
                qrData: leave.inQrCode!,
                label: AppConstants.inQrLabel,
                color: QuickpassQrColors.qrIn,
                date: dateStr,
                time: leave.endTime,
                priorScanTime: leave.inScanTime,
                employeeName: leave.employeeName,
                employeePosition: leave.employeePosition,
                isOut: false,
              ),
            if (!leave.hasQrCodes)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.qr_code, size: 64, color: colorScheme.outlineVariant),
                        const SizedBox(height: 12),
                        Text('QR codes are not available yet', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text('Approved leaves will show QR codes here', style: TextStyle(color: colorScheme.outline)),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 14, color: colorScheme.outline),
                const SizedBox(width: 6),
                Text(
                  'QR codes are valid \u00b115 minutes from scheduled time',
                  style: TextStyle(fontSize: 12, color: colorScheme.outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13))),
          Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: colorScheme.onSurface))),
        ],
      ),
    );
  }
}
