import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../../utils/responsive.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/offline_indicator.dart';
import '../../widgets/shimmer_list.dart';
import 'qr_display_screen.dart';
import 'request_leave_screen.dart';
import 'widgets/leave_filter_bar.dart';
import 'widgets/leave_history_card.dart';

class LeaveHistoryScreen extends StatefulWidget {
  const LeaveHistoryScreen({super.key});

  @override
  State<LeaveHistoryScreen> createState() => _LeaveHistoryScreenState();
}

class _LeaveHistoryScreenState extends State<LeaveHistoryScreen> {
  String? _statusFilter;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaveProvider>().loadHistory(page: _currentPage);
    });
  }

  void _setFilter(String? status) {
    setState(() {
      _statusFilter = status;
      _currentPage = 1;
    });
    context.read<LeaveProvider>().loadHistory(
      status: status,
      page: _currentPage,
    );
  }

  void _goToPage(int page) {
    setState(() => _currentPage = page);
    context.read<LeaveProvider>().loadHistory(
      status: _statusFilter,
      page: page,
    );
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

              SliverPersistentHeader(
                pinned: true,
                delegate: LeaveFilterBarDelegate(_statusFilter, _setFilter),
              ),

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
                        itemCount: 4, itemBuilder: (_) => const LeaveCardPlaceholder()))
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < leaveProv.history.length) {
                          final leave = leaveProv.history[index];
                          return LeaveHistoryCard(
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
                        return null;
                      },
                      childCount: leaveProv.history.length,
                    ),
                  ),
                ),
              if (!leaveProv.isLoading &&
                  leaveProv.historyPages > 1 &&
                  (leaveProv.error == null || leaveProv.history.isNotEmpty))
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Page ${leaveProv.historyPage} of ${leaveProv.historyPages}',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.neutralGray,
                          ),
                        ),
                        Row(
                          children: [
                            FilledButton.tonal(
                              onPressed: _currentPage > 1
                                  ? () => _goToPage(_currentPage - 1)
                                  : null,
                              child: const Text('Prev'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.tonal(
                              onPressed: _currentPage < leaveProv.historyPages
                                  ? () => _goToPage(_currentPage + 1)
                                  : null,
                              child: const Text('Next'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  child: Container(
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


