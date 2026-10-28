/// Shared constants for Tunisia-specific data
/// Used across patient, pharmacist, and admin portals
class TunisiaConstants {
  /// All 24 governorates of Tunisia (official names)
  static const List<String> governorates = [
    'Tunis',
    'Ariana',
    'Ben Arous',
    'Manouba',
    'Nabeul',
    'Zaghouan',
    'Bizerte',
    'Béja',
    'Jendouba',
    'Le Kef',
    'Siliana',
    'Sousse',
    'Monastir',
    'Mahdia',
    'Sfax',
    'Kairouan',
    'Kasserine',
    'Sidi Bouzid',
    'Gabès',
    'Medenine',
    'Tataouine',
    'Gafsa',
    'Tozeur',
    'Kebili',
  ];

  /// Governorate center coordinates for map positioning
  static const Map<String, List<double>> governorateCoordinates = {
    'Tunis': [36.8065, 10.1815],
    'Ariana': [36.8625, 10.1956],
    'Ben Arous': [36.7533, 10.2283],
    'Manouba': [36.8101, 10.0956],
    'Nabeul': [36.4513, 10.7357],
    'Zaghouan': [36.4029, 10.1429],
    'Bizerte': [37.2746, 9.8739],
    'Béja': [36.7256, 9.1817],
    'Jendouba': [36.5013, 8.7801],
    'Le Kef': [36.1742, 8.7048],
    'Siliana': [36.0849, 9.3708],
    'Sousse': [35.8256, 10.6369],
    'Monastir': [35.7780, 10.8260],
    'Mahdia': [35.5047, 11.0622],
    'Sfax': [34.7406, 10.7603],
    'Kairouan': [35.6781, 10.0963],
    'Kasserine': [35.1676, 8.8365],
    'Sidi Bouzid': [35.0382, 9.4858],
    'Gabès': [33.8815, 10.0982],
    'Medenine': [33.3399, 10.4914],
    'Tataouine': [32.9297, 10.4518],
    'Gafsa': [34.4250, 8.7842],
    'Tozeur': [33.9197, 8.1336],
    'Kebili': [33.7044, 8.9690],
  };

  /// Medication categories for the PCT catalog
  static const List<String> drugCategories = [
    'Tous',
    'Fièvre & Douleur',
    'Cœur & Tension',
    'Jambes & Veines',
    'Yeux & Vision',
    'Estomac & Digestion',
    'Diabète & Métabolisme',
    'Infections & Antibio',
  ];

  /// Cache setting keys (prevents typos from raw strings)
  static const String keyHasSeenOnboarding = 'has_seen_onboarding';
  static const String keySearchRadius = 'search_radius';
  static const String keyRequiresCnam = 'requires_cnam';
  static const String keyOnlyGarde = 'only_garde';
}
