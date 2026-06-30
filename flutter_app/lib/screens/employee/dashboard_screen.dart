import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/leave_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../../widgets/status_badge.dart';
import '../auth/login_screen.dart';
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

  final _screens = [
    const _DashboardTab(),
    const LeaveHistoryScreen(),
  ];

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
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final leaveProv = context.watch<LeaveProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
            },
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
                        backgroundColor: QuickpassColors.primary,
                        child: Text(
                          (auth.user?.fullName ?? 'U').substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(auth.user?.fullName ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(auth.user?.position ?? '', style: const TextStyle(color: QuickpassColors.textSecondary, fontSize: 13)),
                            Text('ID: ${auth.user?.employeeId ?? ''}', style: const TextStyle(color: QuickpassColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Active leave banner
              if (leaveProv.activeLeave != null)
                Card(
                  color: QuickpassColors.success.withValues(alpha: 0.15),
                  child: ListTile(
                    leading: const Icon(Icons.timer, color: QuickpassColors.success),
                    title: const Text('Active Leave', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Until ${leaveProv.activeLeave!.endTime}'),
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

              // Quick stats
              Row(
                children: [
                  _StatCard('Pending', leaveProv.pendingCount.toString(), Colors.orange, Icons.hourglass_empty),
                  const SizedBox(width: 12),
                  _StatCard('Approved', leaveProv.approvedCount.toString(), const Color(0xFF8B5CF6), Icons.check_circle),
                  const SizedBox(width: 12),
                  _StatCard('Completed', leaveProv.completedCount.toString(), Colors.blue, Icons.check_circle_outline),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestLeaveScreen())),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Request Leave'),
                ),
              ),

              const SizedBox(height: 24),

              const Text('Recent Requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),

              if (leaveProv.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (leaveProv.history.isEmpty)
                Card(child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('No leave requests yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[700])),
                        const SizedBox(height: 4),
                        Text('Submit a leave request to get started', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                ))
              else
                ...leaveProv.history.take(5).map((leave) => _LeaveCard(leave: leave)),
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
              Text(title, style: const TextStyle(fontSize: 12, color: QuickpassColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final LeaveRequest leave;

  const _LeaveCard({required this.leave});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: StatusBadge(status: leave.status, fontSize: 10),
        title: Text(leave.leaveDate.toIso8601String().split('T').first, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${leave.startTime} - ${leave.endTime}  •  ${leave.durationText}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (leave.hasQrCodes) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => QrDisplayScreen(leave: leave)));
          }
        },
      ),
    );
  }
}
