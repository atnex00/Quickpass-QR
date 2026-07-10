import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../utils/responsive.dart';

class AdaptiveScaffold extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AdaptiveDestination> destinations;
  final Widget body;

  const AdaptiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final screenType = getScreenType(context);

    if (screenType == ScreenType.tablet || screenType == ScreenType.desktop) {
      return Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            backgroundColor: context.surface,
            indicatorColor: context.primary.withValues(alpha: 0.15),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.onPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset('assets/icon/app-icon.png',
                      width: 22, height: 22),
                ),
              ),
            ),
            destinations: destinations
                .map((d) => NavigationRailDestination(
                      icon: Icon(d.icon, color: context.onSurfaceVariant),
                      selectedIcon:
                          Icon(d.selectedIcon, color: context.primary),
                      label:
                          Text(d.label, style: const TextStyle(fontSize: 12)),
                    ))
                .toList(),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.outlineVariant)),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          backgroundColor: context.surface,
          indicatorColor: context.primary.withValues(alpha: 0.15),
          height: 80,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: destinations
              .map((d) => NavigationDestination(
                    icon: Icon(d.icon, color: context.onSurfaceVariant),
                    selectedIcon: Icon(d.selectedIcon, color: context.primary),
                    label: d.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class AdaptiveDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const AdaptiveDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
