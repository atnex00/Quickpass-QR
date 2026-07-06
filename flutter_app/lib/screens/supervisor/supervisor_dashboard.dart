import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/leave_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/supervisor_provider.dart';
import '../employee/profile_screen.dart';
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
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _SupervisorOverview(),
          PendingRequestsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: QuickpassColors.outlineVariant)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: QuickpassColors.surface,
          indicatorColor: QuickpassColors.darkPrimary.withValues(alpha: 0.15),
          height: 80,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: QuickpassColors.onSurfaceVariant),
              selectedIcon: Icon(Icons.dashboard, color: QuickpassColors.darkPrimary),
              label: 'Overview',
            ),
            NavigationDestination(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.pending_actions_outlined, color: QuickpassColors.onSurfaceVariant),
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: QuickpassColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: QuickpassColors.surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              selectedIcon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.pending_actions, color: QuickpassColors.darkPrimary),
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: QuickpassColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: QuickpassColors.surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              label: 'Requests',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline, color: QuickpassColors.onSurfaceVariant),
              selectedIcon: Icon(Icons.person, color: QuickpassColors.darkPrimary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _SupervisorOverview extends StatefulWidget {
  const _SupervisorOverview();

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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final supProv = context.watch<SupervisorProvider>();
    final userName = auth.user?.fullName ?? 'Supervisor';

    return Scaffold(
      body: Stack(
        children: [
          // Main scrollable content
          CustomScrollView(
            slivers: [
              // ── Electric Yellow App Bar ──
              SliverAppBar(
                pinned: true,
                expandedHeight: 0,
                toolbarHeight: 64,
                backgroundColor: QuickpassColors.darkPrimary,
                foregroundColor: QuickpassColors.darkOnPrimary,
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
                            color: QuickpassColors.darkOnPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.qr_code_scanner, size: 18, color: QuickpassColors.darkOnPrimary),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Quickpass',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: QuickpassColors.darkOnPrimary,
                            height: 1.4,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: QuickpassColors.darkOnPrimary),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No new notifications')),
                            );
                          },
                        ),
                        GestureDetector(
                          onTap: () {
                            final state = context.findAncestorStateOfType<_SupervisorDashboardState>();
                            state?.setState(() => state._currentIndex = 2);
                          },
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: QuickpassColors.darkOnPrimary.withValues(alpha: 0.2),
                            child: Text(
                              (userName.isNotEmpty ? userName[0] : 'S').toUpperCase(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: QuickpassColors.darkOnPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Body ──
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Welcome
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'COMMANDER VIEW',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.01,
                            color: QuickpassColors.outline,
                            height: 1.43,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_greeting, ${userName.split(' ').first}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: QuickpassColors.onSurface,
                            letterSpacing: -0.01,
                            height: 1.33,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Hero: Pending Approvals ──
                    Container(
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
                                supProv.pendingCount.toString().padLeft(2, '0'),
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
                            child: ElevatedButton(
                              onPressed: () {
                                final state = context.findAncestorStateOfType<_SupervisorDashboardState>();
                                state?.setState(() => state._currentIndex = 1);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: QuickpassColors.darkPrimary,
                                foregroundColor: QuickpassColors.darkOnPrimary,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Review Now',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward, size: 18, color: QuickpassColors.darkOnPrimary),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Quick Actions Grid ──
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.calendar_month,
                            title: 'Team Calendar',
                            subtitle: 'Manage schedule',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Team Calendar coming soon')),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.analytics,
                            title: 'Dept. Stats',
                            subtitle: 'View reports',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Department Stats coming soon')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Recent History ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent History',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: QuickpassColors.onSurface,
                            height: 1.5,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Viewing all history...')),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: QuickpassColors.onSurface,
                              decoration: TextDecoration.underline,
                              decorationColor: QuickpassColors.darkPrimary,
                              decorationThickness: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // ── History Items ──
                    if (supProv.isLoading)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ))
                    else if (supProv.approvedLeaves.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: QuickpassColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: QuickpassColors.outlineVariant),
                        ),
                        child: const Center(
                          child: Text(
                            'No approved leaves yet',
                            style: TextStyle(color: QuickpassColors.neutralGray),
                          ),
                        ),
                      )
                    else
                      ...supProv.approvedLeaves.take(10).map((leave) => _HistoryCard(
                        leave: leave,
                        onRevoke: () => _revokeApproval(context, leave),
                      )),
                  ]),
                ),
              ),
            ],
          ),

          // ── FAB ──
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                final state = context.findAncestorStateOfType<_SupervisorDashboardState>();
                state?.setState(() => state._currentIndex = 1);
              },
              backgroundColor: QuickpassColors.darkPrimary,
              foregroundColor: QuickpassColors.darkOnPrimary,
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

  Future<void> _revokeApproval(BuildContext context, LeaveRequest leave) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Revoke Approval'),
        content: Text('Revoke approval for ${leave.employeeName}\'s leave?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: QuickpassColors.error),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final supProv = context.read<SupervisorProvider>();
      final result = await supProv.revokeApproval(leave.leaveId);
      if (result != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval revoked for ${leave.employeeName}')),
        );
        supProv.loadPendingRequests();
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(supProv.error ?? 'Failed to revoke')),
        );
      }
    }
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
        color: QuickpassColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QuickpassColors.outlineVariant),
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
                  color: QuickpassColors.darkPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(icon, size: 22, color: QuickpassColors.darkPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: QuickpassColors.onSurface,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: QuickpassColors.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final LeaveRequest leave;
  final VoidCallback onRevoke;

  const _HistoryCard({required this.leave, required this.onRevoke});

  @override
  Widget build(BuildContext context) {
    final isApproved = leave.status == LeaveStatus.approved;
    final statusColor = isApproved ? QuickpassColors.success : QuickpassColors.error;
    final statusLabel = isApproved ? 'Approved' : 'Revoked';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: QuickpassColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QuickpassColors.outlineVariant),
      ),
      child: Stack(
        children: [
          // Status strip
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: QuickpassColors.surfaceVariant,
                  child: Text(
                    leave.employeeName.isNotEmpty ? leave.employeeName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: QuickpassColors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              leave.employeeName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: QuickpassColors.onSurface,
                                height: 1.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'ID #${leave.employeeId}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: QuickpassColors.outline,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${leave.reason.isNotEmpty ? leave.reason : 'Leave'} \u2022 ${leave.leaveDate.toIso8601String().split('T').first}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: QuickpassColors.outline,
                          height: 1.43,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              statusLabel.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${leave.startTime} - ${leave.endTime}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: QuickpassColors.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isApproved)
                  IconButton(
                    icon: const Icon(Icons.undo, size: 20, color: QuickpassColors.error),
                    onPressed: onRevoke,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    style: IconButton.styleFrom(
                      backgroundColor: QuickpassColors.error.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
