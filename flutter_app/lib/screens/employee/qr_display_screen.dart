import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/theme.dart';
import '../../models/leave_request.dart';
import '../../utils/date_formatter.dart';
import '../../utils/qr_countdown.dart';
import '../../widgets/custom_widgets.dart';

class QrDisplayScreen extends StatelessWidget {

  const QrDisplayScreen({super.key, required this.leave});
  final LeaveRequest leave;

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
                          clipBehavior: Clip.antiAlias,
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
                                padding:
                                    const EdgeInsets.fromLTRB(20, 16, 16, 16),
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
                                  qrImageUrl: leave.outQrImage,
                                  qrColor: context.primaryBlue,
                                  title: 'Exit Authorized',
                                  subtitle: 'Scan at Main Gate (Exit)',
                                  pulseColor: context.primaryBlue,
                                  date: dateStr,
                                  time: leave.startTime,
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
                                  qrImageUrl: leave.inQrImage,
                                  qrColor: context.success,
                                  title: 'Entry Authorized',
                                  subtitle: 'Scan at Main Gate (Entry)',
                                  pulseColor: context.success,
                                  date: dateStr,
                                  time: leave.endTime,
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
                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}

class _QrPassCard extends StatefulWidget {

  const _QrPassCard({
    required this.label,
    required this.icon,
    required this.headerColor,
    required this.headerTextColor,
    required this.qrData,
    this.qrImageUrl,
    required this.qrColor,
    required this.title,
    required this.subtitle,
    required this.pulseColor,
    required this.date,
    required this.time,
  });
  final String label;
  final IconData icon;
  final Color headerColor;
  final Color headerTextColor;
  final String qrData;
  final String? qrImageUrl;
  final Color qrColor;
  final String title;
  final String subtitle;
  final Color pulseColor;
  final String date;
  final String time;

  @override
  State<_QrPassCard> createState() => _QrPassCardState();
}

class _QrPassCardState extends State<_QrPassCard> with QrCountdownMixin<_QrPassCard> {
  @override
  void initState() {
    super.initState();
    initCountdown(widget.date, widget.time, target: _resolveTarget());
  }

  DateTime? _resolveTarget() {
    try {
      final decoded = utf8.decode(base64Url.decode(base64Url.normalize(widget.qrData)));
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      if (json['timestamp'] != null) {
        return DateTime.tryParse(json['timestamp']);
      }
    } catch (_) {}
    return null;
  }

  @override
  void dispose() {
    disposeCountdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expired = windowState == 'after';
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
              color: widget.headerColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: widget.headerTextColor,
                  ),
                ),
                Icon(widget.icon, color: widget.headerTextColor),
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
                  final displaySize = qrSize - 32;
                  if (widget.qrImageUrl != null) {
                    return Container(
                      width: qrSize,
                      height: qrSize,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: widget.qrColor.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(12),
                        color: context.surfaceContainerLow,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.qrImageUrl!,
                          width: displaySize,
                          height: displaySize,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  }
                  return Container(
                    width: qrSize,
                    height: qrSize,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: widget.qrColor.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(12),
                      color: context.surfaceContainerLow,
                    ),
                    child: RepaintBoundary(
                      child: QrImageView(
                        data: widget.qrData,
                        size: displaySize,
                        eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.circle,
                            color: widget.qrColor),
                        dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.circle,
                            color: widget.qrColor),
                      ),
                    ),
                  );
                }(),
                const SizedBox(height: 12),
                // ── Live Countdown ──
                if (!expired)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.qrColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined,
                            size: 16, color: widget.qrColor),
                        const SizedBox(width: 6),
                        Text(
                          windowState == 'before'
                              ? 'Opens in ${formatCountdown(remainingSeconds)}'
                              : 'Expires in ${formatCountdown(remainingSeconds)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: widget.qrColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (expired)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_off_outlined,
                            size: 16, color: context.error),
                        const SizedBox(width: 6),
                        Text('Expired',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: context.error)),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.qrColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.outline,
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


