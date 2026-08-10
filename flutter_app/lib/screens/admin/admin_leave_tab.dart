import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/leave_request.dart';
import '../../providers/supervisor_provider.dart';
import '../../services/api_service.dart';
import '../../utils/errors.dart';
import '../../widgets/custom_widgets.dart';
import 'admin_shared.dart';

class LeaveTab extends StatefulWidget {
  const LeaveTab({super.key});

  @override
  State<LeaveTab> createState() => _LeaveTabState();
}

class _LeaveTabState extends State<LeaveTab> {
  late final ApiService _api;
  List<dynamic>? _leaves;
  bool _isLoading = true;
  String? _error;
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLeaves();
    });
  }

  Future<void> _loadLeaves() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await _api.getReports();
      _leaves = res['data'] as List<dynamic>?;
    } catch (e) {
      _error = friendlyError(e);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<dynamic> get _filteredLeaves {
    if (_leaves == null) return [];
    if (_statusFilter.isEmpty) return _leaves!;
    return _leaves!.where((l) => l['status'] == _statusFilter).toList();
  }

  void _confirmDeleteLeave(Map<String, dynamic> leave) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Leave'),
        content: Text(
            'Remove leave request by ${leave['employee_name'] ?? 'Unknown'} on ${leave['leave_date'] ?? ''}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: ctx.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && mounted) {
        try {
          await _api.deleteLeave(leave['leave_id'] as String);
          _loadLeaves();
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Leave deleted')));
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Failed to delete leave')));
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLeaves;

    final slivers = <Widget>[
      buildAdminAppBar(context, 'leaves'),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  AdminFilterChip(
                      label: 'All',
                      selected: _statusFilter.isEmpty,
                      onTap: () {
                        setState(() => _statusFilter = '');
                      }),
                  const SizedBox(width: 8),
                  AdminFilterChip(
                      label: 'Pending',
                      selected: _statusFilter == 'pending',
                      onTap: () {
                        setState(() => _statusFilter = 'pending');
                      }),
                  const SizedBox(width: 8),
                  AdminFilterChip(
                      label: 'Approved',
                      selected: _statusFilter == 'approved',
                      onTap: () {
                        setState(() => _statusFilter = 'approved');
                      }),
                  const SizedBox(width: 8),
                  AdminFilterChip(
                      label: 'Active',
                      selected: _statusFilter == 'active',
                      onTap: () {
                        setState(() => _statusFilter = 'active');
                      }),
                  const SizedBox(width: 8),
                  AdminFilterChip(
                      label: 'Completed',
                      selected: _statusFilter == 'completed',
                      onTap: () {
                        setState(() => _statusFilter = 'completed');
                      }),
                  const SizedBox(width: 8),
                  AdminFilterChip(
                      label: 'Rejected',
                      selected: _statusFilter == 'rejected',
                      onTap: () {
                        setState(() => _statusFilter = 'rejected');
                      }),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('${filtered.length} leave${filtered.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 12, color: context.neutralGray)),
            const SizedBox(height: 8),
            if (_isLoading)
              const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: context.error),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _loadLeaves, child: const Text('Retry')),
                  ],
                ),
              )
            else if (filtered.isEmpty)
              const EmptyState(
                icon: Icons.inbox_outlined,
                title: 'No leave requests',
              ),
          ]),
        ),
      ),
    ];

    if (!_isLoading && filtered.isNotEmpty) {
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _buildLeaveItem(ctx, filtered[i]),
              childCount: filtered.length,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadLeaves,
            child: CustomScrollView(slivers: slivers),
          ),
        ],
      ),
    );
  }

  void _approveLeave(Map<String, dynamic> leave) async {
    final leaveId = leave['leave_id'] as String? ?? '';
    final name = leave['employee_name'] as String? ?? 'Unknown';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Approve Leave?'),
        content: Text(
            '$name \u2014 ${leave['leave_date'] ?? ''} (${leave['start_time'] ?? ''} - ${leave['end_time'] ?? ''})'),
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
    if (confirmed == true && leaveId.isNotEmpty && mounted) {
      await context.read<SupervisorProvider>().approveLeave(leaveId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Approved leave for $name')));
        _loadLeaves();
      }
    }
  }

  void _rejectLeave(Map<String, dynamic> leave) async {
    final leaveId = leave['leave_id'] as String? ?? '';
    final name = leave['employee_name'] as String? ?? 'Unknown';
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Reject Leave'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reason for rejecting $name?'),
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
            style: FilledButton.styleFrom(backgroundColor: ctx.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (reason != null && leaveId.isNotEmpty && mounted) {
      await context.read<SupervisorProvider>().rejectLeave(leaveId, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Rejected leave for $name')));
        _loadLeaves();
      }
    }
  }

  void _revokeApproval(Map<String, dynamic> leave) async {
    final leaveId = leave['leave_id'] as String? ?? '';
    final name = leave['employee_name'] as String? ?? 'Unknown';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Revoke Approval?'),
        content: Text("Move $name's leave back to pending?"),
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
    if (confirmed == true && leaveId.isNotEmpty && mounted) {
      await context.read<SupervisorProvider>().revokeApproval(leaveId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Revoked approval for $name')));
        _loadLeaves();
      }
    }
  }

  Widget _buildLeaveItem(BuildContext context, Map<String, dynamic> leave) {
    final status = leave['status'] as String? ?? '';
    final leaveStatus = LeaveStatus.fromString(status);
    final statusColor = leaveStatus.color(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(leave['employee_name'] ?? 'Unknown',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: context.onSurface)),
                    if ((leave['department_name'] as String?)?.isNotEmpty ==
                        true)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('${leave['department_name'] ?? ''}',
                            style: TextStyle(
                                fontSize: 12, color: context.neutralGray)),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  leaveStatus.label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: context.neutralGray),
                const SizedBox(width: 4),
                Text('${leave['leave_date'] ?? ''}',
                    style: TextStyle(fontSize: 12, color: context.neutralGray)),
                const SizedBox(width: 12),
                Icon(Icons.access_time, size: 14, color: context.neutralGray),
                const SizedBox(width: 4),
                Text(
                    '${leave['start_time'] ?? ''} - ${leave['end_time'] ?? ''}',
                    style: TextStyle(fontSize: 12, color: context.neutralGray)),
              ],
            ),
          ),
          if ((leave['reason'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(leave['reason'] as String? ?? '',
                style: TextStyle(fontSize: 12, color: context.neutralGray),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
          if (status == 'pending' ||
              status == 'approved' ||
              status == 'active') ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: context.error, size: 20),
                    tooltip: 'Delete',
                    onPressed: () => _confirmDeleteLeave(leave),
                  ),
                  if (status == 'pending') ...[
                    OutlinedButton.icon(
                      onPressed: () => _rejectLeave(leave),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.error,
                        side: BorderSide(color: context.error),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => _approveLeave(leave),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: FilledButton.styleFrom(
                        backgroundColor: context.primary,
                        foregroundColor: context.onPrimary,
                      ),
                    ),
                  ],
                  if (status == 'approved' &&
                      leave['is_expired'] != true)
                    OutlinedButton.icon(
                      onPressed: () => _revokeApproval(leave),
                      icon: const Icon(Icons.undo, size: 18),
                      label: const Text('Revoke'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.warning,
                        side: BorderSide(color: context.warning),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
