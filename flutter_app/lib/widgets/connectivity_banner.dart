import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/theme.dart';

class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key, required this.child});

  final Widget child;

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  bool _offline = false;
  bool _serverReachable = true;
  bool _expanded = true;
  int _healthRetryCount = 0;
  StreamSubscription? _connSub;
  Timer? _healthTimer;
  Timer? _collapseTimer;
  Dio? _healthDio;
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final disconnected = results.every((r) => r == ConnectivityResult.none);
      if (mounted) {
        setState(() {
          _offline = disconnected;
          _expanded = true;
        });
      }
      if (disconnected) {
        _healthTimer?.cancel();
        _healthTimer = null;
        _collapseTimer?.cancel();
        _collapseTimer = Timer(const Duration(seconds: 4), () {
          if (mounted && _offline) {
            setState(() => _expanded = false);
          }
        });
      } else {
        _startHealthCheck();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _slideController.forward();
    });
  }

  void _startHealthCheck() {
    _healthTimer?.cancel();
    _healthRetryCount = 0;
    _checkServer();
  }

  Future<void> _checkServer() async {
    try {
      _healthDio ??= Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      await _healthDio!.get('/health');
      if (mounted && !_offline) {
        setState(() {
          _serverReachable = true;
          _expanded = false;
        });
      }
      _healthTimer?.cancel();
      _healthTimer = null;
    } catch (_) {
      if (mounted && !_offline) {
        setState(() {
          _serverReachable = false;
          _expanded = true;
        });
      }
      _collapseTimer?.cancel();
      _collapseTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && !_serverReachable) {
          setState(() => _expanded = false);
        }
      });
      _healthTimer?.cancel();
      final delay = _nextHealthDelay();
      _healthTimer = Timer(delay, _checkServer);
    }
  }

  Duration _nextHealthDelay() {
    const delays = [15, 30, 60, 120, 240, 300];
    final index = _healthRetryCount.clamp(0, delays.length - 1);
    _healthRetryCount++;
    return Duration(seconds: delays[index]);
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _healthTimer?.cancel();
    _collapseTimer?.cancel();
    _healthDio?.close(force: true);
    _slideController.dispose();
    super.dispose();
  }

  String get _message {
    if (_offline) return 'No internet connection';
    if (!_serverReachable) return 'Cannot reach server';
    return '';
  }

  IconData get _icon {
    if (_offline) return Icons.wifi_off;
    return Icons.cloud_off;
  }

  @override
  Widget build(BuildContext context) {
    final showBanner = _message.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
        widget.child,
        if (showBanner)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: SlideTransition(
              position: _slideAnimation,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: _buildChip(context),
              ),
            ),
          ),
      ],
      ),
    );

  }

  Widget _buildChip(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: _expanded ? 14 : 10,
          vertical: _expanded ? 10 : 8,
        ),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: context.warning.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: context.onSurface.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _expanded ? 28 : 22,
              height: _expanded ? 28 : 22,
              decoration: BoxDecoration(
                color: context.warning.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _icon,
                size: _expanded ? 16 : 13,
                color: context.warning,
              ),
            ),
            if (_expanded) ...[
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  _message,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.expand_less,
                size: 14,
                color: context.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
