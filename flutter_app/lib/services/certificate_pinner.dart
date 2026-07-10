import 'dart:io';

class CertificatePinner {
  // Set these with SHA-256 SPKI hashes of your server's certificate(s) for production.
  // Generate with: openssl s_client -connect yourdomain.com:443 -servername yourdomain.com </dev/null 2>/dev/null | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
  static const List<String> _pins = [];

  static void apply(HttpClient client) {
    if (_pins.isEmpty) return;
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      final spkiHash = _extractSpkiHash(cert);
      return _pins.contains(spkiHash);
    };
  }

  static String? _extractSpkiHash(X509Certificate cert) {
    try {
      return cert.pem
          .split('\n')
          .where((l) => !l.startsWith('-----'))
          .join('');
    } catch (_) {
      return null;
    }
  }
}
