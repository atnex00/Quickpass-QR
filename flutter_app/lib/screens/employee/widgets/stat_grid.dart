import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../utils/responsive.dart';

class StatGrid extends StatelessWidget {
  const StatGrid({
    super.key,
    required this.pendingCount,
    required this.approvedCount,
    required this.completedCount,
  });
  final int pendingCount;
  final int approvedCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return isSmallScreen(context)
        ? Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: _StatCard('Pending', pendingCount.toString(), context.warning)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _StatCard('Approved', approvedCount.toString(), context.success)),
                ],
              ),
              const SizedBox(height: 8),
              _StatCard('Completed', completedCount.toString(), context.primaryBlue),
            ],
          )
        : Row(
            children: [
              Expanded(child: _StatCard('Pending', pendingCount.toString(), context.warning)),
              const SizedBox(width: 8),
              Expanded(child: _StatCard('Approved', approvedCount.toString(), context.success)),
              const SizedBox(width: 8),
              Expanded(child: _StatCard('Completed', completedCount.toString(), context.primaryBlue)),
            ],
          );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.title, this.value, this.color);
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: context.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outlineVariant),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.outline,
            ),
          ),
          const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: responsiveFontSize(context, 20),
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }
}
