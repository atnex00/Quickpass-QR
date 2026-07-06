import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scan_provider.dart';
import 'scan_history_screen.dart';
import 'scan_result_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  MobileScannerController? _controller;
  bool _isProcessing = false;
  bool _torchEnabled = false;
  String? _cameraError;
  bool _showManualEntry = false;
  final _manualCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      torchEnabled: false,
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _manualCtl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    _processQr(barcode!.rawValue!);
  }

  void _processQr(String qrData) {
    _isProcessing = true;
    HapticFeedback.heavyImpact();
    context.read<ScanProvider>().setScanning(false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ScanResultScreen(qrData: qrData)),
    );
  }

  void _submitManual() {
    final text = _manualCtl.text.trim();
    if (text.isEmpty) return;
    _processQr(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_cameraError == null)
            RepaintBoundary(
              child: MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
                errorBuilder: (context, error) {
                  final msg = error.errorDetails?.message ?? error.errorCode.name;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _cameraError = msg);
                  });
                  return _buildCameraError();
                },
              ),
            )
          else
            _buildCameraError(),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  height: 64,
                  color: QuickpassColors.darkPrimary,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: QuickpassColors.darkOnPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.asset('assets/icon/app-icon.png', width: 18, height: 18),
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
                          icon: const Icon(Icons.keyboard),
                          color: QuickpassColors.darkOnPrimary,
                          onPressed: () => setState(() => _showManualEntry = !_showManualEntry),
                        ),
                        IconButton(
                          icon: Icon(_torchEnabled ? Icons.flashlight_on : Icons.flashlight_off),
                          color: QuickpassColors.darkOnPrimary,
                          onPressed: () {
                            setState(() => _torchEnabled = !_torchEnabled);
                            _controller?.toggleTorch();
                          },
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: QuickpassColors.darkOnPrimary),
                          color: QuickpassColors.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (value) async {
                            switch (value) {
                              case 'history':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ScanHistoryScreen()),
                                );
                              case 'logout':
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    title: const Text('Logout'),
                                    content: const Text('Are you sure you want to logout?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        style: FilledButton.styleFrom(backgroundColor: QuickpassColors.error),
                                        child: const Text('Logout'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && context.mounted) {
                                  context.read<AuthProvider>().logout();
                                }
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              enabled: false,
                              child: Consumer<AuthProvider>(
                                builder: (_, auth, __) => Text(
                                  auth.user?.fullName ?? 'Guard',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: QuickpassColors.onSurface,
                                  ),
                                ),
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'history',
                              child: ListTile(
                                leading: Icon(Icons.history, color: QuickpassColors.onSurface),
                                title: Text('Scan History'),
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'logout',
                              child: ListTile(
                                leading: Icon(Icons.logout, color: QuickpassColors.error),
                                title: Text('Logout', style: TextStyle(color: QuickpassColors.error)),
                                contentPadding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: _cameraError != null ? QuickpassColors.error : QuickpassColors.secondary, width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      const Positioned(top: -1, left: -1, child: _CornerBracket(QuickpassColors.secondary)),
                      const Positioned(top: -1, right: -1, child: _CornerBracket(QuickpassColors.secondary)),
                      const Positioned(bottom: -1, left: -1, child: _CornerBracket(QuickpassColors.secondary)),
                      const Positioned(bottom: -1, right: -1, child: _CornerBracket(QuickpassColors.secondary)),
                      if (_cameraError != null)
                        const Icon(Icons.videocam_off, size: 48, color: QuickpassColors.error),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatusIndicator(),
                const Spacer(),
                _buildBottomSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraError() {
    return Container(
      color: Colors.black87,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off, size: 64, color: QuickpassColors.error),
            SizedBox(height: 12),
            Text('Camera unavailable', style: TextStyle(color: Colors.white70, fontSize: 16)),
            SizedBox(height: 4),
            Text('Use the manual entry below to enter QR code', style: TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    Color color;
    String text;
    if (_cameraError != null) {
      color = QuickpassColors.error;
      text = 'Camera error';
    } else if (_isProcessing) {
      color = QuickpassColors.warning;
      text = 'Processing...';
    } else {
      color = QuickpassColors.success;
      text = 'Scanner ready';
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_cameraError == null) ...[
            const Text('Position QR code within the frame', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 4),
            const Text('OUT (Blue) or IN (Green) QR', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
          if (_showManualEntry) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualCtl,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Paste QR data or enter manually',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Container(
                    height: 40,
                    margin: const EdgeInsets.all(4),
                    child: FilledButton(
                      onPressed: _submitManual,
                      child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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

class _CornerBracket extends StatelessWidget {
  final Color color;
  const _CornerBracket(this.color);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _BracketPainter(color),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final Color color;
  _BracketPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, size.height), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
