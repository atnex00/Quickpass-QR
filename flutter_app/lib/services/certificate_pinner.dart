import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

class CertificatePinner {
  static const List<String> _pins = [];

  static bool? isPinned(X509Certificate cert) {
    if (_pins.isEmpty) return null;

    final spkiHash = _extractSpkiHash(cert);
    if (spkiHash == null) return false;

    return _pins.any((pin) => pin == spkiHash);
  }

  static String? _extractSpkiHash(X509Certificate cert) {
    try {
      final lines = cert.pem.split('\n');
      final b64 = lines.where((l) => !l.startsWith('-----')).join('');
      final derBytes = base64Decode(b64);

      var offset = 0;
      if (derBytes[offset] != 0x30) return null;
      offset += _readTlvLength(derBytes, offset + 1);

      if (offset >= derBytes.length || derBytes[offset] != 0x30) return null;
      offset += _readTlvLength(derBytes, offset + 1);

      while (offset < derBytes.length) {
        if (derBytes[offset] == 0x30) {
          final tlvLen = _readTlvLength(derBytes, offset + 1);
          offset += tlvLen;
        } else {
          break;
        }
      }

      if (offset >= derBytes.length || derBytes[offset] != 0x03) return null;
      offset += _readTlvLength(derBytes, offset + 1);

      if (offset >= derBytes.length || derBytes[offset] != 0x00) return null;
      offset++;

      if (offset >= derBytes.length || derBytes[offset] != 0x30) return null;
      final spkiLen = _readTlvLength(derBytes, offset + 1);
      final spkiBytes = derBytes.sublist(offset, offset + spkiLen);

      final hash = sha256.convert(spkiBytes);
      return base64.encode(hash.bytes);
    } catch (_) {
      return null;
    }
  }

  static int _readTlvLength(List<int> der, int start) {
    if (start >= der.length) return 0;
    if (der[start] < 0x80) return der[start] + (start + 1 - start);
    final numOctets = der[start] & 0x7F;
    if (numOctets == 0 || start + numOctets >= der.length) return 0;
    var length = 0;
    for (var i = 0; i < numOctets; i++) {
      length = (length << 8) | der[start + 1 + i];
    }
    return length + (start + 1 + numOctets - start);
  }
}
