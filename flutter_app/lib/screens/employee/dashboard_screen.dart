import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/leave_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/loading_indicator.dart';
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
        children: [
          const _DashboardTab(),
          const LeaveHistoryScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final leaveProv = context.watch<LeaveProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => leaveProv.refresh(),
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
                        backgroundColor: colorScheme.primary,
                        child: Text(
                          (auth.user?.fullName ?? 'U').substring(0, 1).toUpperCase(),
                          style: TextStyle(fontSize: 24, color: colorScheme.onPrimary, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(auth.user?.fullName ?? '', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                            const SizedBox(height: 2),
                            Text(auth.user?.position ?? '', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                            Text('ID: ${auth.user?.employeeId ?? ''}', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (leaveProv.activeLeave != null)
                Card(
                  color: colorScheme.primaryContainer,
                  child: ListTile(
                    leading: Icon(Icons.timer, color: colorScheme.primary),
                    title: Text('Active Leave', style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onPrimaryContainer)),
                    subtitle: Text('Until ${leaveProv.activeLeave!.endTime}', style: TextStyle(color: colorScheme.onPrimaryContainer)),
                    trailing: TextButton(
                      onPressed: () {
                        if (leaveProv.activeLeave!.hasQrCodes) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => QrDisplayScreen(leave: leaveProv.activeLeave!)));
                        }
                      },
                      child: const Text('View QR'),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatCard('Pending', leaveProv.pendingCount.toString(), colorScheme.tertiary, Icons.hourglass_empty),
                  const SizedBox(width: 12),
                  _StatCard('Approved', leaveProv.approvedCount.toString(), colorScheme.primary, Icons.check_circle),
                  const SizedBox(width: 12),
                  _StatCard('Completed', leaveProv.completedCount.toString(), colorScheme.secondary, Icons.check_circle_outline),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestLeaveScreen())),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Request Leave'),
                ),
              ),
              const SizedBox(height: 24),
              Text('Recent Requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
              const SizedBox(height: 8),
              if (leaveProv.isLoading)
                const LoadingIndicator()
              else if (leaveProv.history.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: colorScheme.outlineVariant),
                          const SizedBox(height: 12),
                          Text('No leave requests yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Text('Submit a leave request to get started', style: TextStyle(fontSize: 13, color: colorScheme.outline)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...leaveProv.history.take(5).map((leave) => _LeaveCard(leave: leave, colorScheme: colorScheme)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard(this.title, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
              Text(title, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final LeaveRequest leave;
  final ColorScheme colorScheme;

  const _LeaveCard({required this.leave, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (leave.hasQrCodes) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => QrDisplayScreen(leave: leave)));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              StatusBadge(status: leave.status, fontSize: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(leave.leaveDate.toIso8601String().split('T').first, style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                    const SizedBox(height: 2),
                    Text('${leave.startTime} - ${leave.endTime}  \u2022  ${leave.durationText}', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
