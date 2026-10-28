import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'l10n/app_localizations.dart';
import 'core/constants/supabase_constants.dart';
import 'core/constants/theme.dart';
import 'core/services/cache_service.dart';
import 'core/services/drug_interaction_service.dart';
import 'core/services/favorites_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/offline_emergency_service.dart';
import 'core/services/auth_service.dart';
import 'core/repositories/repository_registry.dart';
import 'patient_mobile/screens/onboarding_screen.dart';
import 'patient_mobile/screens/patient_home_screen.dart';
import 'pharmacist_web/screens/pharmacy_cnop_auth_gate.dart';
import 'admin_portal/screens/admin_pin_auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheService().init();
  await OfflineEmergencyService().initOfflineCache();
  await AuthService().restoreSession();
  RepositoryRegistry.instance.init();

  // Initialize Firebase for push notifications
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      debugPrint('[FIREBASE] Initialized successfully');
    } catch (e) {
      debugPrint('[FIREBASE] Init failed (expected in dev): $e');
    }
  }

  if (SupabaseConstants.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConstants.supabaseUrl,
      publishableKey: SupabaseConstants.supabaseAnonKey,
    );
  }

  // Initialize favorites, notifications & drug interaction engine
  await FavoritesService().init();
  await NotificationService().init();
  await NotificationService().requestPermission();
  await DrugInteractionService().init();

  // Start 5-minute background auto-sync loop for medication catalog & stock changes
  SyncService().startAutoSync();

  runApp(const PharmaGuideApp());
}

class PharmaGuideApp extends StatefulWidget {
  const PharmaGuideApp({super.key});

  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
  static final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('fr'));

  @override
  State<PharmaGuideApp> createState() => _PharmaGuideAppState();
}

class _PharmaGuideAppState extends State<PharmaGuideApp> {
  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    final dark = await CacheService().getSetting('dark_mode');
    if (dark == 'true' || dark == true) {
      PharmaGuideApp.themeNotifier.value = ThemeMode.dark;
    }
    final lang = await CacheService().getSetting('language');
    if (lang == 'ar') {
      PharmaGuideApp.localeNotifier.value = const Locale('ar');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: PharmaGuideApp.themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return ValueListenableBuilder<Locale>(
          valueListenable: PharmaGuideApp.localeNotifier,
          builder: (_, Locale currentLocale, __) {
            return MaterialApp(
              title: 'PharmaGuide TN - Trouvez vos Médicaments en Officine',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: currentMode,
              // Localization support (French default + Arabic RTL)
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: currentLocale,
              initialRoute: _resolveInitialRoute(),
              onGenerateRoute: (settings) {
                switch (settings.name) {
                  case '/pharmacy':
                  case '/pharmacie':
                    return MaterialPageRoute(builder: (_) => const PharmacyCnopAuthGate());
                  case '/admin':
                    return MaterialPageRoute(builder: (_) => const AdminPinAuthGate());
                  case '/patient':
                  case '/':
                  default:
                    return MaterialPageRoute(
                      builder: (_) => kIsWeb ? const PatientHomeScreen() : const OnboardingScreen(),
                    );
                }
              },
            );
          },
        );
      },
    );
  }

  String _resolveInitialRoute() {
    if (!kIsWeb) return '/';
    final Uri uri = Uri.base;
    final String path = uri.path.toLowerCase();
    final String role = uri.queryParameters['role']?.toLowerCase() ?? '';

    if (path.contains('/pharmacy') || path.contains('/pharmacie') || role == 'pharmacy') {
      return '/pharmacy';
    }
    if (path.contains('/admin') || role == 'admin') {
      return '/admin';
    }
    return '/';
  }
}
