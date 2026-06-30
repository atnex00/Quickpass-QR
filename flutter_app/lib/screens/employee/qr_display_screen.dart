import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/leave_request.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/qr_code_widget.dart';

class QrDisplayScreen extends StatelessWidget {
  final LeaveRequest leave;

  const QrDisplayScreen({super.key, required this.leave});

  @override
  Widget build(BuildContext context) {
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
                        const Icon(Icons.info_outline, color: QuickpassColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text('Leave Details', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ],
                    ),
                    const Divider(),
                    _detailRow('Date', dateStr),
                    _detailRow('Time', '${leave.startTime} - ${leave.endTime}'),
                    _detailRow('Duration', leave.durationText),
                    _detailRow('Reason', leave.reason),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // OUT QR Code
            if (leave.outQrCode != null)
              QrCodeWidget(
                qrData: leave.outQrCode!,
                label: AppConstants.outQrLabel,
                color: QuickpassColors.qrOut,
                date: dateStr,
                time: leave.startTime,
                priorScanTime: leave.outScanTime,
                employeeName: leave.employeeName,
                employeePosition: leave.employeePosition,
                isOut: true,
              ),

            const SizedBox(height: 16),

            // IN QR Code
            if (leave.inQrCode != null)
              QrCodeWidget(
                qrData: leave.inQrCode!,
                label: AppConstants.inQrLabel,
                color: QuickpassColors.qrIn,
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
                        Icon(Icons.qr_code, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('QR codes are not available yet', style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        const Text('Approved leaves will show QR codes here'),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  'QR codes are valid ±15 minutes from scheduled time',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: QuickpassColors.textSecondary, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
}
