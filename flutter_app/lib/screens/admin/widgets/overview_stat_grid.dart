import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../admin_shared.dart';

class OverviewStatGrid extends StatelessWidget {
  const OverviewStatGrid({
    super.key,
    required this.employeeCount,
    required this.pendingCount,
    required this.activeCount,
    required this.departmentCount,
  });
  final int employeeCount;
  final int pendingCount;
  final int activeCount;
  final int departmentCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            AdminStatCard(
              icon: Icons.people,
              label: 'Employees',
              value: '$employeeCount',
              color: context.secondary,
            ),
            const SizedBox(width: 8),
            AdminStatCard(
              icon: Icons.pending_actions,
              label: 'Pending',
              value: '$pendingCount',
              color: context.warning,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            AdminStatCard(
              icon: Icons.verified_user,
              label: 'Active',
              value: '$activeCount',
              color: context.success,
            ),
            const SizedBox(width: 8),
            AdminStatCard(
              icon: Icons.business,
              label: 'Departments',
              value: '$departmentCount',
              color: context.primaryBlue,
            ),
          ],
        ),
      ],
    );
  }
}
