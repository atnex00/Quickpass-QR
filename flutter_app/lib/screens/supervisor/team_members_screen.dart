import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../models/employee.dart';
import '../../providers/directory_provider.dart';
import '../../utils/responsive.dart';
import '../../widgets/offline_indicator.dart';
import 'employee_leave_history_screen.dart';

class TeamMembersScreen extends StatefulWidget {
  const TeamMembersScreen({super.key});

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DirectoryProvider>().loadTeam();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dirProv = context.watch<DirectoryProvider>();
    final team = dirProv.team.where((e) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return e.fullName.toLowerCase().contains(q) ||
          e.position.toLowerCase().contains(q) ||
          e.employeeId.contains(q);
    }).toList();

    final departmentName =
        team.isNotEmpty ? team.first.departmentName : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Members'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<DirectoryProvider>().loadTeam(),
        child: Column(
          children: [
            if (departmentName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    departmentName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.primary,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search by name, position, or ID',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            if (dirProv.fromCache)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: OfflineIndicator(),
              ),
            Expanded(
              child: dirProv.isLoading && team.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : team.isEmpty
                      ? _EmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: team.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) =>
                              _MemberTile(employee: team[i]),
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
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  EmployeeLeaveHistoryScreen(employee: employee),
            ),
          );
        },
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
                    Text(
                      employee.position,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: context.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${employee.leaveCount} leaves',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.primary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right,
                  size: 20, color: context.onSurfaceVariant),
            ],
          ),
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
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: context.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl != null
          ? Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _InitialsFallback(
                  initials: initials, color: context.primary),
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
          fontSize: 16,
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
            'No team members found',
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