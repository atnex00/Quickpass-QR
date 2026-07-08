import 'dart:io';
import 'package:crypto/crypto.dart';

class CertificatePinner {
  static const List<String> _pins = [];

  static bool check(X509Certificate cert, String host, int port) {
    if (_pins.isEmpty) {
      return true;
    }
    final pin = sha256.convert(cert.der).toString();
    final matched = _pins.contains(pin);
    return matched;
  }

  static String pinFromCert(X509Certificate cert) =>
      sha256.convert(cert.der).toString();
}
