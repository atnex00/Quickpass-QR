import 'package:flutter/material.dart';

class QuickpassAppBar extends StatelessWidget implements PreferredSizeWidget {

  const QuickpassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBack = false,
  });
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      title: Text(title),
      leading: leading ??
          (showBack ? BackButton(color: colorScheme.onPrimary) : null),
      actions: actions,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 0,
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
