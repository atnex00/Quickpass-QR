import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/leave_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../../providers/supervisor_provider.dart';
import '../../widgets/status_badge.dart';
import '../../utils/date_formatter.dart';

class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({super.key});

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<SupervisorProvider>();
      prov.loadPendingRequests();
      prov.loadApprovedLeaves();
    });
  }

  @override
  Widget build(BuildContext context) {
    final supProv = context.watch<SupervisorProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Pending Requests (${supProv.pendingCount})'),
        backgroundColor: QuickpassColors.darkPrimary,
        foregroundColor: QuickpassColors.darkOnPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final prov = context.read<SupervisorProvider>();
          await Future.wait([
            prov.loadPendingRequests(),
            prov.loadApprovedLeaves(),
          ]);
        },
        child: supProv.isLoading
            ? const Center(child: CircularProgressIndicator())
            : supProv.pendingRequests.isEmpty && supProv.approvedLeaves.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, size: 64, color: QuickpassColors.outlineVariant),
                        SizedBox(height: 12),
                        Text('No pending requests', style: TextStyle(color: QuickpassColors.onSurfaceVariant, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('All caught up!', style: TextStyle(color: QuickpassColors.neutralGray)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      if (supProv.pendingRequests.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 8),
                          child: Text('Pending Requests',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: QuickpassColors.onSurface)),
                        ),
                        ...supProv.pendingRequests.map((leave) => _PendingCard(leave: leave)),
                        const SizedBox(height: 16),
                      ],
                      if (supProv.approvedLeaves.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 8),
                          child: Text('Approved Leaves',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: QuickpassColors.onSurface)),
                        ),
                        ...supProv.approvedLeaves.map((leave) => _ApprovedCard(leave: leave)),
                      ],
                    ],
                  ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final LeaveRequest leave;

  const _PendingCard({required this.leave});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: QuickpassColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QuickpassColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: QuickpassColors.darkPrimary.withValues(alpha: 0.2),
                  child: Text(
                    leave.employeeName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: QuickpassColors.darkPrimary, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(leave.employeeName, style: const TextStyle(fontWeight: FontWeight.w600, color: QuickpassColors.onSurface)),
                      if (leave.employeePosition != null)
                        Text(leave.employeePosition!, style: const TextStyle(color: QuickpassColors.neutralGray, fontSize: 12)),
                    ],
                  ),
                ),
                StatusBadge(status: leave.status),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: QuickpassColors.neutralGray),
                  const SizedBox(width: 4),
                  Text(DateFormatter.formatDate(leave.leaveDate), style: const TextStyle(fontSize: 13, color: QuickpassColors.neutralGray)),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 14, color: QuickpassColors.neutralGray),
                  const SizedBox(width: 4),
                  Text('${leave.startTime} - ${leave.endTime}', style: const TextStyle(fontSize: 13, color: QuickpassColors.neutralGray)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(leave.reason, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: QuickpassColors.neutralGray, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (context.watch<AuthProvider>().isAdmin)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: QuickpassColors.error, size: 20),
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(context),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _showRejectDialog(context),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: QuickpassColors.error,
                    side: const BorderSide(color: QuickpassColors.error),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _approve(context),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Approve'),
                  style: FilledButton.styleFrom(
                    backgroundColor: QuickpassColors.darkPrimary,
                    foregroundColor: QuickpassColors.darkOnPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _approve(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Approve Leave?'),
        content: Text('${leave.employeeName} \u2014 ${leave.leaveDate.toIso8601String().split('T').first} (${leave.startTime} - ${leave.endTime})'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      final supProv = context.read<SupervisorProvider>();
      await supProv.approveLeave(leave.leaveId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Approved leave for ${leave.employeeName}'),
          ),
        );
      }
    }
  }

  void _showRejectDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Reject Leave'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reason for rejecting ${leave.employeeName}?'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(hintText: 'Enter reason...', labelText: 'Rejection reason'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, ctrl.text.trim());
            },
            style: FilledButton.styleFrom(backgroundColor: QuickpassColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason != null && context.mounted) {
      final supProv = context.read<SupervisorProvider>();
      await supProv.rejectLeave(leave.leaveId, reason);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Rejected leave for ${leave.employeeName}'),
          ),
        );
      }
    }

    ctrl.dispose();
  }

  void _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Leave'),
        content: Text('Delete leave for ${leave.employeeName}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: QuickpassColors.error),
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
            const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Leave deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(behavior: SnackBarBehavior.floating, content: Text('$e')),
          );
        }
      }
    }
  }
}

class _ApprovedCard extends StatelessWidget {
  final LeaveRequest leave;

  const _ApprovedCard({required this.leave});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: QuickpassColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QuickpassColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: QuickpassColors.success.withValues(alpha: 0.15),
                  child: Text(
                    leave.employeeName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: QuickpassColors.success, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(leave.employeeName, style: const TextStyle(fontWeight: FontWeight.w600, color: QuickpassColors.onSurface)),
                      if (leave.employeePosition != null)
                        Text(leave.employeePosition!, style: const TextStyle(color: QuickpassColors.neutralGray, fontSize: 12)),
                    ],
                  ),
                ),
                StatusBadge(status: leave.status),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: QuickpassColors.neutralGray),
                  const SizedBox(width: 4),
                  Text(DateFormatter.formatDate(leave.leaveDate), style: const TextStyle(fontSize: 13, color: QuickpassColors.neutralGray)),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 14, color: QuickpassColors.neutralGray),
                  const SizedBox(width: 4),
                  Text('${leave.startTime} - ${leave.endTime}', style: const TextStyle(fontSize: 13, color: QuickpassColors.neutralGray)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(leave.reason, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: QuickpassColors.neutralGray, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (context.watch<AuthProvider>().isAdmin)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: QuickpassColors.error, size: 20),
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(context),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _confirmRevoke(context),
                  icon: const Icon(Icons.undo, size: 18),
                  label: const Text('Revoke'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: QuickpassColors.warning,
                    side: const BorderSide(color: QuickpassColors.warning),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRevoke(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Revoke Approval?'),
        content: Text('Move ${leave.employeeName}\'s leave back to pending?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      final supProv = context.read<SupervisorProvider>();
      await supProv.revokeApproval(leave.leaveId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Revoked approval for ${leave.employeeName}'),
          ),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Leave'),
        content: Text('Delete leave for ${leave.employeeName}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: QuickpassColors.error),
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
            const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Leave deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(behavior: SnackBarBehavior.floating, content: Text('$e')),
          );
        }
      }
    }
  }
}
