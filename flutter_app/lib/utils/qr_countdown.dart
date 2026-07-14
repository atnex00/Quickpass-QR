import 'dart:async';

import 'package:flutter/widgets.dart';

import '../services/qr_service.dart';

mixin QrCountdownMixin<T extends StatefulWidget> on State<T> {
  String _windowState = 'during';
  int _remainingSeconds = 0;
  Timer? _timer;

  String get windowState => _windowState;
  int get remainingSeconds => _remainingSeconds;

  void initCountdown(String date, String time) {
    _tick(date, time);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick(date, time));
  }

  void updateCountdown(String date, String time,
      {required String oldDate, required String oldTime}) {
    if (date != oldDate || time != oldTime) {
      _timer?.cancel();
      _tick(date, time);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick(date, time));
    }
  }

  void _tick(String date, String time) {
    final result = QrService.windowSeconds(date, time);
    setState(() {
      _windowState = (result['state'] as String?) ?? 'after';
      _remainingSeconds = (result['seconds'] as int?) ?? 0;
    });
    if (_windowState == 'after') {
      _timer?.cancel();
      _timer = null;
    }
  }

  void disposeCountdown() {
    _timer?.cancel();
  }

  String formatCountdown(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
