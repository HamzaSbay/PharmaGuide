import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/mock_data_service.dart';
import '../../core/models/reservation_model.dart';
import '../../core/screens/privacy_policy_screen.dart';
import '../../core/screens/terms_screen.dart';
import '../../core/screens/login_screen.dart';
import '../../main.dart';
import '../../core/services/favorites_service.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  double _searchRadius = 15.0;
  bool _cnamDefault = false;
  bool _darkMode = false;
  String _language = 'Français';

  final AuthService _authService = AuthService();
  final CacheService _cacheService = CacheService();
  final MockDataService _mockDataService = MockDataService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final radius = await _cacheService.getSetting('search_radius');
    final cnam = await _cacheService.getSetting('cnam_default');
    final dark = await _cacheService.getSetting('dark_mode');
    
    if (!mounted) return;
    setState(() {
      if (radius != null) _searchRadius = double.tryParse(radius.toString()) ?? 15.0;
      if (cnam != null) _cnamDefault = cnam == 'true' || cnam == true;
      if (dark != null) _darkMode = dark == 'true' || dark == true;
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _authService.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen(onLoginSuccess: () {})),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeReservations = _mockDataService.reservations.where((r) => 
      r.status == ReservationStatus.pending || r.status == ReservationStatus.confirmed).length;
    final chronicRemindersCount = _mockDataService.chronicReminders.length;
    final currentUser = _authService.currentUser;
    final phone = currentUser?.phone ?? 'Non connecté';
    final isVerified = currentUser?.isVerified ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: AppTheme.pharmacyGreen,
      ),
      body: ListView(
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.pharmacyGreen,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      phone,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.deepBlack),
                    ),
                    if (isVerified)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Text('✅', style: TextStyle(fontSize: 20)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Réservations', activeReservations.toString()),
                _buildStatCard('Rappels', chronicRemindersCount.toString()),
                _buildStatCard('Favoris', FavoritesService().totalFavorites.toString()),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),

          // Settings Section
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Paramètres',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.deepBlack),
            ),
          ),
          ListTile(
            title: const Text('Rayon de recherche'),
            subtitle: Text('${_searchRadius.toInt()} km'),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: _searchRadius,
                min: 5,
                max: 50,
                divisions: 9,
                activeColor: AppTheme.pharmacyGreen,
                onChanged: (value) {
                  setState(() => _searchRadius = value);
                  _cacheService.saveSetting('search_radius', value);
                },
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Filtre CNAM par défaut'),
            activeTrackColor: AppTheme.pharmacyGreen.withValues(alpha: 0.5),
            thumbColor: WidgetStateProperty.resolveWith((states) => 
              states.contains(WidgetState.selected) ? AppTheme.pharmacyGreen : null),
            value: _cnamDefault,
            onChanged: (value) {
              setState(() => _cnamDefault = value);
              _cacheService.saveSetting('cnam_default', value);
            },
          ),
          SwitchListTile(
            title: const Text('Mode sombre'),
            activeTrackColor: AppTheme.pharmacyGreen.withValues(alpha: 0.5),
            thumbColor: WidgetStateProperty.resolveWith((states) => 
              states.contains(WidgetState.selected) ? AppTheme.pharmacyGreen : null),
            value: _darkMode,
            onChanged: (value) {
              setState(() => _darkMode = value);
              _cacheService.saveSetting('dark_mode', value);
              PharmaGuideApp.themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
            },
          ),
          ListTile(
            title: const Text('Langue'),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Français', label: Text('Fr')),
                ButtonSegment(value: 'عربية', label: Text('Ar')),
              ],
              selected: {_language},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => _language = newSelection.first);
                final locale = newSelection.first == 'عربية' ? const Locale('ar') : const Locale('fr');
                PharmaGuideApp.localeNotifier.value = locale;
                _cacheService.saveSetting('language', locale.languageCode);
              },
            ),
          ),
          const Divider(),

          // Legal Section
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Légal & À propos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.deepBlack),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Politique de Confidentialité'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Conditions Générales'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TermsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('À propos de PharmaGuide'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'PharmaGuide TN',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.local_pharmacy, color: AppTheme.pharmacyGreen, size: 40),
                children: [
                  const Text('L\'application qui vous aide à trouver vos médicaments facilement en Tunisie.'),
                ],
              );
            },
          ),
          const Divider(),

          // Logout
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _logout,
              child: const Text('Déconnexion'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.pharmacyGreen),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: AppTheme.deepBlack),
            ),
          ],
        ),
      ),
    );
  }
}
