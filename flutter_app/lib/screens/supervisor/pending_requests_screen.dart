import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../models/leave_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../../providers/supervisor_provider.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/expandable_reason.dart';
import '../../widgets/pending_card.dart';
import '../../widgets/shimmer_list.dart';
import '../../widgets/status_badge.dart';

class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({super.key});

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  int _segment = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<SupervisorProvider>();
      prov.loadPendingRequests();
      prov.loadApprovedLeaves();
      prov.loadSupervisorHistory();
    });
  }

  Future<void> _refresh() async {
    final prov = context.read<SupervisorProvider>();
    await Future.wait([
      prov.loadPendingRequests(),
      prov.loadApprovedLeaves(),
      prov.loadSupervisorHistory(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final supProv = context.watch<SupervisorProvider>();
    final isAdmin = context.select((AuthProvider a) => a.isAdmin);

    return Scaffold(
      appBar: AppBar(
        title: Text('Requests (${supProv.pendingCount})'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('Pending'),
                    icon: Icon(Icons.inbox_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Approved'),
                    icon: Icon(Icons.check_circle_outline, size: 16),
                  ),
                  ButtonSegment(
                    value: 2,
                    label: Text('History'),
                    icon: Icon(Icons.history, size: 16),
                  ),
                ],
                selected: {_segment},
                onSelectionChanged: (s) => setState(() => _segment = s.first),
                showSelectedIcon: false,
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return QuickpassColors.darkPrimary.withValues(alpha: 0.12);
                    }
                    return Colors.transparent;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    return states.contains(WidgetState.selected)
                        ? QuickpassColors.darkPrimary
                        : context.onSurfaceVariant;
                  }),
                  side: WidgetStateProperty.all(
                      BorderSide(color: context.outlineVariant)),
                  textStyle: WidgetStateProperty.all(const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: _segment == 0
                  ? _buildPendingList(supProv, isAdmin, context)
                  : _segment == 1
                      ? _buildApprovedList(supProv, isAdmin, context)
                      : _buildHistoryList(supProv, context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingList(
      SupervisorProvider supProv, bool isAdmin, BuildContext context) {
    if (supProv.isLoading && supProv.pendingRequests.isEmpty) {
      return const ShimmerList(itemCount: 3, itemBuilder: _pendingCardPlaceholder);
    }
    if (supProv.pendingRequests.isEmpty) {
      return const _FullList(
        child: EmptyState(
          icon: Icons.check_circle_outline,
          title: 'No pending requests',
          subtitle: 'All caught up!',
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.swipe, size: 16, color: context.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Swipe right to approve \u2022 Swipe left to reject',
                    style: TextStyle(fontSize: 12, color: context.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
        ...supProv.pendingRequests.map((leave) => Dismissible(
              key: ValueKey('pending_${leave.leaveId}'),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.endToStart) {
                  await PendingCard.showRejectDialog(context, leave);
                  return false;
                } else {
                  await PendingCard.approveLeave(context, leave);
                  return false;
                }
              },
              background: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 24),
                decoration: BoxDecoration(
                  color: context.success,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 32),
              ),
              secondaryBackground: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                decoration: BoxDecoration(
                  color: context.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.close, color: Colors.white, size: 32),
              ),
              child: PendingCard(leave: leave, showAdminActions: isAdmin),
            )),
      ],
    );
  }

  Widget _buildApprovedList(
      SupervisorProvider supProv, bool isAdmin, BuildContext context) {
    if (supProv.approvedLeaves.isEmpty) {
      return const _FullList(
        child: EmptyState(
          icon: Icons.check_circle_outline,
          title: 'No approved leaves',
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: supProv.approvedLeaves
          .map((leave) => _ApprovedCard(leave: leave, isAdmin: isAdmin))
          .toList(),
    );
  }

  Widget _buildHistoryList(
      SupervisorProvider supProv, BuildContext context) {
    if (supProv.history.isEmpty) {
      return const _FullList(
        child: EmptyState(
          icon: Icons.history,
          title: 'No history yet',
          subtitle: 'Approved and rejected leaves will appear here',
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children:
          supProv.history.map((leave) => _HistoryCard(leave: leave)).toList(),
    );
  }
}

class _FullList extends StatelessWidget {
  const _FullList({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        children: [
          SizedBox(height: constraints.maxHeight * 0.2),
          child,
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.leave});
  final LeaveRequest leave;

  bool get isRejected => leave.status == LeaveStatus.rejected;

  @override
  Widget build(BuildContext context) {
    final decisionColor =
        isRejected ? context.error : context.success;
    final decidedAt = leave.decidedAt ?? leave.updatedAt;

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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: decisionColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    isRejected ? Icons.close : Icons.check,
                    size: 20,
                    color: decisionColor,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: decisionColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: decisionColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    isRejected ? 'Rejected' : 'Approved',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: decisionColor,
                    ),
                  ),
                ),
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
                      style: TextStyle(
                          fontSize: 13, color: context.neutralGray)),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 14, color: context.neutralGray),
                  const SizedBox(width: 4),
                  Text('${leave.startTime} - ${leave.endTime}',
                      style: TextStyle(
                          fontSize: 13, color: context.neutralGray)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            ExpandableReason(
              text: leave.reason,
              collapsedLines: 3,
              style: TextStyle(color: context.neutralGray, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                    isRejected
                        ? Icons.event_busy
                        : Icons.how_to_reg_outlined,
                    size: 14,
                    color: context.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${isRejected ? 'Rejected' : 'Approved'} '
                  '${DateFormatter.formatDateTime(decidedAt)}',
                  style: TextStyle(
                      fontSize: 12, color: context.onSurfaceVariant),
                ),
              ],
            ),
            if (leave.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: context.error.withValues(alpha: 0.25)),
                ),
                child: Text(
                  'Reason: ${leave.rejectionReason}',
                  style: TextStyle(fontSize: 12, color: context.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ApprovedCard extends StatelessWidget {

  const _ApprovedCard({required this.leave, required this.isAdmin});
  final LeaveRequest leave;
  final bool isAdmin;

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
                  backgroundImage: _photo(leave) != null
                      ? NetworkImage(_photo(leave)!)
                      : null,
                  child: _photo(leave) == null
                      ? Text(
                          leave.employeeName.isNotEmpty
                              ? leave.employeeName.substring(0, 1).toUpperCase()
                              : '?',
                          style: TextStyle(
                              color: context.success,
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
            ExpandableReason(
              text: leave.reason,
              collapsedLines: 3,
              style: TextStyle(color: context.neutralGray, fontSize: 13),
            ),
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
                if (!leave.isExpired)
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
            const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Failed to delete leave')),
          );
        }
      }
    }
  }
}

Widget _pendingCardPlaceholder(int _) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 100,
                    height: 11,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 50,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 80,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 100,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 180,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 80,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 90,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
