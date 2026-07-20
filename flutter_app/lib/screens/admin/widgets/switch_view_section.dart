import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../utils/responsive.dart';
import '../../employee/dashboard_screen.dart';
import '../../security/scanner_screen.dart';
import '../../supervisor/supervisor_dashboard.dart';
import '../../shared/admin_shared.dart';

class SwitchViewSection extends StatelessWidget {
  const SwitchViewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Switch View',
          style: TextStyle(
            fontSize: responsiveFontSize(context, 16),
            fontWeight: FontWeight.w600,
            color: context.onSurface,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AdminQuickActionCard(
                icon: Icons.badge_outlined,
                title: 'Employee View',
                subtitle: 'Submit & track leaves',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EmployeeDashboard(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdminQuickActionCard(
                icon: Icons.rate_review_outlined,
                title: 'Supervisor View',
                subtitle: 'Approve & reject leaves',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SupervisorDashboard(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AdminQuickActionCard(
                icon: Icons.qr_code_scanner_outlined,
                title: 'Security View',
                subtitle: 'Scan QR codes at gates',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScannerScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }
}
