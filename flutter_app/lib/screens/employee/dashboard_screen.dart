import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../../widgets/offline_indicator.dart';
import '../shared/settings_screen.dart';
import 'directory_screen.dart';
import 'leave_history_screen.dart';
import 'request_leave_screen.dart';
import 'widgets/active_leave_card.dart';
import 'widgets/dashboard_app_bar.dart';
import 'widgets/recent_activity_section.dart';
import 'widgets/stat_grid.dart';
import 'widgets/user_profile_card.dart';

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
          const DirectoryScreen(),
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
          indicatorColor: context.primary.withValues(alpha: 0.15),
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
              icon: Icon(Icons.people_outline,
                  color: context.onSurfaceVariant),
              selectedIcon: Icon(Icons.people, color: context.primary),
              label: 'Directory',
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
  const _DashboardTab({this.onViewHistory});
  final VoidCallback? onViewHistory;

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      context.read<LeaveProvider>().refresh();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

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
                  const DashboardAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        UserProfileCard(user: user),
                        const SizedBox(height: 16),
                        if (leaveProv.activeLeave != null) ...[
                          ActiveLeaveCard(leave: leaveProv.activeLeave!),
                          const SizedBox(height: 16),
                        ],
                        StatGrid(
                          pendingCount: leaveProv.pendingCount,
                          approvedCount: leaveProv.approvedCount,
                          completedCount: leaveProv.completedCount,
                        ),
                        const SizedBox(height: 24),
                        if (leaveProv.fromCache)
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: OfflineIndicator()),
                        RecentActivitySection(
                          isLoading: leaveProv.isLoading,
                          history: leaveProv.history,
                          error: leaveProv.error,
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
                heroTag: 'employee_add',
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


