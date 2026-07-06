import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/leave_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import 'request_leave_screen.dart';
import 'leave_history_screen.dart';
import 'qr_display_screen.dart';
import 'profile_screen.dart';

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
        children: const [
          _DashboardTab(),
          LeaveHistoryScreen(),
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
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: QuickpassColors.onSurfaceVariant),
              selectedIcon: Icon(Icons.dashboard, color: QuickpassColors.darkPrimary),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined, color: QuickpassColors.onSurfaceVariant),
              selectedIcon: Icon(Icons.history, color: QuickpassColors.darkPrimary),
              label: 'History',
            ),
            NavigationDestination(
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

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final leaveProv = context.watch<LeaveProvider>();

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Electric Yellow App Bar ──
              SliverAppBar(
                pinned: true,
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
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: QuickpassColors.darkOnPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.asset('assets/icon/app-icon.png', width: 22, height: 22),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Quickpass',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: QuickpassColors.darkOnPrimary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: QuickpassColors.darkOnPrimary),
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
                  ),
                ),
              ),

              // ── Body ──
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── User Profile Card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: QuickpassColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: QuickpassColors.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: QuickpassColors.primary.withValues(alpha: 0.1),
                            child: Text(
                              (auth.user?.fullName ?? 'U').substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: QuickpassColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Welcome back,',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: QuickpassColors.outline,
                                  ),
                                ),
                                Text(
                                  auth.user?.fullName ?? '',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: QuickpassColors.onSurface,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      auth.user?.position ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.01,
                                        color: QuickpassColors.secondary,
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6),
                                      child: Text(
                                        '\u2022',
                                        style: TextStyle(fontSize: 10, color: QuickpassColors.outline),
                                      ),
                                    ),
                                    Text(
                                      'ID: ${auth.user?.employeeId ?? ''}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.05,
                                        color: QuickpassColors.outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Active Leave Hero Card ──
                    if (leaveProv.activeLeave != null)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: QuickpassColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: QuickpassColors.outlineVariant),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 4,
                                decoration: const BoxDecoration(
                                  color: QuickpassColors.success,
                                  borderRadius: BorderRadius.only(
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
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: QuickpassColors.success.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: const Text(
                                              'ACTIVE PASS',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: QuickpassColors.success,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            leaveProv.activeLeave!.reason,
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
                                      const Icon(Icons.check_circle, color: QuickpassColors.success, size: 28),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Column(
                                      children: [
                                        _InfoRow(label: 'Validity', value: '${leaveProv.activeLeave!.leaveDate.toIso8601String().split('T').first} \u2022 ${leaveProv.activeLeave!.startTime} - ${leaveProv.activeLeave!.endTime}'),
                                        const SizedBox(height: 8),
                                        const _InfoRow(label: 'Gate Status', value: 'Authorized Out'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: FilledButton(
                                      onPressed: () {
                                        if (leaveProv.activeLeave!.hasQrCodes) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => QrDisplayScreen(leave: leaveProv.activeLeave!),
                                            ),
                                          );
                                        }
                                      },
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.qr_code_2, size: 20, color: QuickpassColors.darkOnPrimary),
                                          SizedBox(width: 8),
                                          Text(
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
                      ),
                    if (leaveProv.activeLeave != null) const SizedBox(height: 16),

                    // ── Stat Grid ──
                    Row(
                      children: [
                        _StatCard('Pending', leaveProv.pendingCount.toString(), QuickpassColors.warning),
                        const SizedBox(width: 8),
                        _StatCard('Approved', leaveProv.approvedCount.toString(), QuickpassColors.success),
                        const SizedBox(width: 8),
                        _StatCard('Completed', leaveProv.completedCount.toString(), QuickpassColors.primary),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Recent Activity ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: QuickpassColors.onSurface,
                            height: 1.5,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final state = context.findAncestorStateOfType<_EmployeeDashboardState>();
                            state?.setState(() => state._currentIndex = 1);
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: QuickpassColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (leaveProv.isLoading)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ))
                    else if (leaveProv.history.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: QuickpassColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: QuickpassColors.outlineVariant),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.inbox_outlined, size: 40, color: QuickpassColors.outlineVariant),
                            SizedBox(height: 12),
                            Text('No recent activity', style: TextStyle(color: QuickpassColors.neutralGray)),
                          ],
                        ),
                      )
                    else
                      ...leaveProv.history.take(10).map((leave) => _ActivityCard(leave: leave)),
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
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestLeaveScreen()));
              },
              backgroundColor: QuickpassColors.darkPrimary,
              foregroundColor: QuickpassColors.darkOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add, size: 32),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: QuickpassColors.onSurfaceVariant, height: 1.43)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: QuickpassColors.onSurface, height: 1.43)),
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
          color: QuickpassColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: QuickpassColors.outlineVariant),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: QuickpassColors.outline,
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
    if (r.contains('vacation') || r.contains('vacation leave')) return Icons.flight_takeoff;
    if (r.contains('casual')) return Icons.work_off;
    return Icons.event_note;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuickpassColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QuickpassColors.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (leave.hasQrCodes) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => QrDisplayScreen(leave: leave)));
          }
        },
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: QuickpassColors.surfaceContainerHigh,
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: QuickpassColors.onSurface,
                      height: 1.43,
                    ),
                  ),
                  Text(
                    leave.leaveDate.toIso8601String().split('T').first,
                    style: const TextStyle(
                      fontSize: 14,
                      color: QuickpassColors.outline,
                      height: 1.43,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
    );
  }
}
