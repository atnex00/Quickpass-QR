import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
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

  void _rebuild() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.pending_actions_outlined), activeIcon: Icon(Icons.pending_actions), label: 'Requests'),
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
                        backgroundColor: QuickpassColors.secondary,
                        child: Text(
                          (auth.user?.fullName ?? 'S').substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(auth.user?.fullName ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            Text(auth.user?.departmentName ?? '', style: const TextStyle(color: QuickpassColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Pending count
              Card(
                color: QuickpassColors.primary,
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
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.pending_actions, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${supProv.pendingCount}',
                                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                              const Text('Pending Requests', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ActionCard(
                    icon: Icons.pending_actions,
                    label: 'Review Pending',
                    color: Colors.orange,
                    onTap: () {
                      final parent = context.findAncestorStateOfType<_SupervisorDashboardState>();
                      parent?._switchToRequests();
                    },
                  ),
                  const SizedBox(width: 12),
                  _ActionCard(
                    icon: Icons.calendar_month,
                    label: 'Team Calendar',
                    color: QuickpassColors.secondary,
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Text('Approved Leaves', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Tap to revoke approval', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 8),

              if (supProv.approvedLeaves.isEmpty)
                Card(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text('No approved leaves', style: TextStyle(color: Colors.grey[500]))),
                ))
              else
                ...supProv.approvedLeaves.take(5).map((leave) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: QuickpassColors.primary,
                      radius: 18,
                      child: Text(leave.employeeName[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                    title: Text(leave.employeeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text('${leave.startTime} - ${leave.endTime}', style: const TextStyle(fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.undo, color: Colors.amber),
                      onPressed: () async {
                        final ok = await supProv.revokeApproval(leave.leaveId);
                        if (ok != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Approval revoked'), backgroundColor: QuickpassColors.success),
                          );
                          supProv.loadPendingRequests();
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(supProv.error ?? 'Failed to revoke'), backgroundColor: QuickpassColors.error),
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
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension on _SupervisorDashboardState {
  void _switchToRequests() {
    final dashState = context.findAncestorStateOfType<_SupervisorDashboardState>();
    if (dashState != null) {
      dashState._currentIndex = 1;
      dashState._rebuild();
    }
  }
}
