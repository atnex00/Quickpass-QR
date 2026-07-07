import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class CertificatePinner {
  static const List<String> _pins = [
    // SHA-256 hashes of your server's full DER certificate (certificate pinning).
    //
    // Add your production server's certificate hash here. You can include
    // multiple hashes to support certificate rotation without breaking the app.
    //
    // Generate a pin from your server's certificate:
    //   openssl s_client -connect yourserver.com:443 -servername yourserver.com </dev/null 2>/dev/null \
    //     | openssl x509 -outform der \
    //     | openssl dgst -sha256
    //
    // Or from a PEM certificate file:
    //   openssl x509 -in cert.pem -outform der | openssl dgst -sha256
    //
    // Example (do NOT use — zero hash placeholder):
    // 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
  ];

  static bool check(X509Certificate cert, String host, int port) {
    if (kDebugMode || kProfileMode) {
      return true;
    }

    final pin = sha256.convert(cert.der).toString();
    final matched = _pins.contains(pin);
    return matched;
  }

  static String pinFromCert(X509Certificate cert) =>
      sha256.convert(cert.der).toString();
}
