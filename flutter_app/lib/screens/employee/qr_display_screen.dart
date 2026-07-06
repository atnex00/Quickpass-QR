import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/theme.dart';
import '../../models/leave_request.dart';

class QrDisplayScreen extends StatelessWidget {
  final LeaveRequest leave;

  const QrDisplayScreen({super.key, required this.leave});

  String _qrToken(String? qrData) {
    if (qrData == null) return '---';
    return qrData.length > 8
        ? qrData.substring(qrData.length - 8).toUpperCase()
        : qrData.toUpperCase();
  }

  Widget _guidelineItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('\u2022',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: QuickpassColors.primary)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 14, color: QuickpassColors.onSurfaceVariant))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = leave.leaveDate.toIso8601String().split('T').first;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ── Main Content ──
            CustomScrollView(
              slivers: [
                // ── Electric Yellow App Bar ──
                SliverAppBar(
                  pinned: true,
                  toolbarHeight: 64,
                  backgroundColor: QuickpassColors.darkPrimary,
                  foregroundColor: QuickpassColors.darkOnPrimary,
                  automaticallyImplyLeading: false,
                  flexibleSpace: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          color: QuickpassColors.darkOnPrimary,
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Quickpass',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: QuickpassColors.darkOnPrimary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined,
                              color: QuickpassColors.darkOnPrimary),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text('No new notifications'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Body ──
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Leave Details ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: QuickpassColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: QuickpassColors.outlineVariant),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0D000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 4,
                                decoration: const BoxDecoration(
                                  color: QuickpassColors.success,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: QuickpassColors.success
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: const Text(
                                              'Approved',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: QuickpassColors.success,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            leave.reason,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                              color: QuickpassColors.onSurface,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'ID: #${leave.leaveId}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: QuickpassColors.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 20,
                                          color: QuickpassColors.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        dateStr,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color:
                                              QuickpassColors.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      const Icon(Icons.schedule,
                                          size: 20,
                                          color: QuickpassColors.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${leave.startTime} - ${leave.endTime}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color:
                                              QuickpassColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── QR Codes Grid ──
                      if (!leave.hasQrCodes)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: QuickpassColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: QuickpassColors.outlineVariant),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.qr_code,
                                  size: 64,
                                  color: QuickpassColors.outlineVariant),
                              SizedBox(height: 12),
                              Text('QR codes are not available yet',
                                  style: TextStyle(
                                      color: QuickpassColors.onSurfaceVariant)),
                              SizedBox(height: 4),
                              Text('Approved leaves will show QR codes here',
                                  style: TextStyle(
                                      color: QuickpassColors.neutralGray)),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: [
                            // ── OUT PASS ──
                            if (leave.outQrCode != null)
                              _QrPassCard(
                                label: 'Out Pass',
                                icon: Icons.logout,
                                headerColor: QuickpassColors.darkPrimary,
                                headerTextColor: QuickpassColors.darkOnPrimary,
                                qrData: leave.outQrCode!,
                                qrColor: QuickpassColors.primary,
                                scanLineColor: QuickpassColors.secondary
                                    .withValues(alpha: 0.4),
                                title: 'Exit Authorized',
                                subtitle: 'Scan at Main Gate (Exit)',
                                token: _qrToken(leave.outQrCode),
                                pulseColor: QuickpassColors.primary,
                              ),
                            const SizedBox(height: 16),
                            // ── IN PASS ──
                            if (leave.inQrCode != null)
                              _QrPassCard(
                                label: 'In Pass',
                                icon: Icons.login,
                                headerColor: QuickpassColors.success
                                    .withValues(alpha: 0.1),
                                headerTextColor: QuickpassColors.success,
                                qrData: leave.inQrCode!,
                                qrColor: QuickpassColors.success,
                                scanLineColor: QuickpassColors.success
                                    .withValues(alpha: 0.4),
                                title: 'Entry Authorized',
                                subtitle: 'Scan at Main Gate (Entry)',
                                token: _qrToken(leave.inQrCode),
                                pulseColor: QuickpassColors.success,
                              ),
                          ],
                        ),
                      const SizedBox(height: 16),

                      // ── Pass Guidelines ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: QuickpassColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: QuickpassColors.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline,
                                    size: 18, color: QuickpassColors.onSurface),
                                SizedBox(width: 8),
                                Text(
                                  'Pass Guidelines',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.01,
                                    color: QuickpassColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _guidelineItem(
                                'Ensure screen brightness is set to maximum.'),
                            const SizedBox(height: 8),
                            _guidelineItem(
                                'QR codes refresh every 60 seconds for security.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),

            // ── Bottom Timer Footer ──
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BottomTimer(
                  leaveDate: leave.leaveDate,
                  startTime: leave.startTime,
                  endTime: leave.endTime),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrPassCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color headerColor;
  final Color headerTextColor;
  final String qrData;
  final Color qrColor;
  final Color scanLineColor;
  final String title;
  final String subtitle;
  final String token;
  final Color pulseColor;

  const _QrPassCard({
    required this.label,
    required this.icon,
    required this.headerColor,
    required this.headerTextColor,
    required this.qrData,
    required this.qrColor,
    required this.scanLineColor,
    required this.title,
    required this.subtitle,
    required this.token,
    required this.pulseColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: QuickpassColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QuickpassColors.outlineVariant),
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: headerTextColor,
                  ),
                ),
                Icon(icon, color: headerTextColor),
              ],
            ),
          ),

          // QR Code
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 240,
                  height: 240,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: qrColor.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                    color: QuickpassColors.surfaceContainerLow,
                  ),
                  child: Stack(
                    children: [
                      RepaintBoundary(
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 208,
                          backgroundColor: Colors.transparent,
                          eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.circle, color: qrColor),
                          dataModuleStyle: QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.circle,
                              color: qrColor),
                        ),
                      ),
                      // Scanning line animation
                      IgnorePointer(
                        child: _ScanLine(color: scanLineColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: qrColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: QuickpassColors.outline,
                  ),
                ),
              ],
            ),
          ),

          // Token bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: QuickpassColors.surfaceContainerLow,
              border: Border(
                  top: BorderSide(color: QuickpassColors.outlineVariant)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: pulseColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'TOKEN: $token',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.05,
                    color: QuickpassColors.onSurfaceVariant,
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

class _BottomTimer extends StatefulWidget {
  final DateTime leaveDate;
  final String startTime;
  final String endTime;
  const _BottomTimer(
      {required this.leaveDate,
      required this.startTime,
      required this.endTime});

  @override
  State<_BottomTimer> createState() => _BottomTimerState();
}

class _BottomTimerState extends State<_BottomTimer> {
  late Timer _timer;
  int _remainingSeconds = 0;
  int _totalSeconds = 1;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final dateStr = widget.leaveDate.toIso8601String().split('T').first;
    final timeStr = widget.startTime.padLeft(5, '0');
    final hhmm = timeStr.split(':').take(2).join(':');
    final start = DateTime.parse('${dateStr}T$hhmm:00');
    final windowEnd = start.add(const Duration(minutes: 15));
    final now = DateTime.now();
    final remaining = windowEnd.difference(now).inSeconds;
    final total = const Duration(minutes: 15).inSeconds;
    if (!mounted) return;
    setState(() {
      _remainingSeconds = remaining.clamp(0, total);
      _totalSeconds = total;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _fmt(int secs) {
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 0.0;
    return Container(
      height: 88,
      decoration: const BoxDecoration(
        color: QuickpassColors.surface,
        border: Border(top: BorderSide(color: QuickpassColors.outlineVariant)),
      ),
      child: Stack(
        children: [
          Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: QuickpassColors.surfaceContainer,
                color: QuickpassColors.error,
                minHeight: 4,
              )),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('VALID FOR',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                        color: QuickpassColors.outline)),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer,
                        size: 18, color: QuickpassColors.error),
                    const SizedBox(width: 6),
                    Text(_fmt(_remainingSeconds),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: QuickpassColors.error)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanLine extends StatefulWidget {
  final Color color;
  const _ScanLine({required this.color});

  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned(
                top: _animation.value * (240 - 2),
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      widget.color.withValues(alpha: 0),
                      widget.color,
                      widget.color.withValues(alpha: 0),
                    ]),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
