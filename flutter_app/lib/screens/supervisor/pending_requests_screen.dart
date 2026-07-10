import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/leave_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../../providers/supervisor_provider.dart';
import '../../widgets/custom_widgets.dart';
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
    final isAdmin = context.select((AuthProvider a) => a.isAdmin);

    return Scaffold(
      appBar: AppBar(
        title: Text('Pending Requests (${supProv.pendingCount})'),
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
                ? const EmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'No pending requests',
                    subtitle: 'All caught up!',
                  )
                : ListView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      if (supProv.pendingRequests.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Text('Pending Requests',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.onSurface)),
                        ),
                        ...supProv.pendingRequests.map((leave) =>
                            _PendingCard(leave: leave, isAdmin: isAdmin)),
                        const SizedBox(height: 16),
                      ],
                      if (supProv.approvedLeaves.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Text('Approved Leaves',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.onSurface)),
                        ),
                        ...supProv.approvedLeaves.map((leave) =>
                            _ApprovedCard(leave: leave, isAdmin: isAdmin)),
                      ],
                    ],
                  ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final LeaveRequest leave;
  final bool isAdmin;

  const _PendingCard({required this.leave, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outlineVariant),
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
                  backgroundColor: context.primary.withValues(alpha: 0.2),
                  child: Text(
                    leave.employeeName.isNotEmpty
                        ? leave.employeeName.substring(0, 1).toUpperCase()
                        : '?',
                    style: TextStyle(
                        color: context.primary, fontWeight: FontWeight.w700),
                  ),
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
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14, color: context.neutralGray),
                  const SizedBox(width: 4),
                  Text(DateFormatter.formatDate(leave.leaveDate),
                      style:
                          TextStyle(fontSize: 13, color: context.neutralGray)),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 14, color: context.neutralGray),
                  const SizedBox(width: 4),
                  Text('${leave.startTime} - ${leave.endTime}',
                      style:
                          TextStyle(fontSize: 13, color: context.neutralGray)),
                ],
              ),
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
                if (isAdmin)
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: context.error, size: 20),
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(context),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _showRejectDialog(context),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.error,
                    side: BorderSide(color: context.error),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _approve(context),
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
    );
  }

  void _approve(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              decoration: const InputDecoration(
                  hintText: 'Enter reason...', labelText: 'Rejection reason'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, ctrl.text.trim());
            },
            style: FilledButton.styleFrom(backgroundColor: context.error),
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
        content: Text(
            'Delete leave for ${leave.employeeName}? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: context.error),
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
            SnackBar(behavior: SnackBarBehavior.floating, content: Text('$e')),
          );
        }
      }
    }
  }
}

class _ApprovedCard extends StatelessWidget {
  final LeaveRequest leave;
  final bool isAdmin;

  const _ApprovedCard({required this.leave, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outlineVariant),
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
                  backgroundColor: context.success.withValues(alpha: 0.15),
                  child: Text(
                    leave.employeeName.isNotEmpty
                        ? leave.employeeName.substring(0, 1).toUpperCase()
                        : '?',
                    style: TextStyle(
                        color: context.success, fontWeight: FontWeight.w700),
                  ),
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
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14, color: context.neutralGray),
                  const SizedBox(width: 4),
                  Text(DateFormatter.formatDate(leave.leaveDate),
                      style:
                          TextStyle(fontSize: 13, color: context.neutralGray)),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 14, color: context.neutralGray),
                  const SizedBox(width: 4),
                  Text('${leave.startTime} - ${leave.endTime}',
                      style:
                          TextStyle(fontSize: 13, color: context.neutralGray)),
                ],
              ),
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
                if (isAdmin)
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: context.error, size: 20),
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(context),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _confirmRevoke(context),
                  icon: const Icon(Icons.undo, size: 18),
                  label: const Text('Revoke'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.warning,
                    side: BorderSide(color: context.warning),
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
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
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
        content: Text(
            'Delete leave for ${leave.employeeName}? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: context.error),
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
            SnackBar(behavior: SnackBarBehavior.floating, content: Text('$e')),
          );
        }
      }
    }
  }
}
