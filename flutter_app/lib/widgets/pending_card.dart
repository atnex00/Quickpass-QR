import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../config/theme.dart';
import '../models/leave_request.dart';
import '../providers/leave_provider.dart';
import '../providers/supervisor_provider.dart';
import '../utils/date_formatter.dart';
import 'status_badge.dart';

class PendingCard extends StatelessWidget {
  const PendingCard({
    super.key,
    required this.leave,
    this.showAccentBorder = false,
    this.showAdminActions = false,
  });

  final LeaveRequest leave;
  final bool showAccentBorder;
  final bool showAdminActions;

  static String? _photo(LeaveRequest l) => AppConfig.photoUrl(l.employeePhoto);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outlineVariant),
      ),
      child: Stack(
        children: [
          if (showAccentBorder)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: context.warning,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
            ),
          Padding(
            padding: showAccentBorder
                ? const EdgeInsets.fromLTRB(16, 14, 14, 14)
                : const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: context.primary.withValues(alpha: 0.2),
                      backgroundImage: _photo(leave) != null
                          ? NetworkImage(_photo(leave)!)
                          : null,
                      child: _photo(leave) == null
                          ? Text(
                              leave.employeeName.isNotEmpty
                                  ? leave.employeeName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                  color: context.primary,
                                  fontWeight: FontWeight.w700),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(leave.employeeName,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: context.onSurface)),
                          if (leave.employeePosition != null)
                            Text(leave.employeePosition!,
                                style: TextStyle(
                                    color: context.neutralGray, fontSize: 12)),
                        ],
                      ),
                    ),
                    StatusBadge(status: leave.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 14, color: context.neutralGray),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        DateFormatter.formatDate(leave.leaveDate),
                        style:
                            TextStyle(fontSize: 13, color: context.neutralGray),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time,
                        size: 14, color: context.neutralGray),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${leave.startTime} - ${leave.endTime}',
                        style:
                            TextStyle(fontSize: 13, color: context.neutralGray),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(leave.reason,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.neutralGray, fontSize: 13)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (showAdminActions)
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: context.error, size: 20),
                        tooltip: 'Delete',
                        onPressed: () => _confirmDelete(context),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => showRejectDialog(context, leave),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.error,
                        side: BorderSide(color: context.error),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => approveLeave(context, leave),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: FilledButton.styleFrom(
                        backgroundColor: context.primary,
                        foregroundColor: context.onPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> approveLeave(
      BuildContext context, LeaveRequest leave) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Approve Leave?'),
        content: Text(
            '${leave.employeeName} \u2014 ${DateFormatter.formatDateApi(leave.leaveDate)} (${leave.startTime} - ${leave.endTime})'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      final supProv = context.read<SupervisorProvider>();
      final approved = await supProv.approveLeave(leave.leaveId);
      if (context.mounted) {
        if (approved != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Approved leave for ${leave.employeeName}'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(supProv.error ?? 'Failed to approve leave'),
            ),
          );
        }
      }
    }
  }

  static Future<void> showRejectDialog(
      BuildContext context, LeaveRequest leave) async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Reject Leave'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reason for rejecting ${leave.employeeName}?'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                  hintText: 'Enter reason...',
                  labelText: 'Rejection reason'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, ctrl.text.trim());
            },
            style:
                FilledButton.styleFrom(backgroundColor: context.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason != null && context.mounted) {
      final supProv = context.read<SupervisorProvider>();
      final rejected = await supProv.rejectLeave(leave.leaveId, reason);
      if (context.mounted) {
        if (rejected != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Rejected leave for ${leave.employeeName}'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(supProv.error ?? 'Failed to reject leave'),
            ),
          );
        }
      }
    }

    ctrl.dispose();
  }

  void _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Leave'),
        content: Text(
            'Delete leave for ${leave.employeeName}? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                FilledButton.styleFrom(backgroundColor: context.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<LeaveProvider>().deleteLeave(leave.leaveId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('Leave deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('Failed to delete leave')),
          );
        }
      }
    }
  }
}
