import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../../utils/date_formatter.dart';
import '../../utils/validators.dart';

class RequestLeaveScreen extends StatefulWidget {
  const RequestLeaveScreen({super.key});

  @override
  State<RequestLeaveScreen> createState() => _RequestLeaveScreenState();
}

class _RequestLeaveScreenState extends State<RequestLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _leaveDate = DateTime.now();
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String _reason = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _startTime = TimeOfDay.fromDateTime(DateTime.now());
    _endTime =
        TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 2)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _leaveDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _leaveDate = picked);
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    final st =
        '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00';
    final et =
        '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}:00';

    final timeError = Validators.timeRange(st, et);
    if (timeError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(timeError)),
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

    if (mounted) setState(() => _isSubmitting = false);

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
    final user = context.select((AuthProvider a) => a.user);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              toolbarHeight: 64,
              automaticallyImplyLeading: false,
              flexibleSpace: SizedBox(
                height: 64,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        color: context.onPrimary,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Request Leave',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: context.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Employee Information',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: context.onSurface)),
                              Divider(color: context.outlineVariant),
                              _ReadOnlyField(
                                  label: 'Employee ID',
                                  value: user?.employeeId ?? ''),
                              _ReadOnlyField(
                                  label: 'Full Name',
                                  value: user?.fullName ?? ''),
                              _ReadOnlyField(
                                  label: 'Position',
                                  value: user?.position ?? ''),
                              _ReadOnlyField(
                                  label: 'Department',
                                  value: user?.departmentName ?? ''),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.outlineVariant),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    color: context.primaryBlue, size: 20),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Date',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: context.neutralGray)),
                                    Text(DateFormatter.formatDate(_leaveDate),
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: context.onSurface)),
                                  ],
                                ),
                                const Spacer(),
                                Icon(Icons.edit_calendar,
                                    size: 16, color: context.primaryBlue),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _TimePickerCard(
                                label: 'Start Time (OUT)',
                                time: DateFormatter.formatTimeOfDay(
                                    _startTime.hour, _startTime.minute),
                                onTap: () => _pickTime(isStart: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TimePickerCard(
                                label: 'End Time (IN)',
                                time: DateFormatter.formatTimeOfDay(
                                    _endTime.hour, _endTime.minute),
                                onTap: () => _pickTime(isStart: false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.outlineVariant),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, color: context.secondary),
                              const SizedBox(width: 12),
                              Text('Duration: ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: context.onSurface)),
                              Text(
                                _calculateDuration(),
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: context.secondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Reason for Leave',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.onSurface)),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: _reason,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.description_outlined),
                            hintText: 'Enter your reason for leave...',
                          ),
                          maxLines: 3,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Reason is required';
                            }
                            if (v.trim().length < 5) {
                              return 'Reason must be at least 5 characters';
                            }
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
                            style: FilledButton.styleFrom(
                              backgroundColor: context.primary,
                              foregroundColor: context.onPrimary,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5, color: Colors.white))
                                : const Text('Submit Request'),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
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

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 110,
              child: Text(label,
                  style: TextStyle(color: context.neutralGray, fontSize: 13))),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: context.onSurface))),
        ],
      ),
    );
  }
}

class _TimePickerCard extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimePickerCard(
      {required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: context.neutralGray)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.access_time, size: 18, color: context.primaryBlue),
                  const SizedBox(width: 6),
                  Text(time,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: context.onSurface)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
