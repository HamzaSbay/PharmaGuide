import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FavoritesService extends ChangeNotifier {
  // Singleton pattern
  FavoritesService._privateConstructor();
  static final FavoritesService _instance = FavoritesService._privateConstructor();
  factory FavoritesService() => _instance;
  static FavoritesService get instance => _instance;

  bool _isInitialized = false;
  List<String> _favoritePharmacyIds = [];
  List<String> _favoriteDrugIds = [];

  late Box<String> _pharmaciesBox;
  late Box<String> _drugsBox;

  bool get isInitialized => _isInitialized;
  List<String> get favoritePharmacyIds => List.unmodifiable(_favoritePharmacyIds);
  List<String> get favoriteDrugIds => List.unmodifiable(_favoriteDrugIds);
  int get totalFavorites => _favoritePharmacyIds.length + _favoriteDrugIds.length;

  Future<void> init() async {
    if (_isInitialized) return;

    _pharmaciesBox = await Hive.openBox<String>('favorite_pharmacies');
    _drugsBox = await Hive.openBox<String>('favorite_drugs');

    _favoritePharmacyIds = _pharmaciesBox.values.toList();
    _favoriteDrugIds = _drugsBox.values.toList();

    _isInitialized = true;
    notifyListeners();
  }

  bool isPharmacyFavorite(String pharmacyId) {
    return _favoritePharmacyIds.contains(pharmacyId);
  }

  bool isDrugFavorite(String drugId) {
    return _favoriteDrugIds.contains(drugId);
  }

  Future<void> togglePharmacyFavorite(String pharmacyId) async {
    if (isPharmacyFavorite(pharmacyId)) {
      _favoritePharmacyIds.remove(pharmacyId);
      await _pharmaciesBox.delete(pharmacyId);
    } else {
      _favoritePharmacyIds.add(pharmacyId);
      await _pharmaciesBox.put(pharmacyId, pharmacyId);
    }
    notifyListeners();
  }

  Future<void> toggleDrugFavorite(String drugId) async {
    if (isDrugFavorite(drugId)) {
      _favoriteDrugIds.remove(drugId);
      await _drugsBox.delete(drugId);
    } else {
      _favoriteDrugIds.add(drugId);
      await _drugsBox.put(drugId, drugId);
    }
    notifyListeners();
  }
}
