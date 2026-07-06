import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../config/theme.dart';
import '../services/qr_service.dart';

class QrCodeWidget extends StatefulWidget {
  final String qrData;
  final String label;
  final Color color;
  final String date;
  final String time;
  final DateTime? priorScanTime;
  final String? employeeName;
  final String? employeePosition;
  final bool isOut;

  const QrCodeWidget({
    super.key,
    required this.qrData,
    required this.label,
    required this.color,
    required this.date,
    required this.time,
    this.priorScanTime,
    this.employeeName,
    this.employeePosition,
    required this.isOut,
  });

  @override
  State<QrCodeWidget> createState() => _QrCodeWidgetState();
}

class _QrCodeWidgetState extends State<QrCodeWidget> {
  String _windowState = 'during';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final result = QrService.windowSeconds(widget.date, widget.time);
    setState(() {
      _windowState = result['state'] as String;
    });
    if (_windowState == 'after') {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _expired => widget.isOut && _windowState == 'after';
  bool get _used => widget.priorScanTime != null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.color.withValues(alpha: 0.3), width: 2),
        color: widget.color.withValues(alpha: 0.03),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.label,
                  style: TextStyle(color: widget.color, fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 1.2),
                ),
              ),
              if (_used)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: QuickpassColors.neutralGray),
                    SizedBox(width: 4),
                    Text('Scanned', style: TextStyle(fontSize: 11, color: QuickpassColors.neutralGray)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),

          if (_used)
            const Column(
              children: [
                Icon(Icons.check_circle, size: 48, color: QuickpassColors.neutralGray),
                SizedBox(height: 8),
                Text('Already Scanned', style: TextStyle(color: QuickpassColors.neutralGray, fontSize: 16)),
              ],
            )
          else if (_expired)
            Column(
              children: [
                const Icon(Icons.timer_off, size: 48, color: QuickpassColors.neutralGray),
                const SizedBox(height: 8),
                Text('QR Code Expired', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16)),
                const SizedBox(height: 4),
                const Text('The 15-minute validity window has passed', style: TextStyle(color: QuickpassColors.neutralGray, fontSize: 12)),
              ],
            )
          else ...[
            RepaintBoundary(
              child: QrImageView(
                data: widget.qrData,
                version: QrVersions.auto,
                size: 450,
                backgroundColor: Colors.white,
                eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.circle, color: widget.color),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Colors.black),
              ),
            ),
            const SizedBox(height: 16),
            _TimerRow(color: widget.color, date: widget.date, time: widget.time, isOut: widget.isOut),
          ],

          if (widget.employeeName != null || widget.employeePosition != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  CircleAvatar(radius: 16, backgroundColor: widget.color, child: Text(
                    (widget.employeeName ?? '?')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                  )),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.employeeName != null)
                          Text(widget.employeeName!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: QuickpassColors.onSurface)),
                        if (widget.employeePosition != null)
                          Text(widget.employeePosition!, style: const TextStyle(color: QuickpassColors.neutralGray, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimerRow extends StatefulWidget {
  final Color color;
  final String date;
  final String time;
  final bool isOut;
  const _TimerRow({required this.color, required this.date, required this.time, required this.isOut});

  @override
  State<_TimerRow> createState() => _TimerRowState();
}

class _TimerRowState extends State<_TimerRow> {
  String _windowState = 'during';
  int _remainingSeconds = 900;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final result = QrService.windowSeconds(widget.date, widget.time);
    if (!mounted) return;
    setState(() {
      _windowState = result['state'] as String;
      _remainingSeconds = result['seconds'] as int;
    });
    if (_windowState == 'after') {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    const used = false;
    final expired = widget.isOut && _windowState == 'after';
    if (used || expired) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, size: 18, color: widget.color),
          const SizedBox(width: 6),
          widget.isOut
              ? Text(
                  '${_windowState == 'before' ? 'Opens in ' : 'Expires in '}${_fmt(_remainingSeconds)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'monospace', color: widget.color),
                )
              : Text('Ready to scan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: widget.color)),
        ],
      ),
    );
  }
}
