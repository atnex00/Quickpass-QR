class AppConfig {
  static const String appName = 'Quickpass';
  static const String appVersion = '1.0.0';
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const int qrValidityMinutes = 15;
}
