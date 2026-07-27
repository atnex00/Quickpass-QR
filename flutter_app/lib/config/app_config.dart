class AppConfig {
  static const String appName = 'Quickpass';
  static const String appVersion = '1.0.0';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://182.168.1.15:3000/api',
  );
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const int qrValidityMinutes = 15;

  static String? photoUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    final base = apiBaseUrl.replaceFirst('/api', '');
    return '$base$path';
  }
}
