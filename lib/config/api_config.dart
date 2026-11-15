/// Backend API environment configuration.
///
/// In production or staging, configure via dart-define:
/// `flutter run --dart-define=BACKEND_URL=https://eldencare.onrender.com`
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://eldencare.onrender.com',
  );

  static String get healthUrl => '$baseUrl/health';
  static String get apiV1 => '$baseUrl/api/v1';

  // Notification endpoints
  static String get devicesUrl => '$apiV1/notifications/devices';
  static String get preferencesUrl => '$apiV1/notifications/preferences';
  static String get historyUrl => '$apiV1/notifications/history';
  static String get markAllReadUrl => '$apiV1/notifications/mark-all-read';

  // Healthcare endpoints
  static String get patientsUrl => '$apiV1/patients';
  static String get medicationsUrl => '$apiV1/medications';
  static String get confirmationsUrl => '$apiV1/confirmations';
}
