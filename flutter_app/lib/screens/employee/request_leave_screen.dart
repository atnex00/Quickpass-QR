import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  DateTime _leaveDate = DateTime.now();
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _leaveDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _leaveDate = picked);
    }
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
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final dateStr = DateFormatter.dateApi.format(_leaveDate);
    final leaveProv = context.read<LeaveProvider>();
    final result = await leaveProv.submitLeave(
      leaveDate: dateStr,
      startTime: st,
      endTime: et,
      reason: _reason,
    );

    setState(() => _isSubmitting = false);

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave request submitted')),
      );
      Navigator.pop(context);
    } else if (leaveProv.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(leaveProv.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: const QuickpassAppBar(title: 'Request Leave', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Employee Information', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colorScheme.onSurface)),
                      const Divider(),
                      _readOnlyField('Employee ID', auth.user?.employeeId ?? '', colorScheme),
                      _readOnlyField('Full Name', auth.user?.fullName ?? '', colorScheme),
                      _readOnlyField('Position', auth.user?.position ?? '', colorScheme),
                      _readOnlyField('Department', auth.user?.departmentName ?? '', colorScheme),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: colorScheme.primary, size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                            Text(DateFormatter.formatDate(_leaveDate), style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                          ],
                        ),
                        const Spacer(),
                        Icon(Icons.edit_calendar, size: 16, color: colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: colorScheme.secondary),
                      const SizedBox(width: 12),
                      Text('Duration: ', style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                      Text(
                        _calculateDuration(),
                        style: TextStyle(fontWeight: FontWeight.w700, color: colorScheme.secondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Reason for Leave', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
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
                child: FilledButton(
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

  Widget _readOnlyField(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: colorScheme.onSurface))),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.access_time, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(time, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
