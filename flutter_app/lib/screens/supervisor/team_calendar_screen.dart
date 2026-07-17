import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../models/leave_request.dart';
import '../../providers/supervisor_provider.dart';
import '../../utils/date_formatter.dart';
import '../../utils/responsive.dart';
import '../../widgets/status_badge.dart';

class TeamCalendarScreen extends StatefulWidget {
  const TeamCalendarScreen({super.key});

  @override
  State<TeamCalendarScreen> createState() => _TeamCalendarScreenState();
}

class _TeamCalendarScreenState extends State<TeamCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<LeaveRequest>> _groupByDate(List<LeaveRequest> leaves) {
    final map = <DateTime, List<LeaveRequest>>{};
    for (final l in leaves) {
      final date = DateTime(l.leaveDate.year, l.leaveDate.month, l.leaveDate.day);
      map.putIfAbsent(date, () => []).add(l);
    }
    return map;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchMonth(_focusedDay));
  }

  void _fetchMonth(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1, 0);
    context.read<SupervisorProvider>().loadTeamLeaves(
      startDate: DateFormatter.formatDateApi(start),
      endDate: DateFormatter.formatDateApi(end),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leaves = context.watch<SupervisorProvider>().teamLeaves;
    final byDate = _groupByDate(leaves);
    final selectedLeaves = _selectedDay != null ? byDate[_selectedDay] ?? [] : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Calendar'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<SupervisorProvider>().loadTeamLeaves(
            startDate: DateFormatter.formatDateApi(
              DateTime(_focusedDay.year, _focusedDay.month),
            ),
            endDate: DateFormatter.formatDateApi(
              DateTime(_focusedDay.year, _focusedDay.month + 1, 0),
            ),
          );
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _CalendarSection(
                focusedDay: _focusedDay,
                selectedDay: _selectedDay,
                leavesByDate: byDate,
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                onPageChanged: (focused) {
                  setState(() => _focusedDay = focused);
                  _fetchMonth(focused);
                },
              ),
            ),
            if (_selectedDay != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    DateFormatter.formatDate(_selectedDay!),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.onSurface,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            if (selectedLeaves.isEmpty && _selectedDay != null)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.outlineVariant),
                    ),
                    child: Center(
                      child: Text(
                        'No leaves on this date',
                        style: TextStyle(color: context.neutralGray),
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final leave = selectedLeaves[index];
                    return _LeaveCard(leave: leave);
                  },
                  childCount: selectedLeaves.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CalendarSection extends StatelessWidget {
  const _CalendarSection({
    required this.focusedDay,
    required this.selectedDay,
    required this.leavesByDate,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Map<DateTime, List<LeaveRequest>> leavesByDate;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final void Function(DateTime focusedDay) onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(
          bottom: BorderSide(color: context.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: TableCalendar(
        firstDay: DateTime(2020),
        lastDay: DateTime(2030),
        focusedDay: focusedDay,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        availableCalendarFormats: const {CalendarFormat.month: 'Month'},
        onDaySelected: onDaySelected,
        onPageChanged: onPageChanged,
        eventLoader: (day) => leavesByDate[DateTime(day.year, day.month, day.day)] ?? [],
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: context.primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: context.primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            fontWeight: FontWeight.w600,
            color: context.primary,
          ),
          markersMaxCount: 3,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.onSurface,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: context.primary),
          rightChevronIcon: Icon(Icons.chevron_right, color: context.primary),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return null;
            final statuses = events
                .map((e) => (e as LeaveRequest).status)
                .toSet();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (statuses.contains(LeaveStatus.approved))
                  _dot(QuickpassColors.primary),
                if (statuses.contains(LeaveStatus.active))
                  _dot(QuickpassColors.success),
                if (statuses.contains(LeaveStatus.pending))
                  _dot(QuickpassColors.warning),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  const _LeaveCard({required this.leave});
  final LeaveRequest leave;

  static String? _photo(LeaveRequest l) => AppConfig.photoUrl(l.employeePhoto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: context.primary.withValues(alpha: 0.2),
                backgroundImage: _photo(leave) != null
                    ? NetworkImage(_photo(leave)!)
                    : null,
                child: _photo(leave) == null
                    ? Text(
                        leave.employeeName.isNotEmpty
                            ? leave.employeeName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: context.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leave.employeeName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: context.onSurface,
                      ),
                    ),
                    if (leave.employeePosition != null)
                      Text(
                        leave.employeePosition!,
                        style: TextStyle(
                          color: context.neutralGray,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: context.neutralGray),
                        const SizedBox(width: 4),
                        Text(
                          '${leave.startTime} - ${leave.endTime}',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.neutralGray,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              StatusBadge(status: leave.status),
            ],
          ),
        ),
      ),
    );
  }
}
