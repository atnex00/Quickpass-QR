import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/leave_request.dart';
import '../../services/api_service.dart';
import '../../utils/date_formatter.dart';
import '../../utils/errors.dart';
import '../../widgets/custom_widgets.dart';
import 'admin_shared.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  late final ApiService _api;
  List<dynamic>? _reportData;
  List<dynamic>? _departmentReport;
  bool _isLoading = true;
  String? _error;
  String _reportType = '';
  DateTime? _startDate;
  DateTime? _endDate;
  final _startCtl = TextEditingController();
  final _endCtl = TextEditingController();
  List<BarChartGroupData>? _cachedBarGroups;

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReports();
    });
  }

  @override
  void dispose() {
    _startCtl.dispose();
    _endCtl.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final params = <String, dynamic>{};
      if (_reportType.isNotEmpty) params['type'] = _reportType;
      if (_startDate != null) {
        params['start_date'] = DateFormatter.formatDateApi(_startDate!);
      }
      if (_endDate != null) {
        params['end_date'] = DateFormatter.formatDateApi(_endDate!);
      }
      _reportData = (await _api.getReports(
          type: params['type'],
          startDate: params['start_date'],
          endDate: params['end_date']))['data'] as List?;
      final deptRes = await _api.getReports(type: 'department');
      _departmentReport = deptRes['data'] as List<dynamic>?;
      _computeCounts();
    } catch (e) {
      _error = friendlyError(e);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _computeCounts() {
    _statusCounts = {};
    _cachedBarGroups = null;
    if (_reportData == null) return;
    for (final entry in _reportData!) {
      final s = entry['status'] as String? ?? 'unknown';
      _statusCounts[s] = (_statusCounts[s] ?? 0) + 1;
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          _startCtl.text = DateFormatter.formatDateApi(picked);
        } else {
          _endDate = picked;
          _endCtl.text = DateFormatter.formatDateApi(picked);
        }
      });
      _loadReports();
    }
  }

  Map<String, int> _statusCounts = {};

  double get _maxDeptCount {
    if (_departmentReport == null || _departmentReport!.isEmpty) return 10;
    double max = 0;
    for (final d in _departmentReport!) {
      for (final key in ['pending', 'approved', 'rejected', 'completed']) {
        final val = num.tryParse('${d[key]}')?.toDouble() ?? 0;
        if (val > max) max = val;
      }
    }
    return max < 10 ? 10 : max;
  }

  List<BarChartGroupData> _buildBarGroups() {
    if (_cachedBarGroups != null) return _cachedBarGroups!;
    if (_departmentReport == null) return [];
    _cachedBarGroups = List.generate(_departmentReport!.length, (i) {
      final d = _departmentReport![i];
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: num.tryParse('${d['pending']}')?.toDouble() ?? 0,
            color: context.warning,
            width: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: num.tryParse('${d['approved']}')?.toDouble() ?? 0,
            color: context.primaryBlue,
            width: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: num.tryParse('${d['rejected']}')?.toDouble() ?? 0,
            color: context.error,
            width: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: num.tryParse('${d['completed']}')?.toDouble() ?? 0,
            color: context.success,
            width: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        barsSpace: 3,
      );
    });
    return _cachedBarGroups!;
  }

  Widget _buildDepartmentBarChart() {
    if (_departmentReport == null || _departmentReport!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Department Overview',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.onSurface,
                  height: 1.5)),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _maxDeptCount * 1.3,
                groupsSpace: 16,
                barGroups: _buildBarGroups(),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: context.outlineVariant.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 ||
                            idx >= (_departmentReport?.length ?? 0)) {
                          return const SizedBox.shrink();
                        }
                        final dept = _departmentReport![idx];
                        final code = dept['department_code'] as String? ??
                            dept['department_name'] as String? ??
                            '';
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            code,
                            style:
                                TextStyle(fontSize: 10, color: context.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max) return const SizedBox.shrink();
                        return Text(
                          '${value.toInt()}',
                          style:
                              TextStyle(fontSize: 10, color: context.onSurfaceVariant),
                    );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                  ),
                  rightTitles: const AxisTitles(
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final dept = _departmentReport![group.x.toInt()];
                      final deptName = dept['department_name'] as String? ?? '';
                      final statusLabels = [
                        'Pending',
                        'Approved',
                        'Rejected',
                        'Completed'
                      ];
                      final statusColors = [
                        context.warning,
                        context.primaryBlue,
                        context.error,
                        context.success,
                      ];
                      return BarTooltipItem(
                        '$deptName\n',
                        TextStyle(
                            color: context.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 12),
                        children: [
                          TextSpan(
                            text: '${statusLabels[rodIndex]}: ',
                            style: TextStyle(
                                color: statusColors[rodIndex],
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                          ),
                          TextSpan(
                            text: '${rod.toY.toInt()}',
                            style: TextStyle(
                                color: context.onSurface, fontSize: 12),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildBarLegend(),
          const SizedBox(height: 12),
          _buildDepartmentLegend(),
        ],
      ),
    );
  }

  Widget _buildDepartmentLegend() {
    if (_departmentReport == null || _departmentReport!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Department Legend',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          ..._departmentReport!.map((d) {
            final code = d['department_code'] as String? ?? '';
            final fullName = d['department_name'] as String? ?? '';
            final parts = fullName.split('·');
            final name = parts.length > 1 ? parts.last.trim() : fullName;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                          fontSize: 12, color: context.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBarLegend() {
    final entries = [
      ('Pending', context.warning),
      ('Approved', context.primaryBlue),
      ('Rejected', context.error),
      ('Completed', context.success),
    ];
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: entries.map((e) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: e.$2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(e.$1, style: TextStyle(fontSize: 11, color: context.onSurfaceVariant)),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadReports,
            child: CustomScrollView(
              slivers: [
                buildAdminAppBar(context, 'reports'),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      ReportsFilterBar(
                        startCtl: _startCtl,
                        endCtl: _endCtl,
                        reportType: _reportType,
                        onPickDate: _pickDate,
                        onFilterChanged: (type) {
                          setState(() => _reportType = type);
                          _loadReports();
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const Center(
                            child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ))
                      else if (_error != null)
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.error_outline, size: 48, color: context.error),
                              const SizedBox(height: 12),
                              Text(_error!, textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 15)),
                              const SizedBox(height: 16),
                              FilledButton(onPressed: _loadReports, child: const Text('Retry')),
                            ],
                          ),
                        )
                      else ...[
                        ReportsStatSummary(
                          statusCounts: _statusCounts,
                          departmentCount: _departmentReport?.length ?? 0,
                        ),
                        const SizedBox(height: 16),
                        _buildDepartmentBarChart(),
                        Text('Leave Requests',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: context.onSurface,
                                height: 1.5)),
                        const SizedBox(height: 8),
                        if (_reportData == null || _reportData!.isEmpty)
                          const EmptyState(
                            icon: Icons.inbox_outlined,
                            title: 'No leave requests found',
                          ),
                      ],
                    ]),
                  ),
                ),
                if (_reportData != null && _reportData!.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = _reportData![index];
                          final leaveStatus = LeaveStatus.fromString(
                              entry['status'] as String? ?? '');
                          final statusColor = leaveStatus.color(context);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.outlineVariant),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${entry['employee_name'] ?? 'Unknown'}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: context.onSurface),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${entry['leave_date'] ?? ''} \u2022 ${entry['start_time'] ?? ''}-${entry['end_time'] ?? ''}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: context.onSurfaceVariant),
                                      ),
                                      Text(
                                        entry['reason'] ?? '',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: context.neutralGray),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                        color:
                                            statusColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    leaveStatus.label,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: _reportData!.length.clamp(0, 50),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReportsFilterBar extends StatelessWidget {

  const ReportsFilterBar({
    super.key,
    required this.startCtl,
    required this.endCtl,
    required this.reportType,
    required this.onPickDate,
    required this.onFilterChanged,
  });
  final TextEditingController startCtl;
  final TextEditingController endCtl;
  final String reportType;
  final void Function(bool isStart) onPickDate;
  final void Function(String type) onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: startCtl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Start Date',
                  prefixIcon: Icon(Icons.calendar_today, size: 18),
                  isDense: true,
                ),
                onTap: () => onPickDate(true),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('to', style: TextStyle(color: context.neutralGray)),
            ),
            Expanded(
              child: TextField(
                controller: endCtl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'End Date',
                  prefixIcon: Icon(Icons.calendar_today, size: 18),
                  isDense: true,
                ),
                onTap: () => onPickDate(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              AdminFilterChip(
                  label: 'All',
                  selected: reportType.isEmpty,
                  onTap: () => onFilterChanged('')),
              const SizedBox(width: 8),
              AdminFilterChip(
                  label: 'Department',
                  selected: reportType == 'department',
                  onTap: () => onFilterChanged('department')),
              const SizedBox(width: 8),
              AdminFilterChip(
                  label: 'Employee',
                  selected: reportType == 'employee',
                  onTap: () => onFilterChanged('employee')),
            ],
          ),
        ),
      ],
    );
  }
}

class ReportsStatSummary extends StatelessWidget {

  const ReportsStatSummary({
    super.key,
    required this.statusCounts,
    required this.departmentCount,
  });
  final Map<String, int> statusCounts;
  final int departmentCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            AdminStatCard(
                icon: Icons.pending_actions,
                label: 'Pending',
                value: '${statusCounts['pending'] ?? 0}',
                color: context.warning),
            const SizedBox(width: 8),
            AdminStatCard(
                icon: Icons.check_circle,
                label: 'Approved',
                value: '${statusCounts['approved'] ?? 0}',
                color: context.success),
            const SizedBox(width: 8),
            AdminStatCard(
                icon: Icons.cancel,
                label: 'Rejected',
                value: '${statusCounts['rejected'] ?? 0}',
                color: context.error),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            AdminStatCard(
                icon: Icons.timer,
                label: 'Active',
                value: '${statusCounts['active'] ?? 0}',
                color: context.primaryBlue),
            const SizedBox(width: 8),
            AdminStatCard(
                icon: Icons.check_circle_outline,
                label: 'Completed',
                value: '${statusCounts['completed'] ?? 0}',
                color: context.secondary),
            const SizedBox(width: 8),
            AdminStatCard(
                icon: Icons.business,
                label: 'Departments',
                value: '$departmentCount',
                color: context.tertiary),
          ],
        ),
      ],
    );
  }
}
