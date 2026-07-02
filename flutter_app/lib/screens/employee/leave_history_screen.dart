import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/leave_request.dart';
import '../../providers/leave_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/loading_indicator.dart';
import 'qr_display_screen.dart';

class LeaveHistoryScreen extends StatefulWidget {
  const LeaveHistoryScreen({super.key});

  @override
  State<LeaveHistoryScreen> createState() => _LeaveHistoryScreenState();
}

class _LeaveHistoryScreenState extends State<LeaveHistoryScreen> {
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaveProvider>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final leaveProv = context.watch<LeaveProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave History'),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (s) {
              setState(() => _statusFilter = s);
              context.read<LeaveProvider>().loadHistory(status: s);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All')),
              ...LeaveStatus.values.map((s) => PopupMenuItem(
                value: s.name,
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(s.label),
                  ],
                ),
              )),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => leaveProv.loadHistory(status: _statusFilter),
        child: leaveProv.isLoading
            ? const LoadingIndicator()
            : leaveProv.history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: colorScheme.outlineVariant),
                        const SizedBox(height: 12),
                        Text('No leave requests found', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(
                          _statusFilter != null ? 'No $_statusFilter requests match your filter' : 'Submit a leave request to get started',
                          style: TextStyle(color: colorScheme.outline, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: leaveProv.history.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final leave = leaveProv.history[index];
                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            if (leave.hasQrCodes) {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => QrDisplayScreen(leave: leave),
                              ));
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      leave.leaveDate.toIso8601String().split('T').first,
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: colorScheme.onSurface),
                                    ),
                                    StatusBadge(status: leave.status),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 16, color: colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 4),
                                    Text('${leave.startTime} - ${leave.endTime}', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                                    const Spacer(),
                                    Text(leave.durationText, style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.secondary)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(leave.reason, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                                if (leave.rejectionReason != null) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, size: 14, color: colorScheme.error),
                                        const SizedBox(width: 6),
                                        Expanded(child: Text(leave.rejectionReason!, style: TextStyle(fontSize: 12, color: colorScheme.onErrorContainer))),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
