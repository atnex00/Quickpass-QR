import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/leave_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/custom_app_bar.dart';

class RequestLeaveScreen extends StatefulWidget {
  const RequestLeaveScreen({super.key});

  @override
  State<RequestLeaveScreen> createState() => _RequestLeaveScreenState();
}

class _RequestLeaveScreenState extends State<RequestLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  TimeOfDay _startTime = TimeOfDay(hour: DateTime.now().hour, minute: DateTime.now().minute);
  TimeOfDay _endTime = TimeOfDay(hour: DateTime.now().hour + 2, minute: DateTime.now().minute);
  String _reason = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (_startTime.hour > 23) _startTime = const TimeOfDay(hour: 23, minute: 0);
    if (_endTime.hour > 23) _endTime = const TimeOfDay(hour: 23, minute: 59);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        if (isStart) _startTime = picked;
        else _endTime = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final st = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00';
    final et = '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}:00';

    if (st.compareTo(et) >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time'), backgroundColor: QuickpassColors.error),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final today = DateFormatter.dateApi.format(DateTime.now());
    final leaveProv = context.read<LeaveProvider>();
    final result = await leaveProv.submitLeave(
      leaveDate: today,
      startTime: st,
      endTime: et,
      reason: _reason,
    );

    setState(() => _isSubmitting = false);

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave request submitted'), backgroundColor: QuickpassColors.success),
      );
      Navigator.pop(context);
    } else if (leaveProv.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(leaveProv.error!), backgroundColor: QuickpassColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final today = DateTime.now();

    return Scaffold(
      appBar: const QuickpassAppBar(title: 'Request Leave', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Auto-filled info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Employee Information', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const Divider(),
                      _readOnlyField('Employee ID', auth.user?.employeeId ?? ''),
                      _readOnlyField('Full Name', auth.user?.fullName ?? ''),
                      _readOnlyField('Position', auth.user?.position ?? ''),
                      _readOnlyField('Department', auth.user?.departmentName ?? ''),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Date (locked)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: QuickpassColors.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Date', style: TextStyle(fontSize: 12, color: QuickpassColors.textSecondary)),
                          Text(DateFormatter.formatDate(today), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.lock, size: 16, color: QuickpassColors.textSecondary),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Time pickers
              Row(
                children: [
                  Expanded(
                    child: _TimePickerCard(
                      label: 'Start Time (OUT)',
                      time: DateFormatter.formatTimeOfDay(_startTime.hour, _startTime.minute),
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimePickerCard(
                      label: 'End Time (IN)',
                      time: DateFormatter.formatTimeOfDay(_endTime.hour, _endTime.minute),
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Duration
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: QuickpassColors.secondary),
                      const SizedBox(width: 12),
                      const Text('Duration: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        _calculateDuration(),
                        style: const TextStyle(fontWeight: FontWeight.w700, color: QuickpassColors.secondary),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text('Reason for Leave', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _reason,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.description_outlined),
                  hintText: 'Enter your reason for leave...',
                ),
                maxLines: 3,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Reason is required';
                  if (v.trim().length < 5) return 'Reason must be at least 5 characters';
                  return null;
                },
                onChanged: (v) => _reason = v,
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Submit Request'),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _readOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: QuickpassColors.textSecondary, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }

  String _calculateDuration() {
    final startMin = _startTime.hour * 60 + _startTime.minute;
    final endMin = _endTime.hour * 60 + _endTime.minute;
    if (endMin <= startMin) return 'Invalid';
    final diff = endMin - startMin;
    final h = diff ~/ 60;
    final m = diff % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }
}

class _TimePickerCard extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimePickerCard({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: QuickpassColors.textSecondary)),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 18, color: QuickpassColors.primary),
                  const SizedBox(width: 6),
                  Text(time, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
