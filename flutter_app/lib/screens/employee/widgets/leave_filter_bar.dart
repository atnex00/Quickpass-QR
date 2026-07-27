import 'package:flutter/material.dart';

import '../../../config/theme.dart';

class LeaveFilterBarDelegate extends SliverPersistentHeaderDelegate {
  LeaveFilterBarDelegate(this.currentFilter, this.onFilterChanged);
  final String? currentFilter;
  final void Function(String?) onFilterChanged;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: 56,
      color: context.surface.withValues(alpha: 0.95),
      child: ListView(
        padding: const EdgeInsets.only(left: 16),
        scrollDirection: Axis.horizontal,
        children: [
          Center(
              child: _FilterChip(
                  label: 'All',
                  selected: currentFilter == null,
                  onTap: () => onFilterChanged(null))),
          const SizedBox(width: 8),
          Center(
              child: _FilterChip(
                  label: 'Pending',
                  selected: currentFilter == 'pending',
                  onTap: () => onFilterChanged('pending'))),
          const SizedBox(width: 8),
          Center(
              child: _FilterChip(
                  label: 'Approved',
                  selected: currentFilter == 'approved',
                  onTap: () => onFilterChanged('approved'))),
          const SizedBox(width: 8),
          Center(
              child: _FilterChip(
                  label: 'Rejected',
                  selected: currentFilter == 'rejected',
                  onTap: () => onFilterChanged('rejected'))),
          const SizedBox(width: 8),
          Center(
              child: _FilterChip(
                  label: 'Completed',
                  selected: currentFilter == 'completed',
                  onTap: () => onFilterChanged('completed'))),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 56;

  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(covariant LeaveFilterBarDelegate oldDelegate) {
    return currentFilter != oldDelegate.currentFilter;
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? context.primaryBlue : context.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? context.primaryBlue : context.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.01,
            color: selected ? Colors.white : context.onSurface,
          ),
        ),
      ),
    );
  }
}
