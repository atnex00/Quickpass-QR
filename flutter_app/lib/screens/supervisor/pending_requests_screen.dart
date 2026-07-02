import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/leave_request.dart';
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
      context.read<SupervisorProvider>().loadPendingRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final supProv = context.watch<SupervisorProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Pending Requests (${supProv.pendingCount})'),
      ),
      body: RefreshIndicator(
        onRefresh: () => supProv.loadPendingRequests(),
        child: supProv.isLoading
            ? const Center(child: CircularProgressIndicator())
            : supProv.pendingRequests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, size: 64, color: colorScheme.outlineVariant),
                        const SizedBox(height: 12),
                        Text('No pending requests', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('All caught up!', style: TextStyle(color: colorScheme.outline)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: supProv.pendingRequests.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final leave = supProv.pendingRequests[index];
                      return _PendingCard(leave: leave, colorScheme: colorScheme);
                    },
                  ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final LeaveRequest leave;
  final ColorScheme colorScheme;

  const _PendingCard({required this.leave, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.primary,
                  child: Text(
                    leave.employeeName.substring(0, 1).toUpperCase(),
                    style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(leave.employeeName, style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                      if (leave.employeePosition != null)
                        Text(leave.employeePosition!, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
                StatusBadge(status: leave.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(DateFormatter.formatDate(leave.leaveDate), style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('${leave.startTime} - ${leave.endTime}', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 6),
            Text(leave.reason, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showRejectDialog(context),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(color: colorScheme.error),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _approve(context),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Approve'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
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
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
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
            content: Text('Rejected leave for ${leave.employeeName}'),
          ),
        );
      }
    }

    ctrl.dispose();
  }
}
