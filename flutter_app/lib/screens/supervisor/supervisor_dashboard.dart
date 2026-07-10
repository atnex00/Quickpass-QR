import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/leave_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/supervisor_provider.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/status_badge.dart';
import '../employee/dashboard_screen.dart';
import '../employee/request_leave_screen.dart';
import '../shared/settings_screen.dart';
import 'pending_requests_screen.dart';

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          top: false,
          child: IndexedStack(
            index: _currentIndex,
            children: [
              _SupervisorOverview(
                onViewRequests: () => setState(() => _currentIndex = 1),
                onViewProfile: () => setState(() => _currentIndex = 2),
              ),
              const PendingRequestsScreen(),
              const SettingsScreen(),
            ],
          )),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.outlineVariant)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: context.surface,
          indicatorColor: QuickpassColors.darkPrimary.withValues(alpha: 0.15),
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined,
                  color: context.onSurfaceVariant),
              selectedIcon: Icon(Icons.dashboard, color: context.primary),
              label: 'Overview',
            ),
            NavigationDestination(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.pending_actions_outlined,
                      color: context.onSurfaceVariant),
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: context.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              selectedIcon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.pending_actions, color: context.primary),
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: context.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              label: 'Requests',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined, color: context.onSurfaceVariant),
              selectedIcon: Icon(Icons.settings, color: context.primary),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _SupervisorOverview extends StatefulWidget {
  final VoidCallback onViewRequests;
  final VoidCallback onViewProfile;
  const _SupervisorOverview({
    required this.onViewRequests,
    required this.onViewProfile,
  });

  @override
  State<_SupervisorOverview> createState() => _SupervisorOverviewState();
}

class _SupervisorOverviewState extends State<_SupervisorOverview> {
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
    final user = context.select((AuthProvider p) => p.user);
    final supProv = context.watch<SupervisorProvider>();
    final userName = user?.fullName ?? 'Supervisor';

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _SupervisorAppBar(
                userName: userName,
                onProfileTap: widget.onViewProfile,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _WelcomeSection(userName: userName),
                    const SizedBox(height: 16),
                    _PendingApprovalsHero(
                      pendingCount: supProv.pendingCount,
                      onReviewNow: widget.onViewRequests,
                    ),
                    const SizedBox(height: 16),
                    const _QuickActionsRow(),
                    const SizedBox(height: 16),
                    _PendingRequestsSection(
                      isLoading: supProv.isLoading,
                      pendingRequests: supProv.pendingRequests,
                      onViewAll: widget.onViewRequests,
                    ),
                  ]),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RequestLeaveScreen()),
                );
              },
              backgroundColor: context.primary,
              foregroundColor: context.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupervisorAppBar extends StatelessWidget {
  final String userName;
  final VoidCallback onProfileTap;
  const _SupervisorAppBar({required this.userName, required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      key: const ValueKey('supervisor-dashboard'),
      pinned: true,
      expandedHeight: 0,
      toolbarHeight: 64,
      automaticallyImplyLeading: false,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: context.onPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset('assets/icon/app-icon.png',
                    width: 18, height: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'Quickpass',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: context.onPrimary,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.notifications_outlined,
                    color: context.onPrimary),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No new notifications')),
                  );
                },
              ),
              GestureDetector(
                onTap: onProfileTap,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: context.onPrimary.withValues(alpha: 0.2),
                  child: Text(
                    (userName.isNotEmpty ? userName[0] : 'S').toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.onPrimary,
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

class _WelcomeSection extends StatelessWidget {
  final String userName;
  const _WelcomeSection({required this.userName});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COMMANDER VIEW',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.01,
            color: context.outline,
            height: 1.43,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_greeting()}, ${userName.split(' ').first}',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: context.onSurface,
            letterSpacing: -0.01,
            height: 1.33,
          ),
        ),
      ],
    );
  }
}

class _PendingApprovalsHero extends StatelessWidget {
  final int pendingCount;
  final VoidCallback onReviewNow;
  const _PendingApprovalsHero(
      {required this.pendingCount, required this.onReviewNow});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A5F), Color(0xFF0F1E33)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PENDING APPROVALS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                pendingCount.toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.05,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Requests',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: onReviewNow,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Review Now',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18, color: context.onPrimary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.dashboard,
                title: 'My Dashboard',
                subtitle: 'Employee overview',
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EmployeeDashboard()));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PendingRequestsSection extends StatelessWidget {
  final bool isLoading;
  final List<dynamic> pendingRequests;
  final VoidCallback onViewAll;

  const _PendingRequestsSection({
    required this.isLoading,
    required this.pendingRequests,
    required this.onViewAll,
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
              'Pending Requests',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.onSurface,
                height: 1.5,
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View All',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.onSurface,
                  decoration: TextDecoration.underline,
                  decorationColor: context.primary,
                  decorationThickness: 2,
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
        else if (pendingRequests.isEmpty)
          const EmptyState(
            icon: Icons.inbox_outlined,
            title: 'No pending requests',
          )
        else
          ...pendingRequests.take(5).map((leave) => _PendingCard(leave: leave)),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(icon, size: 22, color: context.primary),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.onSurface,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.outline,
                ),
              ),
            ],
          ),
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
        color: context.surface,
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
                color: context.warning,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
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
                            ? leave.employeeName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: context.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leave.employeeName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: context.onSurface,
                            ),
                          ),
                          if (leave.employeePosition != null)
                            Text(
                              leave.employeePosition!,
                              style: TextStyle(
                                color: context.neutralGray,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    StatusBadge(status: leave.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 14, color: context.neutralGray),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        DateFormatter.formatDate(leave.leaveDate),
                        style:
                            TextStyle(fontSize: 13, color: context.neutralGray),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time,
                        size: 14, color: context.neutralGray),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${leave.startTime} - ${leave.endTime}',
                        style:
                            TextStyle(fontSize: 13, color: context.neutralGray),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  leave.reason,
                  style: TextStyle(color: context.neutralGray, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
        ],
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
          '${leave.employeeName} \u2014 ${DateFormatter.formatDateApi(leave.leaveDate)} (${leave.startTime} - ${leave.endTime})',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
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
}
