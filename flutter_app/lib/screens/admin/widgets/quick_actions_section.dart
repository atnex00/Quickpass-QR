import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../utils/responsive.dart';
import '../../shared/admin_shared.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key, required this.onSwitchTab});
  final void Function(int) onSwitchTab;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
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
                icon: Icons.people,
                title: 'Manage Employees',
                subtitle: 'CRUD operations',
                onTap: () => onSwitchTab(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdminQuickActionCard(
                icon: Icons.business,
                title: 'Departments',
                subtitle: 'Organize teams',
                onTap: () => onSwitchTab(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AdminQuickActionCard(
                icon: Icons.bar_chart,
                title: 'Reports',
                subtitle: 'View analytics',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text('Scroll down to view leave breakdown')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
