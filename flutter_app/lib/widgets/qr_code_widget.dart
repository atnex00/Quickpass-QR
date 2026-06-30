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
  int _remainingSeconds = 900;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  void _updateRemaining() {
    setState(() {
      final result = QrService.windowSeconds(widget.date, widget.time);
      _windowState = result['state'] as String;
      _remainingSeconds = result['seconds'] as int;
    });
    if (_windowState == 'after' && _timer != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _isExpired => widget.isOut && _windowState == 'after';
  bool get _isUsed => widget.priorScanTime != null;
  bool get _showQr => !_isUsed && (widget.isOut ? !_isExpired : true);

  String _formatTime(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: widget.color.withValues(alpha: 0.3), width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.color.withValues(alpha: 0.05),
              Colors.white,
            ],
          ),
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
                    style: TextStyle(
                      color: widget.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                if (_isUsed)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text('Scanned', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 20),

            if (_isUsed)
              Column(
                children: [
                  Icon(Icons.check_circle, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('Already Scanned', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              )
            else if (_isExpired)
              Column(
                children: [
                  Icon(Icons.timer_off, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('QR Code Expired', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('The 15-minute validity window has passed',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              )
            else if (widget.priorScanTime == null && !widget.isOut && _remainingSeconds <= -86400)
              const SizedBox.shrink()
            else ...[
              // QR Code with embedded logo overlay
              Stack(
                alignment: Alignment.center,
                children: [
                  QrImageView(
                    data: widget.qrData,
                    version: QrVersions.auto,
                    size: 450,
                    backgroundColor: Colors.white,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.roundedOuter,
                      color: widget.color,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.circle,
                      color: Colors.black,
                    ),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
                      ],
                    ),
                    child: Icon(Icons.qr_code, size: 30, color: widget.color),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Timer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.isOut && _windowState == 'before'
                      ? Colors.blue.withValues(alpha: 0.1)
                      : widget.isOut
                          ? (_remainingSeconds > 300
                              ? QuickpassColors.success.withValues(alpha: 0.1)
                              : QuickpassColors.warning.withValues(alpha: 0.1))
                          : QuickpassColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer,
                      size: 18,
                      color: widget.isOut && _windowState == 'before'
                          ? Colors.blue
                          : widget.isOut
                              ? (_remainingSeconds > 300 ? QuickpassColors.success : QuickpassColors.warning)
                              : QuickpassColors.success,
                    ),
                    const SizedBox(width: 6),
                    widget.isOut
                        ? Text(
                            '${_windowState == 'before' ? "Opens in " : "Expires in "}${_formatTime(_remainingSeconds)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              color: _windowState == 'before'
                                  ? Colors.blue
                                  : _remainingSeconds > 300
                                      ? QuickpassColors.success
                                      : QuickpassColors.warning,
                            ),
                          )
                        : Text(
                            'Ready to scan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: QuickpassColors.success,
                            ),
                          ),
                  ],
                ),
              ),
            ],

            // Employee info footer
            if (widget.employeeName != null || widget.employeePosition != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: widget.color,
                      child: Text(
                        (widget.employeeName ?? '?')[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.employeeName != null)
                            Text(widget.employeeName!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          if (widget.employeePosition != null)
                            Text(widget.employeePosition!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
