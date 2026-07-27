import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../utils/responsive.dart';
import '../admin_shared.dart';

class LeaveBreakdownSection extends StatelessWidget {
  const LeaveBreakdownSection({
    super.key,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
    required this.activeCount,
    required this.completedCount,
  });
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final int activeCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    final sections = <PieChartSectionData>[];
    final entries = [
      ('Pending', pendingCount, context.warning),
      ('Approved', approvedCount, context.primaryBlue),
      ('Rejected', rejectedCount, context.error),
      ('Active', activeCount, context.success),
      ('Completed', completedCount, context.secondary),
    ];
    for (final e in entries) {
      if (e.$2 > 0) {
        sections.add(PieChartSectionData(
          value: e.$2.toDouble(),
          title: '${e.$2}',
          color: e.$3,
          radius: 40,
          titleStyle: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
        ));
      }
    }
    if (sections.isEmpty) {
      sections.add(PieChartSectionData(
        value: 1,
        title: '0',
        color: context.neutralGray.withValues(alpha: 0.3),
        radius: 40,
        titleStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: context.neutralGray),
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Leave Breakdown',
          style: TextStyle(
            fontSize: responsiveFontSize(context, 16),
            fontWeight: FontWeight.w600,
            color: context.onSurface,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.outlineVariant),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 180,
                child: PieChart(
                    PieChartData(sections: sections, centerSpaceRadius: 30)),
              ),
              const SizedBox(height: 16),
              AdminStatusLegend(
                  label: 'Pending',
                  count: pendingCount,
                  color: context.warning),
              const SizedBox(height: 4),
              AdminStatusLegend(
                  label: 'Approved',
                  count: approvedCount,
                  color: context.primaryBlue),
              const SizedBox(height: 4),
              AdminStatusLegend(
                  label: 'Rejected',
                  count: rejectedCount,
                  color: context.error),
              const SizedBox(height: 4),
              AdminStatusLegend(
                  label: 'Active', count: activeCount, color: context.success),
              const SizedBox(height: 4),
              AdminStatusLegend(
                  label: 'Completed',
                  count: completedCount,
                  color: context.secondary),
            ],
          ),
        ),
      ],
    );
  }
}
