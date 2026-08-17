import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/adaptive_scaffold.dart';
import 'scan_history_screen.dart';
import 'scanner_screen.dart';
import 'security_dashboard_tab.dart';
import 'security_directory_screen.dart';

class SecurityShell extends StatefulWidget {
  const SecurityShell({super.key});

  @override
  State<SecurityShell> createState() => _SecurityShellState();
}

class _SecurityShellState extends State<SecurityShell> {
  int _currentIndex = 0;

  void _onTabSelected(int i) {
    setState(() => _currentIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated || (!auth.isSecurity && !auth.isAdmin)) {
      return const SizedBox.shrink();
    }

    return AdaptiveScaffold(
      selectedIndex: _currentIndex,
      onDestinationSelected: _onTabSelected,
      destinations: const [
        AdaptiveDestination(
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          label: 'Dashboard',
        ),
        AdaptiveDestination(
          icon: Icons.qr_code_scanner_outlined,
          selectedIcon: Icons.qr_code_scanner,
          label: 'Scan',
        ),
        AdaptiveDestination(
          icon: Icons.history_outlined,
          selectedIcon: Icons.history,
          label: 'History',
        ),
        AdaptiveDestination(
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          label: 'Directory',
        ),
      ],
      body: IndexedStack(
        index: _currentIndex,
        children: [
          SecurityDashboardTab(
            onScanRequested: () => _onTabSelected(1),
          ),
          ScannerScreen(active: _currentIndex == 1),
          const ScanHistoryScreen(showBack: false),
          const SecurityDirectoryScreen(),
        ],
      ),
    );
  }
}
