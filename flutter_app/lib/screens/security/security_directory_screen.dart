import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/employee.dart';
import '../../providers/directory_provider.dart';
import '../../utils/responsive.dart';
import '../../widgets/offline_indicator.dart';
import 'department_members_screen.dart';

class SecurityDirectoryScreen extends StatefulWidget {
  const SecurityDirectoryScreen({super.key});

  @override
  State<SecurityDirectoryScreen> createState() =>
      _SecurityDirectoryScreenState();
}

class _SecurityDirectoryScreenState extends State<SecurityDirectoryScreen> {
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
    final byDepartment = <String, List<Employee>>{};
    for (final e in dirProv.directory) {
      if (e.departmentId.isEmpty) continue;
      byDepartment.putIfAbsent(e.departmentId, () => []).add(e);
    }
    final departments = byDepartment.values
        .map((members) => (members.first, members.length))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Directory'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<DirectoryProvider>().loadDirectory(),
        child: Column(
          children: [
            if (dirProv.fromCache)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: OfflineIndicator(),
              ),
            Expanded(
              child: dirProv.isLoading && departments.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : departments.isEmpty
                      ? _EmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: departments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final (member, count) = departments[i];
                            return _DepartmentCard(
                              departmentName: member.departmentName,
                              departmentCode: member.departmentCode,
                              memberCount: count,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DepartmentMembersScreen(
                                      departmentName: member.departmentName,
                                      departmentCode: member.departmentCode,
                                      members: byDepartment[member.departmentId]!,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({
    required this.departmentName,
    required this.departmentCode,
    required this.memberCount,
    required this.onTap,
  });
  final String departmentName;
  final String departmentCode;
  final int memberCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: context.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  departmentCode,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: context.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  departmentName,
                  style: TextStyle(
                    fontSize: responsiveFontSize(context, 15),
                    fontWeight: FontWeight.w600,
                    color: context.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$memberCount',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.onSurfaceVariant,
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

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.business_outlined, size: 48, color: context.neutralGray),
          const SizedBox(height: 12),
          Text(
            'No departments found',
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