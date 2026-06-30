import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/leave_request.dart';
import '../../providers/supervisor_provider.dart';
import '../../widgets/status_badge.dart';
import '../../utils/date_formatter.dart';
import 'approve_reject_screen.dart';

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
                        Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('No pending requests', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                        const SizedBox(height: 4),
                        const Text('All caught up!', style: TextStyle(color: QuickpassColors.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: supProv.pendingRequests.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final leave = supProv.pendingRequests[index];
                      return _PendingCard(leave: leave);
                    },
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
                  backgroundColor: QuickpassColors.primary,
                  child: Text(
                    leave.employeeName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(leave.employeeName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (leave.employeePosition != null)
                        Text(leave.employeePosition!, style: const TextStyle(color: QuickpassColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                StatusBadge(status: leave.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: QuickpassColors.textSecondary),
                const SizedBox(width: 4),
                Text(DateFormatter.formatDate(leave.leaveDate), style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 14, color: QuickpassColors.textSecondary),
                const SizedBox(width: 4),
                Text('${leave.startTime} - ${leave.endTime}', style: const TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            Text(leave.reason, style: const TextStyle(color: QuickpassColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showRejectDialog(context),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(foregroundColor: QuickpassColors.error, side: const BorderSide(color: QuickpassColors.error)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _approve(context),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(backgroundColor: QuickpassColors.success, foregroundColor: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _approve(BuildContext context) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Approve Leave?'),
        content: Text('${leave.employeeName} — ${leave.leaveDate.toIso8601String().split('T').first} (${leave.startTime} - ${leave.endTime})'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<SupervisorProvider>().approveLeave(leave.leaveId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: QuickpassColors.success, foregroundColor: Colors.white),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await context.read<SupervisorProvider>().rejectLeave(leave.leaveId, ctrl.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: QuickpassColors.error, foregroundColor: Colors.white),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
