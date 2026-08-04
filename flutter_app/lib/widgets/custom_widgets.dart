import 'package:flutter/material.dart';
import '../config/theme.dart';

class InfoRow extends StatelessWidget {

  const InfoRow(
      {super.key, required this.label, required this.value, this.trailing});
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14, color: context.onSurfaceVariant, height: 1.43)),
        const SizedBox(width: 8),
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ] else ...[
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.onSurface,
                    height: 1.43)),
          ),
        ],
      ],
    );
  }
}

class GuidelineItem extends StatelessWidget {

  const GuidelineItem({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('\u2022',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: context.primaryBlue)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style:
                    TextStyle(fontSize: 14, color: context.onSurfaceVariant))),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.isOffline = false,
    this.error,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final bool isOffline;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final displayTitle = error ?? title;
    final displaySubtitle = error != null
        ? 'Pull down to retry'
        : (isOffline ? 'Check your internet connection' : subtitle);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              error != null ? Icons.cloud_off : icon,
              size: 64,
              color: error != null ? context.warning : context.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              displayTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: context.onSurfaceVariant,
              ),
            ),
            if (displaySubtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                displaySubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.neutralGray),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
