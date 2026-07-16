import 'package:flutter/material.dart';

import '../config/theme.dart';

class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 12, color: context.warning),
          const SizedBox(width: 4),
          Text(
            'Showing cached data',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: context.warning,
            ),
          ),
        ],
      ),
    );
  }
}
