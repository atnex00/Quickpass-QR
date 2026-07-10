import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/theme.dart';
import '../../models/leave_request.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/custom_widgets.dart';

class QrDisplayScreen extends StatelessWidget {
  final LeaveRequest leave;

  const QrDisplayScreen({super.key, required this.leave});

  String _qrToken(String? qrData) {
    if (qrData == null) return '---';
    return qrData.length > 8
        ? qrData.substring(qrData.length - 8).toUpperCase()
        : qrData.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormatter.formatDateApi(leave.leaveDate);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ── Main Content ──
            Hero(
              tag: ValueKey('qr-leave-${leave.leaveId}'),
              child: CustomScrollView(
                slivers: [
                  // ── Electric Yellow App Bar ──
                  SliverAppBar(
                    pinned: true,
                    toolbarHeight: 64,
                    automaticallyImplyLeading: false,
                    flexibleSpace: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Material(
                                type: MaterialType.transparency,
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  color: context.onPrimary,
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Quickpass',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: context.onPrimary,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(Icons.notifications_outlined,
                                    color: context.onPrimary),
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
                            color: context.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.outlineVariant),
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
                                  decoration: BoxDecoration(
                                    color: context.success,
                                    borderRadius: const BorderRadius.only(
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
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: context.success
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          999),
                                                ),
                                                child: Text(
                                                  'Approved',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: context.success,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                leave.reason,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w600,
                                                  color: context.onSurface,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          'ID: #${leave.leaveId}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: context.outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        children: [
                                          Icon(Icons.calendar_today,
                                              size: 20,
                                              color: context.primaryBlue),
                                          const SizedBox(width: 8),
                                          Text(
                                            dateStr,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: context.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(width: 24),
                                          Icon(Icons.schedule,
                                              size: 20,
                                              color: context.primaryBlue),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${leave.startTime} - ${leave.endTime}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: context.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
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
                              color: context.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.outlineVariant),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.qr_code,
                                    size: 64, color: context.outlineVariant),
                                const SizedBox(height: 12),
                                Text('QR codes are not available yet',
                                    style: TextStyle(
                                        color: context.onSurfaceVariant)),
                                const SizedBox(height: 4),
                                Text('Approved leaves will show QR codes here',
                                    style:
                                        TextStyle(color: context.neutralGray)),
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
                                  headerColor: context.primary,
                                  headerTextColor: context.onPrimary,
                                  qrData: leave.outQrCode!,
                                  qrColor: context.primaryBlue,
                                  scanLineColor:
                                      context.secondary.withValues(alpha: 0.4),
                                  title: 'Exit Authorized',
                                  subtitle: 'Scan at Main Gate (Exit)',
                                  token: _qrToken(leave.outQrCode),
                                  pulseColor: context.primaryBlue,
                                ),
                              const SizedBox(height: 16),
                              // ── IN PASS ──
                              if (leave.inQrCode != null)
                                _QrPassCard(
                                  label: 'In Pass',
                                  icon: Icons.login,
                                  headerColor:
                                      context.success.withValues(alpha: 0.1),
                                  headerTextColor: context.success,
                                  qrData: leave.inQrCode!,
                                  qrColor: context.success,
                                  scanLineColor:
                                      context.success.withValues(alpha: 0.4),
                                  title: 'Entry Authorized',
                                  subtitle: 'Scan at Main Gate (Entry)',
                                  token: _qrToken(leave.inQrCode),
                                  pulseColor: context.success,
                                ),
                            ],
                          ),
                        const SizedBox(height: 16),

                        // ── Pass Guidelines ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 18, color: context.onSurface),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Pass Guidelines',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.01,
                                      color: context.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const GuidelineItem(
                                  text:
                                      'Ensure screen brightness is set to maximum.'),
                              const SizedBox(height: 8),
                              const GuidelineItem(
                                  text:
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
            ),

            // ── Bottom Timer Footer ──
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BottomTimer(
                  leaveDate: leave.leaveDate,
                  startTime: leave.startTime,
                  endTime: leave.endTime,
                  isOut: true),
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
        color: context.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outlineVariant),
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
                () {
                  final qrSize = (MediaQuery.of(context).size.width - 80)
                      .clamp(180.0, 240.0);
                  return Container(
                    width: qrSize,
                    height: qrSize,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: qrColor.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(12),
                      color: context.surfaceContainerLow,
                    ),
                    child: Stack(
                      children: [
                        RepaintBoundary(
                          child: QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: qrSize - 32,
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
                          child: _ScanLine(
                              containerSize: qrSize, color: scanLineColor),
                        ),
                      ],
                    ),
                  );
                }(),
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.outline,
                  ),
                ),
              ],
            ),
          ),

          // Token bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.surfaceContainerLow,
              border: Border(top: BorderSide(color: context.outlineVariant)),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.05,
                    color: context.onSurfaceVariant,
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
  final bool isOut;
  const _BottomTimer(
      {required this.leaveDate,
      required this.startTime,
      required this.endTime,
      this.isOut = true});

  @override
  State<_BottomTimer> createState() => _BottomTimerState();
}

class _BottomTimerState extends State<_BottomTimer>
    with WidgetsBindingObserver {
  late Timer _timer;
  late DateTime _windowEnd;
  int _remainingSeconds = 0;
  int _totalSeconds = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _windowEnd = _computeWindowEnd();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  DateTime _computeWindowEnd() {
    final dateStr = DateFormatter.formatDateApi(widget.leaveDate);
    final timeStr =
        (widget.isOut ? widget.startTime : widget.endTime).padLeft(5, '0');
    final hhmm = timeStr.split(':').take(2).join(':');
    final start = DateTime.parse('${dateStr}T$hhmm:00');
    return start.add(const Duration(minutes: 15));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _timer.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _timer.cancel();
      _tick();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  void _tick() {
    final now = DateTime.now();
    final remaining = _windowEnd.difference(now).inSeconds;
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
    WidgetsBinding.instance.removeObserver(this);
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
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(top: BorderSide(color: context.outlineVariant)),
      ),
      child: Stack(
        children: [
          Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: context.surfaceContainer,
                color: context.error,
                minHeight: 4,
              )),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('VALID FOR',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                        color: context.outline)),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer, size: 18, color: context.error),
                    const SizedBox(width: 6),
                    Text(_fmt(_remainingSeconds),
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: context.error)),
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
  final double containerSize;
  final Color color;
  const _ScanLine({required this.containerSize, required this.color});

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
                top: _animation.value * (widget.containerSize - 2),
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
