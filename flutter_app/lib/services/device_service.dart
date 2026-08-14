import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceService {
  static Future<String> getFingerprint() async {
    final info = DeviceInfoPlugin();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = await info.androidInfo;
      final raw =
          '${android.id}:${android.brand}:${android.device}:${android.fingerprint}';
      return sha256.convert(utf8.encode(raw)).toString();
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = await info.iosInfo;
      final raw = 'ios:${ios.identifierForVendor ?? ios.model}';
      return sha256.convert(utf8.encode(raw)).toString();
    }
    final raw = 'other:${defaultTargetPlatform.name}';
    return sha256.convert(utf8.encode(raw)).toString();
  }
}
