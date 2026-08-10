import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/theme.dart';
import '../../../models/leave_request.dart';
import '../../../providers/leave_provider.dart';
import '../../../utils/date_formatter.dart';
import '../../../utils/responsive.dart';
import '../../../widgets/custom_widgets.dart';
import '../qr_display_screen.dart';
import '../request_leave_screen.dart';

class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({
    super.key,
    required this.isLoading,
    required this.history,
    this.error,
    required this.onSeeAll,
  });
  final bool isLoading;
  final List<LeaveRequest> history;
  final String? error;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: responsiveFontSize(context, 16),
                fontWeight: FontWeight.w600,
                color: context.onSurface,
                height: 1.5,
              ),
            ),
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'See All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ))
        else if (error != null)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 40, color: context.error),
                const SizedBox(height: 8),
                Text(error!, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: context.error)),
              ],
            ),
          )
        else if (history.isEmpty)
          EmptyState(
            icon: Icons.inbox_outlined,
            title: 'No recent activity',
            isOffline: context.read<LeaveProvider>().fromCache,
          )
        else ...[
          if (history.firstOrNull?.isExpired == true) ...[
            _ExpiredNotice(
              onRequestAgain: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RequestLeaveScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
          ...history.take(10).map((leave) => _ActivityCard(leave: leave)),
        ],
      ],
    );
  }
}

class _ExpiredNotice extends StatelessWidget {
  const _ExpiredNotice({required this.onRequestAgain});
  final VoidCallback onRequestAgain;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_off_outlined, size: 18, color: context.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your leave pass has expired',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'The exit QR wasn\u2019t scanned in time, so the pass can no longer be used. You can submit a new request.',
            style: TextStyle(
              fontSize: 12,
              color: context.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRequestAgain,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              foregroundColor: context.error,
            ),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text(
              'Request Again',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.leave});
  final LeaveRequest leave;

  IconData _iconForReason(String reason) {
    final r = reason.toLowerCase();
    if (r.contains('sick') || r.contains('medical')) return Icons.event_busy;
    if (r.contains('vacation') || r.contains('vacation leave')) {
      return Icons.flight_takeoff;
    }
    if (r.contains('casual')) return Icons.work_off;
    return Icons.event_note;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Hero(
      tag: ValueKey('qr-leave-${leave.leaveId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.outlineVariant),
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (leave.hasQrCodes && !leave.isExpired) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => QrDisplayScreen(leave: leave)));
              }
            },
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    _iconForReason(leave.reason),
                    size: 22,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leave.reason,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: responsiveFontSize(context, 14),
                          fontWeight: FontWeight.w600,
                          color: context.onSurface,
                          height: 1.43,
                        ),
                      ),
                      Text(
                        DateFormatter.formatDateApi(leave.leaveDate),
                        style: TextStyle(
                          fontSize: 14,
                          color: context.onSurfaceVariant,
                          height: 1.43,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (leave.isExpired
                            ? context.error
                            : leave.status.color(context))
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    leave.isExpired ? 'Expired' : leave.status.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: leave.isExpired
                          ? context.error
                          : leave.status.color(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
