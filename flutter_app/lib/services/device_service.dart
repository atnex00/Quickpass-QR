import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceService {
  static Future<String> getFingerprint() async {
    final info = DeviceInfoPlugin();
    final android = await info.androidInfo;
    final raw =
        '${android.id}:${android.brand}:${android.device}:${android.fingerprint}';
    return sha256.convert(utf8.encode(raw)).toString();
  }
}
