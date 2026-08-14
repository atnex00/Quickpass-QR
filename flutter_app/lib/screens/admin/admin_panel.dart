import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/adaptive_scaffold.dart';
import '../security/scanner_screen.dart';
import 'admin_department_tab.dart';
import 'admin_employee_tab.dart';
import 'admin_leave_tab.dart';
import 'admin_overview_tab.dart';
import 'admin_reports_tab.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated || !auth.isAdmin) {
      return const SizedBox.shrink();
    }

    return AdaptiveScaffold(
      selectedIndex: _currentIndex,
      onDestinationSelected: (i) => setState(() => _currentIndex = i),
      destinations: const [
        AdaptiveDestination(
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          label: 'Overview',
        ),
        AdaptiveDestination(
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          label: 'Employees',
        ),
        AdaptiveDestination(
          icon: Icons.business_outlined,
          selectedIcon: Icons.business,
          label: 'Departments',
        ),
        AdaptiveDestination(
          icon: Icons.bar_chart_outlined,
          selectedIcon: Icons.bar_chart,
          label: 'Reports',
        ),
        AdaptiveDestination(
          icon: Icons.event_note_outlined,
          selectedIcon: Icons.event_note,
          label: 'Leaves',
        ),
        AdaptiveDestination(
          icon: Icons.qr_code_scanner_outlined,
          selectedIcon: Icons.qr_code_scanner,
          label: 'Scan',
        ),
      ],
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            OverviewTab(onSwitchTab: (i) => setState(() => _currentIndex = i)),
            const EmployeeTab(),
            const DepartmentTab(),
            const ReportsTab(),
            const LeaveTab(),
            ScannerScreen(active: _currentIndex == 5),
          ],
        ),
      ),
    );
  }
}
