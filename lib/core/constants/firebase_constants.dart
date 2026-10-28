/// Firebase Configuration Credentials
/// Configurable via `--dart-define=FIREBASE_API_KEY=...` and `--dart-define=FIREBASE_APP_ID=...`
class FirebaseConstants {
  static const String projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'pharmaguide-ddbaf',
  );

  static const String projectNumber = String.fromEnvironment(
    'FIREBASE_PROJECT_NUMBER',
    defaultValue: '690677054248',
  );

  static const String storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'pharmaguide-ddbaf.firebasestorage.app',
  );

  static const String apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );

  static const String appId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '',
  );

  static const String authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: 'pharmaguide-ddbaf.firebaseapp.com',
  );

  static bool get isConfigured => apiKey.isNotEmpty && appId.isNotEmpty;
}
