import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/supervisor_provider.dart';
import 'pending_requests_screen.dart';

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  int _currentIndex = 0;

  final _screens = [
    const _SupervisorHomeTab(),
    const PendingRequestsScreen(),
  ];

  void _switchToRequests() {
    setState(() => _currentIndex = 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.pending_actions_outlined), selectedIcon: Icon(Icons.pending_actions), label: 'Requests'),
        ],
      ),
    );
  }
}

class _SupervisorHomeTab extends StatefulWidget {
  const _SupervisorHomeTab();

  @override
  State<_SupervisorHomeTab> createState() => _SupervisorHomeTabState();
}

class _SupervisorHomeTabState extends State<_SupervisorHomeTab> {
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
    final colorScheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final supProv = context.watch<SupervisorProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervisor Panel'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => context.read<AuthProvider>().logout()),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await supProv.loadPendingRequests();
          await supProv.loadApprovedLeaves();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: colorScheme.secondary,
                        child: Text(
                          (auth.user?.fullName ?? 'S').substring(0, 1).toUpperCase(),
                          style: TextStyle(fontSize: 24, color: colorScheme.onSecondary, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(auth.user?.fullName ?? '', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                            Text(auth.user?.departmentName ?? '', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                color: colorScheme.primary,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    final parent = context.findAncestorStateOfType<_SupervisorDashboardState>();
                    parent?._switchToRequests();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.onPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.pending_actions, color: colorScheme.onPrimary, size: 32),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${supProv.pendingCount}',
                                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: colorScheme.onPrimary),
                              ),
                              Text('Pending Requests', style: TextStyle(color: colorScheme.onPrimary.withValues(alpha: 0.7), fontSize: 14)),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: colorScheme.onPrimary.withValues(alpha: 0.5), size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ActionCard(
                    icon: Icons.pending_actions,
                    label: 'Review Pending',
                    color: colorScheme.tertiary,
                    onTap: () {
                      final parent = context.findAncestorStateOfType<_SupervisorDashboardState>();
                      parent?._switchToRequests();
                    },
                  ),
                  const SizedBox(width: 12),
                  _ActionCard(
                    icon: Icons.calendar_month,
                    label: 'Team Calendar',
                    color: colorScheme.secondary,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Approved Leaves', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
              const SizedBox(height: 4),
              Text('Tap to revoke approval', style: TextStyle(fontSize: 12, color: colorScheme.outline)),
              const SizedBox(height: 8),
              if (supProv.approvedLeaves.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text('No approved leaves', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                    ),
                  ),
                )
              else
                ...supProv.approvedLeaves.take(5).map((leave) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primary,
                      radius: 18,
                      child: Text(leave.employeeName[0], style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.w600)),
                    ),
                    title: Text(leave.employeeName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colorScheme.onSurface)),
                    subtitle: Text('${leave.startTime} - ${leave.endTime}', style: TextStyle(fontSize: 12)),
                    trailing: IconButton(
                      icon: Icon(Icons.undo, color: colorScheme.tertiary),
                      onPressed: () async {
                        final result = await supProv.revokeApproval(leave.leaveId);
                        if (result != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Approval revoked')),
                          );
                          supProv.loadPendingRequests();
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(supProv.error ?? 'Failed to revoke')),
                          );
                        }
                      },
                    ),
                  ),
                )),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
