import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/leave_request.dart';
import '../../providers/leave_provider.dart';
import '../../widgets/status_badge.dart';
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
            ? const Center(child: CircularProgressIndicator())
            : leaveProv.history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('No leave requests found', style: TextStyle(color: Colors.grey[700], fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(_statusFilter != null ? 'No $_statusFilter requests match your filter' : 'Submit a leave request to get started',
                            style: TextStyle(color: Colors.grey[500], fontSize: 13)),
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
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                    ),
                                    StatusBadge(status: leave.status),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 16, color: QuickpassColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text('${leave.startTime} - ${leave.endTime}'),
                                    const Spacer(),
                                    Text(leave.durationText, style: const TextStyle(fontWeight: FontWeight.w500, color: QuickpassColors.secondary)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(leave.reason, style: const TextStyle(color: QuickpassColors.textSecondary, fontSize: 13)),
                                if (leave.rejectionReason != null) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: QuickpassColors.error.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.info_outline, size: 14, color: QuickpassColors.error),
                                        const SizedBox(width: 6),
                                        Expanded(child: Text(leave.rejectionReason!, style: const TextStyle(fontSize: 12, color: QuickpassColors.error))),
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
