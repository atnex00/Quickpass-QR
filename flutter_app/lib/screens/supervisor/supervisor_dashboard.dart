import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/supervisor_provider.dart';
import '../../utils/responsive.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/offline_indicator.dart';
import '../../widgets/pending_card.dart';
import '../employee/dashboard_screen.dart';
import '../employee/request_leave_screen.dart';
import '../shared/settings_screen.dart';
import 'pending_requests_screen.dart';
import 'team_calendar_screen.dart';

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
  const _SupervisorOverview({
    required this.onViewRequests,
    required this.onViewProfile,
  });
  final VoidCallback onViewRequests;
  final VoidCallback onViewProfile;

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
                photoUrl: AppConfig.photoUrl(user?.profilePhoto),
                onProfileTap: widget.onViewProfile,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _WelcomeSection(userName: userName),
                    if (supProv.fromCache)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: OfflineIndicator()),
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
              heroTag: 'supervisor_add',
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
  const _SupervisorAppBar({
    required this.userName,
    required this.photoUrl,
    required this.onProfileTap,
  });
  final String userName;
  final String? photoUrl;
  final VoidCallback onProfileTap;

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
                    fontSize: responsiveFontSize(context, 20),
                    fontWeight: FontWeight.w600,
                    color: context.onPrimary,
                    height: 1.4,
                  ),
                ),
              const Spacer(),
              const NotificationBell(),
              GestureDetector(
                onTap: onProfileTap,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: photoUrl != null
                      ? null
                      : context.onPrimary.withValues(alpha: 0.2),
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl!)
                      : null,
                  child: photoUrl == null
                      ? Text(
                          (userName.isNotEmpty ? userName[0] : 'S').toUpperCase(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.onPrimary,
                          ),
                        )
                      : null,
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
  const _WelcomeSection({required this.userName});
  final String userName;

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
              fontSize: responsiveFontSize(context, 14),
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
            fontSize: responsiveFontSize(context, 24),
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
  const _PendingApprovalsHero(
      {required this.pendingCount, required this.onReviewNow});
  final int pendingCount;
  final VoidCallback onReviewNow;

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
              fontSize: responsiveFontSize(context, 14),
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
                  fontSize: responsiveFontSize(context, 20),
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
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.calendar_month,
                title: 'Team Calendar',
                subtitle: 'View team leaves',
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TeamCalendarScreen()));
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

  const _PendingRequestsSection({
    required this.isLoading,
    required this.pendingRequests,
    required this.onViewAll,
  });
  final bool isLoading;
  final List<dynamic> pendingRequests;
  final VoidCallback onViewAll;

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
                fontSize: responsiveFontSize(context, 16),
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
          EmptyState(
            icon: Icons.inbox_outlined,
            title: 'No pending requests',
            isOffline: context.read<SupervisorProvider>().fromCache,
          )
        else
          ...pendingRequests.take(5).map((leave) => PendingCard(leave: leave, showAccentBorder: true)),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

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
                    fontSize: responsiveFontSize(context, 16),
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


