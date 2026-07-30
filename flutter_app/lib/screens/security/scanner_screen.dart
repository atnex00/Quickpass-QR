import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scan_provider.dart';
import '../shared/settings_screen.dart';
import 'scan_history_screen.dart';
import 'scan_result_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  MobileScannerController? _controller;
  bool _isProcessing = false;
  bool _torchEnabled = false;
  String? _cameraError;
  bool _showManualEntry = false;
  bool _permissionGranted = false;
  bool _permissionChecked = false;
  final _manualCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestCameraPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _controller != null) {
      _controller!.start();
    } else if (state == AppLifecycleState.paused && _controller != null) {
      _controller!.stop();
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status.isGranted) {
      _permissionGranted = true;
      _permissionChecked = true;
      _initScanner();
    } else if (status.isPermanentlyDenied) {
      _cameraError = 'Camera permission permanently denied. '
          'Enable it in app settings.';
      _permissionChecked = true;
      setState(() {});
    } else {
      _cameraError = 'Camera permission denied. '
          'Use manual entry below to scan QR codes.';
      _permissionChecked = true;
      setState(() {});
    }
  }

  void _initScanner() {
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    if (mounted) setState(() {});
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

    Navigator.of(context, rootNavigator: true)
        .push(MaterialPageRoute(
            builder: (_) => ScanResultScreen(qrData: qrData)))
        .then((_) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _showManualEntry = false;
          _manualCtl.clear();
        });
      }
    });
  }

  void _submitManual() {
    final text = _manualCtl.text.trim();
    if (text.isEmpty) return;
    _processQr(text);
  }

  void _openAppSettings() {
    openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_cameraError == null && _permissionGranted)
            RepaintBoundary(
              child: MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
                errorBuilder: (context, error, _) {
                  if (_cameraError == null) {
                    final msg =
                        error.errorDetails?.message ?? error.errorCode.name;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _cameraError = msg);
                    });
                  }
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
                _ScannerAppBar(
                  torchEnabled: _torchEnabled,
                  showManualEntry: _showManualEntry,
                  onToggleManual: () =>
                      setState(() => _showManualEntry = !_showManualEntry),
                  onToggleTorch: () {
                    setState(() => _torchEnabled = !_torchEnabled);
                    _controller?.toggleTorch();
                  },
                ),
                const Spacer(),
                _QrScanFrame(cameraError: _cameraError),
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
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off, size: 64, color: context.error),
            const SizedBox(height: 12),
            const Text('Camera unavailable',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _cameraError ?? 'Use the manual entry below to enter QR code',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
            if (_cameraError?.contains('permanently denied') == true) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _openAppSettings,
                child: const Text('Open Settings'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    Color color;
    String text;
    if (_cameraError != null) {
      color = context.error;
      text = 'Camera error';
    } else if (_isProcessing) {
      color = context.warning;
      text = 'Processing...';
    } else if (!_permissionChecked) {
      color = context.warning;
      text = 'Requesting camera permission...';
    } else {
      color = context.success;
      text = 'Scanner ready';
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }

  Widget _buildBottomSection() {
    return Container(
      width: double.infinity,
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
          if (_cameraError == null && _permissionGranted) ...[
            const Text('Position QR code within the frame',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 4),
            const Text('OUT (Blue) or IN (Green) QR',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
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
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Container(
                    height: 40,
                    margin: const EdgeInsets.all(4),
                    child: FilledButton(
                      onPressed: _submitManual,
                      child: const Text('Submit',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
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

class _ScannerAppBar extends StatelessWidget {

  const _ScannerAppBar({
    required this.torchEnabled,
    required this.showManualEntry,
    required this.onToggleManual,
    required this.onToggleTorch,
  });
  final bool torchEnabled;
  final bool showManualEntry;
  final VoidCallback onToggleManual;
  final VoidCallback onToggleTorch;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white70.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ColorFiltered(
                      colorFilter: ColorFilter.mode(context.onSurface, BlendMode.srcIn),
                      child: Image.asset('assets/icon/app-icon.png',
                          width: 18, height: 18)),
                ),
                const SizedBox(width: 8),
                Text(
                  'Quickpass',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.keyboard),
                  color: Colors.white,
                  onPressed: onToggleManual,
                ),
                IconButton(
                  icon: Icon(torchEnabled
                      ? Icons.flashlight_on
                      : Icons.flashlight_off),
                  color: Colors.white,
                  onPressed: onToggleTorch,
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.white),
                  color: context.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) async {
                    switch (value) {
                      case 'settings':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()),
                        );
                        break;
                      case 'history':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ScanHistoryScreen()),
                        );
                        break;
                      case 'logout':
                        final errorColor = context.error;
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            title: const Text('Logout'),
                            content:
                                const Text('Are you sure you want to logout?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel')),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: FilledButton.styleFrom(
                                    backgroundColor: errorColor),
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
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: context.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'settings',
                      child: ListTile(
                        leading: Icon(Icons.settings, color: context.onSurface),
                        title: const Text('Settings'),
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'history',
                      child: ListTile(
                        leading: Icon(Icons.history, color: context.onSurface),
                        title: const Text('Scan History'),
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'logout',
                      child: ListTile(
                        leading: Icon(Icons.logout, color: context.error),
                        title: Text('Logout',
                            style: TextStyle(color: context.error)),
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QrScanFrame extends StatelessWidget {
  const _QrScanFrame({this.cameraError});
  final String? cameraError;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final frameSize = (constraints.maxWidth).clamp(200.0, 260.0);
        return SizedBox(
          width: frameSize,
          height: frameSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: cameraError != null
                          ? context.error
                          : context.secondary,
                      width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              Positioned(
                  top: -1, left: -1, child: _CornerBracket(context.secondary)),
              Positioned(
                  top: -1, right: -1, child: _CornerBracket(context.secondary)),
              Positioned(
                  bottom: -1,
                  left: -1,
                  child: _CornerBracket(context.secondary)),
              Positioned(
                  bottom: -1,
                  right: -1,
                  child: _CornerBracket(context.secondary)),
              if (cameraError != null)
                Icon(Icons.videocam_off, size: 48, color: context.error),
            ],
          ),
        );
      },
    );
  }
}

class _CornerBracket extends StatelessWidget {
  const _CornerBracket(this.color);
  final Color color;

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
  _BracketPainter(this.color);
  final Color color;

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
