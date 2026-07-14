import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../config/theme.dart';
import '../utils/qr_countdown.dart';

class QrCodeWidget extends StatefulWidget {

  const QrCodeWidget({
    super.key,
    required this.qrData,
    this.qrImageUrl,
    required this.label,
    required this.color,
    required this.date,
    required this.time,
    this.priorScanTime,
    this.employeeName,
    this.employeePosition,
    required this.isOut,
  });
  final String qrData;
  final String? qrImageUrl;
  final String label;
  final Color color;
  final String date;
  final String time;
  final DateTime? priorScanTime;
  final String? employeeName;
  final String? employeePosition;
  final bool isOut;

  @override
  State<QrCodeWidget> createState() => _QrCodeWidgetState();
}

class _QrCodeWidgetState extends State<QrCodeWidget> with QrCountdownMixin<QrCodeWidget> {
  @override
  void initState() {
    super.initState();
    initCountdown(widget.date, widget.time);
  }

  @override
  void didUpdateWidget(covariant QrCodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateCountdown(widget.date, widget.time,
        oldDate: oldWidget.date, oldTime: oldWidget.time);
  }

  @override
  void dispose() {
    disposeCountdown();
    super.dispose();
  }

  bool get _expired => widget.isOut && windowState == 'after';
  bool get _used => widget.priorScanTime != null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: widget.color.withValues(alpha: 0.3), width: 2),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.label,
                  style: TextStyle(
                      color: widget.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 1.2),
                ),
              ),
              if (_used)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        size: 14, color: context.neutralGray),
                    const SizedBox(width: 4),
                    Text('Scanned',
                        style: TextStyle(
                            fontSize: 11, color: context.neutralGray)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (_used)
            Column(
              children: [
                Icon(Icons.check_circle, size: 48, color: context.neutralGray),
                const SizedBox(height: 8),
                Text('Already Scanned',
                    style: TextStyle(color: context.neutralGray, fontSize: 16)),
              ],
            )
          else if (_expired)
            Column(
              children: [
                Icon(Icons.timer_off, size: 48, color: context.neutralGray),
                const SizedBox(height: 8),
                Text('QR Code Expired',
                    style: TextStyle(
                        color: colorScheme.onSurfaceVariant, fontSize: 16)),
                const SizedBox(height: 4),
                Text('The 15-minute validity window has passed',
                    style: TextStyle(color: context.neutralGray, fontSize: 12)),
              ],
            )
          else ...[
            if (widget.qrImageUrl != null)
              Image.network(
                widget.qrImageUrl!,
                width: 450,
                height: 450,
                fit: BoxFit.contain,
              )
            else
              RepaintBoundary(
                child: QrImageView(
                  data: widget.qrData,
                  size: 450,
                  backgroundColor: context.surface,
                  eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.circle, color: widget.color),
                  dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.circle,
                      color: Colors.black),
                ),
              ),
            const SizedBox(height: 16),
            _TimerRow(
                color: widget.color,
                isOut: widget.isOut,
                windowState: windowState,
                remainingSeconds: remainingSeconds),
          ],
          if (widget.employeeName != null ||
              widget.employeePosition != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  CircleAvatar(
                      radius: 16,
                      backgroundColor: widget.color,
                      child: Text(
                        (widget.employeeName ?? '?')[0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      )),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.employeeName != null)
                          Text(widget.employeeName!,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: context.onSurface)),
                        if (widget.employeePosition != null)
                          Text(widget.employeePosition!,
                              style: TextStyle(
                                  color: context.neutralGray, fontSize: 12)),
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

class _TimerRow extends StatelessWidget {

  const _TimerRow({
    required this.color,
    required this.isOut,
    required this.windowState,
    required this.remainingSeconds,
  });
  final Color color;
  final bool isOut;
  final String windowState;
  final int remainingSeconds;

  String _fmt(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final expired = isOut && windowState == 'after';
    if (expired) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, size: 18, color: color),
          const SizedBox(width: 6),
          if (isOut) Text(
                  '${windowState == 'before' ? 'Opens in ' : 'Expires in '}${_fmt(remainingSeconds)}',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                      color: color),
                ) else Text('Ready to scan',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color)),
        ],
      ),
    );
  }
}
