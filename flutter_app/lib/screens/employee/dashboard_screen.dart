import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../models/employee.dart';
import '../../models/leave_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/custom_widgets.dart';
import '../shared/settings_screen.dart';
import 'leave_history_screen.dart';
import 'qr_display_screen.dart';
import 'request_leave_screen.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaveProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _DashboardTab(onViewHistory: () => setState(() => _currentIndex = 1)),
          const LeaveHistoryScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.outlineVariant)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: context.surface,
          indicatorColor: QuickpassColors.darkPrimary.withValues(alpha: 0.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined,
                  color: context.onSurfaceVariant),
              selectedIcon: Icon(Icons.dashboard, color: context.primary),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined,
                  color: context.onSurfaceVariant),
              selectedIcon: Icon(Icons.receipt_long, color: context.primary),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined,
                  color: context.onSurfaceVariant),
              selectedIcon: Icon(Icons.settings, color: context.primary),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  final VoidCallback? onViewHistory;
  const _DashboardTab({this.onViewHistory});

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthProvider p) => p.user);
    final leaveProv = context.watch<LeaveProvider>();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => context.read<LeaveProvider>().refresh(),
              child: CustomScrollView(
                slivers: [
                  const _DashboardAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _UserProfileCard(user: user),
                        const SizedBox(height: 16),
                        if (leaveProv.activeLeave != null) ...[
                          _ActiveLeaveCard(leave: leaveProv.activeLeave!),
                          const SizedBox(height: 16),
                        ],
                        _StatGrid(
                          pendingCount: leaveProv.pendingCount,
                          approvedCount: leaveProv.approvedCount,
                          completedCount: leaveProv.completedCount,
                        ),
                        const SizedBox(height: 24),
                        _RecentActivitySection(
                          isLoading: leaveProv.isLoading,
                          history: leaveProv.history,
                          onSeeAll: widget.onViewHistory ?? () {},
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 24,
              right: 16,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RequestLeaveScreen()));
                },
                backgroundColor: context.primary,
                foregroundColor: context.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add, size: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardAppBar extends StatelessWidget {
  const _DashboardAppBar();

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      key: const ValueKey('employee-dashboard'),
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
                  const SizedBox(width: 8),
                  Text(
                    'Quickpass',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: context.onPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.notifications_outlined,
                        color: context.onPrimary),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text('No new notifications'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserProfileCard extends StatelessWidget {
  final Employee? user;
  const _UserProfileCard({required this.user});

  static String? _photo(Employee? u) => AppConfig.photoUrl(u?.profilePhoto);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: context.primaryBlue.withValues(alpha: 0.1),
            backgroundImage: _photo(user) != null
                ? NetworkImage(_photo(user)!)
                : null,
            child: _photo(user) == null
                ? Text(
                    (user?.fullName ?? 'U').substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: context.primaryBlue,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.outline,
                  ),
                ),
                Text(
                  user?.fullName ?? '',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: context.onSurface,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user?.position ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.01,
                          color: context.secondary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '\u2022',
                        style: TextStyle(fontSize: 10, color: context.outline),
                      ),
                    ),
                    Text(
                      'ID: ${user?.employeeId ?? ''}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.05,
                        color: context.outline,
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
}

class _ActiveLeaveCard extends StatelessWidget {
  final LeaveRequest leave;
  const _ActiveLeaveCard({required this.leave});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outlineVariant),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: context.success,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'ACTIVE PASS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: context.success,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          leave.reason,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: context.onSurface,
                            letterSpacing: -0.01,
                            height: 1.33,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.check_circle, color: context.success, size: 28),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      InfoRow(
                          label: 'Validity',
                          value:
                              '${DateFormatter.formatDateApi(leave.leaveDate)} \u2022 ${leave.startTime} - ${leave.endTime}'),
                      const SizedBox(height: 8),
                      const InfoRow(
                          label: 'Gate Status', value: 'Authorized Out'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      if (leave.hasQrCodes) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QrDisplayScreen(leave: leave),
                          ),
                        );
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_2,
                            size: 20, color: context.onPrimary),
                        const SizedBox(width: 8),
                        const Text(
                          'View QR Pass',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  final int pendingCount;
  final int approvedCount;
  final int completedCount;

  const _StatGrid({
    required this.pendingCount,
    required this.approvedCount,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard('Pending', pendingCount.toString(), context.warning),
        const SizedBox(width: 8),
        _StatCard('Approved', approvedCount.toString(), context.success),
        const SizedBox(width: 8),
        _StatCard('Completed', completedCount.toString(), context.primaryBlue),
      ],
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  final bool isLoading;
  final List<LeaveRequest> history;
  final VoidCallback onSeeAll;

  const _RecentActivitySection({
    required this.isLoading,
    required this.history,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.onSurface,
                height: 1.5,
              ),
            ),
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'See All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ))
        else if (history.isEmpty)
          const EmptyState(
            icon: Icons.inbox_outlined,
            title: 'No recent activity',
          )
        else
          ...history.take(10).map((leave) => _ActivityCard(leave: leave)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard(this.title, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: context.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.outlineVariant),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: context.outline,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final LeaveRequest leave;

  const _ActivityCard({required this.leave});

  IconData _iconForReason(String reason) {
    final r = reason.toLowerCase();
    if (r.contains('sick') || r.contains('medical')) return Icons.event_busy;
    if (r.contains('vacation') || r.contains('vacation leave')) {
      return Icons.flight_takeoff;
    }
    if (r.contains('casual')) return Icons.work_off;
    return Icons.event_note;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Hero(
      tag: ValueKey('qr-leave-${leave.leaveId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.outlineVariant),
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (leave.hasQrCodes) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => QrDisplayScreen(leave: leave)));
              }
            },
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    _iconForReason(leave.reason),
                    size: 22,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leave.reason,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.onSurface,
                          height: 1.43,
                        ),
                      ),
                      Text(
                        DateFormatter.formatDateApi(leave.leaveDate),
                        style: TextStyle(
                          fontSize: 14,
                          color: context.outline,
                          height: 1.43,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: leave.status.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    leave.status.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: leave.status.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
