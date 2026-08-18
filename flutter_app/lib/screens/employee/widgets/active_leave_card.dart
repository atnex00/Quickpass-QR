import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/theme.dart';
import '../../../models/leave_request.dart';
import '../../../providers/leave_provider.dart';
import '../../../utils/date_formatter.dart';
import '../../../utils/responsive.dart';
import '../../../widgets/custom_widgets.dart';
import '../../../widgets/expandable_reason.dart';
import '../qr_display_screen.dart';

class ActiveLeaveCard extends StatelessWidget {
  const ActiveLeaveCard({super.key, required this.leave});
  final LeaveRequest leave;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outlineVariant),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: context.success,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              leave.status == LeaveStatus.approved
                                  ? 'APPROVED'
                                  : 'ACTIVE PASS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: context.success,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ExpandableReason(
                            text: leave.reason,
                            style: TextStyle(
                              fontSize: responsiveFontSize(context, 24),
                              fontWeight: FontWeight.w700,
                              color: context.onSurface,
                              letterSpacing: -0.01,
                              height: 1.33,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle, color: context.success, size: 28),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      InfoRow(
                          label: 'Validity',
                          value:
                              '${DateFormatter.formatDateApi(leave.leaveDate)} \u2022 ${leave.startTime} - ${leave.endTime}'),
                      const SizedBox(height: 8),
                      const InfoRow(
                          label: 'Gate Status', value: 'Authorized Out'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      if (leave.hasQrCodes) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QrDisplayScreen(leave: leave),
                          ),
                        );
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_2,
                            size: 20, color: context.onPrimary),
                        const SizedBox(width: 8),
                        const Text(
                          'View QR Pass',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (leave.status == LeaveStatus.approved &&
                    leave.outScanTime == null &&
                    !leave.isExpired) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Cancel Leave'),
                            content: Text(
                                'Cancel your leave for ${DateFormatter.formatDate(leave.leaveDate)}?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('No')),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: FilledButton.styleFrom(
                                    backgroundColor: context.warning),
                                child: const Text('Yes, Cancel'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          try {
                            await context
                                .read<LeaveProvider>()
                                .cancelLeave(leave.leaveId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    behavior: SnackBarBehavior.floating,
                                    content: Text('Leave cancelled')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    behavior: SnackBarBehavior.floating,
                                    content: Text('$e')),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Cancel Leave'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.warning,
                        side: BorderSide(color: context.warning),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
