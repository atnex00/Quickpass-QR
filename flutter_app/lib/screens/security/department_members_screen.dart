import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../models/employee.dart';
import '../../utils/responsive.dart';

class DepartmentMembersScreen extends StatefulWidget {
  const DepartmentMembersScreen({
    super.key,
    required this.departmentName,
    required this.departmentCode,
    required this.members,
  });
  final String departmentName;
  final String departmentCode;
  final List<Employee> members;

  @override
  State<DepartmentMembersScreen> createState() =>
      _DepartmentMembersScreenState();
}

class _DepartmentMembersScreenState extends State<DepartmentMembersScreen> {
  String? _positionFilter;

  @override
  Widget build(BuildContext context) {
    final positions = widget.members
        .map((e) => e.position)
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final filtered = _positionFilter == null
        ? widget.members
        : widget.members.where((e) => e.position == _positionFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.departmentName),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: context.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.departmentCode} \u2022 ${filtered.length} members',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: context.primary,
                  ),
                ),
              ),
            ),
          ),
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
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_off_outlined,
                            size: 48, color: context.neutralGray),
                        const SizedBox(height: 12),
                        Text(
                          'No members found',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) =>
                        _MemberTile(employee: filtered[i]),
                  ),
          ),
        ],
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