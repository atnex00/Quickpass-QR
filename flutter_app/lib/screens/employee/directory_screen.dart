import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../models/employee.dart';
import '../../providers/directory_provider.dart';
import '../../utils/responsive.dart';
import '../../widgets/offline_indicator.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  String? _positionFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DirectoryProvider>().loadDirectory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dirProv = context.watch<DirectoryProvider>();
    final directory = dirProv.directory;
    final positions = directory
        .map((e) => e.position)
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final filtered = _positionFilter == null
        ? directory
        : directory.where((e) => e.position == _positionFilter).toList();

    final byDepartment = <String, List<Employee>>{};
    for (final e in filtered) {
      byDepartment.putIfAbsent(e.departmentName, () => []).add(e);
    }
    final departmentNames = byDepartment.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Directory'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<DirectoryProvider>().loadDirectory(),
        child: Column(
          children: [
            if (positions.isNotEmpty)
              SizedBox(
                height: 52,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: positions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final p = positions[i];
                    final selected = p == _positionFilter;
                    return FilterChip(
                      label: Text(p, style: const TextStyle(fontSize: 12)),
                      selected: selected,
                      showCheckmark: false,
                      onSelected: (_) =>
                          setState(() => _positionFilter = selected ? null : p),
                      backgroundColor: context.surface,
                      selectedColor: context.primary.withValues(alpha: 0.15),
                      side: BorderSide(
                        color: selected
                            ? context.primary.withValues(alpha: 0.5)
                            : context.outlineVariant,
                      ),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? context.primary : context.onSurface,
                      ),
                    );
                  },
                ),
              ),
            if (dirProv.fromCache)
              const Padding(
                padding: EdgeInsets.only(top: 4, bottom: 4),
                child: OfflineIndicator(),
              ),
            Expanded(
              child: dirProv.isLoading && directory.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : departmentNames.isEmpty
                      ? _EmptyState()
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          children: [
                            for (final name in departmentNames) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 8, bottom: 6),
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: context.primary,
                                  ),
                                ),
                              ),
                              for (final e in byDepartment[name]!)
                                _MemberTile(employee: e),
                              const SizedBox(height: 8),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.employee});
  final Employee employee;

  @override
  Widget build(BuildContext context) {
    final photoUrl = AppConfig.photoUrl(employee.profilePhoto);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _Avatar(photoUrl: photoUrl, name: employee.fullName),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.fullName,
                    style: TextStyle(
                      fontSize: responsiveFontSize(context, 15),
                      fontWeight: FontWeight.w600,
                      color: context.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          employee.position,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (employee.isSupervisor) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Supervisor',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: context.warning,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.name});
  final String? photoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).map((p) => p[0]).take(2).join();

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: context.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl != null
          ? Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _InitialsFallback(initials: initials, color: context.primary),
            )
          : _InitialsFallback(initials: initials, color: context.primary),
    );
  }
}

class _InitialsFallback extends StatelessWidget {
  const _InitialsFallback({required this.initials, required this.color});
  final String initials;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 48, color: context.neutralGray),
          const SizedBox(height: 12),
          Text(
            'No employees found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}