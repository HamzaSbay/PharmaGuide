/// Supabase Configuration Credentials
/// Configurable via `--dart-define=SUPABASE_URL=...` and `--dart-define=SUPABASE_ANON_KEY=...`
/// When not configured, PharmaGuide seamlessly falls back to the local offline repository.
class SupabaseConstants {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      supabaseUrl != 'YOUR_SUPABASE_PROJECT_URL' &&
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';
}
