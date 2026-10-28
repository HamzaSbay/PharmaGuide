/// Supabase Configuration Credentials
/// Project: PharmaGuide (Ref: kpsxtixxmgsxlpusiygs)
class SupabaseConstants {
  static const String supabaseUrl = 'https://kpsxtixxmgsxlpusiygs.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_wehK7TZSNuJ1lyPHNWtdOQ_pxobRyu2';

  static bool get isConfigured =>
      supabaseUrl != 'YOUR_SUPABASE_PROJECT_URL' &&
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY' &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty;
}
