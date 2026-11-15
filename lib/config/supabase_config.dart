/// Supabase environment configuration.
///
/// In production or staging, configure via dart-define:
/// `flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...`
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    // Fallback placeholder
    defaultValue: '',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    // Fallback placeholder
    defaultValue: '',
  );

  /// Whether valid Supabase credentials have been configured.
  static bool get isConfigured =>
      url.isNotEmpty &&
      anonKey.isNotEmpty &&
      url.startsWith('http') &&
      !url.contains('placeholder');
}
