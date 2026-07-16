import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';

class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key, required this.child});

  final Widget child;

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool _offline = false;
  bool _serverReachable = true;
  StreamSubscription? _connSub;
  Timer? _healthTimer;
  Dio? _healthDio;

  @override
  void initState() {
    super.initState();
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final disconnected = results.every((r) => r == ConnectivityResult.none);
      if (mounted) setState(() => _offline = disconnected);
      if (disconnected) {
        _healthTimer?.cancel();
        _healthTimer = null;
      } else {
        _startHealthCheck();
      }
    });
  }

  void _startHealthCheck() {
    _healthTimer?.cancel();
    _checkServer();
    _healthTimer = Timer.periodic(const Duration(seconds: 15), (_) => _checkServer());
  }

  Future<void> _checkServer() async {
    try {
      _healthDio ??= Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      await _healthDio!.get('/health');
      if (mounted && !_offline) setState(() => _serverReachable = true);
    } catch (_) {
      if (mounted && !_offline) setState(() => _serverReachable = false);
    }
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _healthTimer?.cancel();
    _healthDio?.close(force: true);
    super.dispose();
  }

  String get _message {
    if (_offline) return 'No internet connection';
    if (!_serverReachable) return 'Cannot reach server — check your connection';
    return '';
  }

  IconData get _icon {
    if (_offline) return Icons.wifi_off;
    return Icons.cloud_off;
  }

  Color get _bgColor {
    if (_offline) return Colors.red.shade700;
    return Colors.amber.shade800;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_message.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            color: _bgColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_icon, size: 14, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  _message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
