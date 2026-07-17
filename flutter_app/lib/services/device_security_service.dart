import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

import 'api_service.dart';

class DeviceSecurityService {
  static Future<bool> isDeviceCompromised() async {
    try {
      return await FlutterJailbreakDetection.jailbroken;
    } catch (_) {
      return false;
    }
  }

  static Future<void> handleCompromisedDevice() async {
    await ApiService().clearLocalAuth();
  }
}

class BlockedApp extends StatelessWidget {
  const BlockedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PopScope(
        canPop: false,
        child: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 24),
                  const Text(
                    'Security Blocked',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Quickpass cannot run on a rooted or compromised '
                    'device.\n\nContact IT support for a replacement device.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => SystemNavigator.pop(),
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Exit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
