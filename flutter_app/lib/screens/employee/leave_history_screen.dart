import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/leave_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../../utils/date_formatter.dart';
import '../../utils/responsive.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/offline_indicator.dart';
import '../../widgets/shimmer_list.dart';
import 'qr_display_screen.dart';
import 'request_leave_screen.dart';

class LeaveHistoryScreen extends StatefulWidget {
  const LeaveHistoryScreen({super.key});

  @override
  State<LeaveHistoryScreen> createState() => _LeaveHistoryScreenState();
}

class _LeaveHistoryScreenState extends State<LeaveHistoryScreen> {
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaveProvider>().loadHistory();
    });
  }

  void _setFilter(String? status) {
    setState(() => _statusFilter = status);
    context.read<LeaveProvider>().loadHistory(status: status);
  }

  @override
  Widget build(BuildContext context) {
    final leaveProv = context.watch<LeaveProvider>();
    final isAdmin = context.read<AuthProvider>().isAdmin;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => leaveProv.loadHistory(status: _statusFilter),
          child: CustomScrollView(
            slivers: [
              // ── Electric Yellow App Bar ──
              SliverAppBar(
                pinned: true,
                toolbarHeight: 64,
                automaticallyImplyLeading: false,
                flexibleSpace: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: context.onPrimary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Image.asset('assets/icon/app-icon.png',
                                  width: 22, height: 22),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Gate History',
                              style: TextStyle(
                                fontSize: responsiveFontSize(context, 20),
                                fontWeight: FontWeight.w700,
                                color: context.onPrimary,
                              ),
                            ),
                            const Spacer(),
                            const NotificationBell(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Sticky Filter Bar ──
              SliverPersistentHeader(
                pinned: true,
                delegate: _FilterBarDelegate(_statusFilter, _setFilter),
              ),

              // ── Content ──
              if (leaveProv.fromCache)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: OfflineIndicator(),
                  ),
                ),
              if (leaveProv.isLoading)
                SliverFillRemaining(
                    child: ShimmerList(
                        itemCount: 4, itemBuilder: (_) => const _LeaveCardPlaceholder()))
              else if (leaveProv.error != null)
                SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'No leave requests found',
                    subtitle: _statusFilter != null
                        ? 'No $_statusFilter requests match your filter'
                        : 'Submit a leave request to get started',
                    error: leaveProv.error,
                  ),
                )
              else if (leaveProv.history.isEmpty)
                SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'No leave requests found',
                    subtitle: _statusFilter != null
                        ? 'No $_statusFilter requests match your filter'
                        : 'Submit a leave request to get started',
                    isOffline: leaveProv.fromCache,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < leaveProv.history.length) {
                          final leave = leaveProv.history[index];
                          return _HistoryCard(
                            leave: leave,
                            isAdmin: isAdmin,
                            onTap: () {
                              if (leave.hasQrCodes) {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          QrDisplayScreen(leave: leave),
                                    ));
                              }
                            },
                            onCancel: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Cancel Leave'),
                                  content: Text(
                                      'Cancel leave request #${leave.leaveId}?'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('No')),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
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
                            onDelete: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Leave'),
                                  content: Text(
                                      'Delete leave #${leave.leaveId}? This cannot be undone.'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel')),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: FilledButton.styleFrom(
                                          backgroundColor: context.error),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true && context.mounted) {
                                try {
                                  await context
                                      .read<LeaveProvider>()
                                      .deleteLeave(leave.leaveId);
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
                                      SnackBar(
                                          behavior: SnackBarBehavior.floating,
                                          content: Text('$e')),
                                    );
                                  }
                                }
                              }
                            },
                          );
                        }
                        final offset = index - leaveProv.history.length;
                        if (offset == 0) return const SizedBox(height: 16);
                        if (offset == 1) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: context.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: context.primaryBlue
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Planning ahead?',
                                    style: TextStyle(
                                        fontSize: responsiveFontSize(context, 16),
                                        fontWeight: FontWeight.w600,
                                        color: context.onPrimaryContainer,
                                        height: 1.5)),
                                const SizedBox(height: 8),
                                Text(
                                    'Secure your holiday pass now to ensure quick approval from the command center.',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: context.onPrimaryContainer,
                                        height: 1.43)),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const RequestLeaveScreen())),
                                  child: const Text('New Request',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          );
                        }
                        return null;
                      },
                      childCount: leaveProv.history.length + 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sticky Filter Bar ──

class _FilterBarDelegate extends SliverPersistentHeaderDelegate {

  _FilterBarDelegate(this.currentFilter, this.onFilterChanged);
  final String? currentFilter;
  final void Function(String?) onFilterChanged;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: 56,
      color: context.surface.withValues(alpha: 0.95),
      child: ListView(
        padding: const EdgeInsets.only(left: 16),
        scrollDirection: Axis.horizontal,
        children: [
          Center(
              child: _FilterChip(
                  label: 'All',
                  selected: currentFilter == null,
                  onTap: () => onFilterChanged(null))),
          const SizedBox(width: 8),
          Center(
              child: _FilterChip(
                  label: 'Pending',
                  selected: currentFilter == 'pending',
                  onTap: () => onFilterChanged('pending'))),
          const SizedBox(width: 8),
          Center(
              child: _FilterChip(
                  label: 'Approved',
                  selected: currentFilter == 'approved',
                  onTap: () => onFilterChanged('approved'))),
          const SizedBox(width: 8),
          Center(
              child: _FilterChip(
                  label: 'Rejected',
                  selected: currentFilter == 'rejected',
                  onTap: () => onFilterChanged('rejected'))),
          const SizedBox(width: 8),
          Center(
              child: _FilterChip(
                  label: 'Completed',
                  selected: currentFilter == 'completed',
                  onTap: () => onFilterChanged('completed'))),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 56;

  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(covariant _FilterBarDelegate oldDelegate) {
    return currentFilter != oldDelegate.currentFilter;
  }
}

class _FilterChip extends StatelessWidget {

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? context.primaryBlue : context.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? context.primaryBlue : context.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.01,
            color: selected ? Colors.white : context.onSurface,
          ),
        ),
      ),
    );
  }
}

// ── History Card ──

class _HistoryCard extends StatelessWidget {

  const _HistoryCard(
      {required this.leave,
      required this.onTap,
      this.isAdmin = false,
      this.onDelete,
      this.onCancel});
  final LeaveRequest leave;
  final VoidCallback onTap;
  final bool isAdmin;
  final VoidCallback? onDelete;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final statusColor = leave.status.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    leave.reason,
                                    style: TextStyle(
                                      fontSize: responsiveFontSize(context, 16),
                                      fontWeight: FontWeight.w600,
                                      color: context.onSurface,
                                      height: 1.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    leave.status.label.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.calendar_month,
                                    size: 16, color: context.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormatter.formatDate(leave.leaveDate),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.onSurfaceVariant,
                                    height: 1.43,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID: #${leave.leaveId} \u2022 ${leave.durationText}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: context.neutralGray,
                              ),
                            ),
                            if (leave.rejectionReason != null) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: context.errorContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        size: 14, color: context.error),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        leave.rejectionReason!,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: context.onErrorContainer),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (leave.status == LeaveStatus.pending ||
                          leave.status == LeaveStatus.approved)
                        GestureDetector(
                          onTap: onCancel,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Icon(Icons.close,
                                size: 20, color: context.warning),
                          ),
                        ),
                      const SizedBox(width: 4),
                      if (isAdmin)
                        GestureDetector(
                          onTap: onDelete,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Icon(Icons.delete_outline,
                                size: 20, color: context.error),
                          ),
                        ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.surfaceContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: context.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaveCardPlaceholder extends StatelessWidget {
  const _LeaveCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              height: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 16,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 60,
                          height: 22,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 160,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
