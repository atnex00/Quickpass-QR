import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/employee.dart';
import '../../models/leave_request.dart';
import '../../providers/directory_provider.dart';
import '../../utils/responsive.dart';
import '../../widgets/offline_indicator.dart';
import '../employee/widgets/leave_history_card.dart';

class EmployeeLeaveHistoryScreen extends StatefulWidget {
  const EmployeeLeaveHistoryScreen({super.key, required this.employee});
  final Employee employee;

  @override
  State<EmployeeLeaveHistoryScreen> createState() =>
      _EmployeeLeaveHistoryScreenState();
}

class _EmployeeLeaveHistoryScreenState extends State<EmployeeLeaveHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<DirectoryProvider>()
          .loadTeamMemberLeaves(widget.employee.employeeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dirProv = context.watch<DirectoryProvider>();
    final leaves = dirProv.teamLeavesOf(widget.employee.employeeId) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employee.fullName),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => context
            .read<DirectoryProvider>()
            .loadTeamMemberLeaves(widget.employee.employeeId),
        child: Column(
          children: [
            _SummaryHeader(employee: widget.employee, leaves: leaves),
            if (dirProv.fromCache)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: OfflineIndicator(),
              ),
            Expanded(
              child: leaves.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy,
                              size: 48, color: context.neutralGray),
                          const SizedBox(height: 12),
                          Text(
                            'No leave records yet',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: leaves.length,
                      itemBuilder: (context, i) => LeaveHistoryCard(
                        leave: leaves[i],
                        onTap: () {},
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.employee, required this.leaves});
  final Employee employee;
  final List<LeaveRequest> leaves;

  @override
  Widget build(BuildContext context) {
    int count(LeaveStatus status) =>
        leaves.where((l) => l.status == status && !l.isExpired).length;

    final pending = count(LeaveStatus.pending);
    final approved = count(LeaveStatus.approved);
    final completed = count(LeaveStatus.completed);
    final rejected = count(LeaveStatus.rejected);
    final active = count(LeaveStatus.active);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  employee.position,
                  style: TextStyle(
                    fontSize: responsiveFontSize(context, 14),
                    fontWeight: FontWeight.w600,
                    color: context.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${leaves.length} total',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryChip(label: 'Pending', value: pending, color: context.warning),
              _SummaryChip(label: 'Approved', value: approved, color: context.primary),
              _SummaryChip(label: 'Active', value: active, color: context.success),
              _SummaryChip(label: 'Completed', value: completed, color: context.success),
              _SummaryChip(label: 'Rejected', value: rejected, color: context.error),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}