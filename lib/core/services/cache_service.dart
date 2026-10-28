import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/drug_model.dart';

/// Offline cache service using Hive for patient search results
/// Enables offline access to recent pharmacy searches and drug catalog
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _recentSearchesBox = 'recent_searches';
  static const String _drugCatalogBox = 'drug_catalog_cache';
  static const String _settingsBox = 'user_settings';
  static const int maxRecentSearches = 20;

  bool _isInitialized = false;

  /// Initialize Hive for Flutter (call once at app start)
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await Hive.initFlutter();
      await Hive.openBox<Map>(_recentSearchesBox);
      await Hive.openBox<Map>(_drugCatalogBox);
      await Hive.openBox(_settingsBox);
      _isInitialized = true;
      debugPrint('📦 [CACHE] Hive offline cache initialized successfully');
    } catch (e) {
      debugPrint('📦 [CACHE] Hive init failed (expected on first run): $e');
    }
  }

  // ──────────────────────────────────────────────
  // RECENT SEARCHES
  // ──────────────────────────────────────────────

  /// Save a recent drug search query with timestamp
  Future<void> saveRecentSearch({
    required String query,
    required String drugId,
    required String drugName,
    required String dciName,
  }) async {
    if (!_isInitialized) return;
    try {
      final box = Hive.box<Map>(_recentSearchesBox);
      final entry = {
        'query': query,
        'drugId': drugId,
        'drugName': drugName,
        'dciName': dciName,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Remove duplicate if exists
      final keys = box.keys.toList();
      for (var key in keys) {
        final existing = box.get(key);
        if (existing != null && existing['drugId'] == drugId) {
          await box.delete(key);
        }
      }

      // Add new entry
      await box.add(entry);

      // Trim to max recent searches
      while (box.length > maxRecentSearches) {
        await box.deleteAt(0);
      }
    } catch (e) {
      debugPrint('📦 [CACHE] Failed to save recent search: $e');
    }
  }

  /// Get recent searches sorted by most recent first
  List<Map<String, dynamic>> getRecentSearches() {
    if (!_isInitialized) return [];
    try {
      final box = Hive.box<Map>(_recentSearchesBox);
      final searches = box.values
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
      searches.sort((a, b) =>
          (b['timestamp'] as String).compareTo(a['timestamp'] as String));
      return searches;
    } catch (e) {
      debugPrint('📦 [CACHE] Failed to get recent searches: $e');
      return [];
    }
  }

  /// Clear all recent searches
  Future<void> clearRecentSearches() async {
    if (!_isInitialized) return;
    try {
      final box = Hive.box<Map>(_recentSearchesBox);
      await box.clear();
    } catch (e) {
      debugPrint('📦 [CACHE] Failed to clear recent searches: $e');
    }
  }

  // ──────────────────────────────────────────────
  // DRUG CATALOG CACHE (for offline browse)
  // ──────────────────────────────────────────────

  /// Cache the full drug catalog for offline access
  Future<void> cacheDrugCatalog(List<DrugModel> drugs) async {
    if (!_isInitialized) return;
    try {
      final box = Hive.box<Map>(_drugCatalogBox);
      await box.clear();
      for (var drug in drugs) {
        await box.put(drug.id, {
          'id': drug.id,
          'brandName': drug.brandName,
          'dciName': drug.dciName,
          'dosage': drug.dosage,
          'form': drug.form,
          'pctCode': drug.pctCode,
          'requiresPrescription': drug.requiresPrescription,
          'isBlacklisted': drug.isBlacklisted,
        });
      }
      debugPrint('📦 [CACHE] Cached ${drugs.length} drugs for offline access');
    } catch (e) {
      debugPrint('📦 [CACHE] Failed to cache drug catalog: $e');
    }
  }

  /// Get cached drug catalog (offline fallback)
  List<DrugModel> getCachedDrugCatalog() {
    if (!_isInitialized) return [];
    try {
      final box = Hive.box<Map>(_drugCatalogBox);
      return box.values.map((m) => DrugModel(
        id: (m['id'] ?? '').toString(),
        brandName: (m['brandName'] ?? '').toString(),
        dciName: (m['dciName'] ?? '').toString(),
        dosage: (m['dosage'] ?? '').toString(),
        form: (m['form'] ?? '').toString(),
        pctCode: (m['pctCode'] ?? '').toString(),
        requiresPrescription: m['requiresPrescription'] == true,
        isBlacklisted: m['isBlacklisted'] == true,
      )).toList();
    } catch (e) {
      debugPrint('📦 [CACHE] Failed to get cached drug catalog: $e');
      return [];
    }
  }

  // ──────────────────────────────────────────────
  // USER SETTINGS (radius, filters, preferences)
  // ──────────────────────────────────────────────

  /// Save a user preference
  Future<void> saveSetting(String key, dynamic value) async {
    if (!_isInitialized) return;
    try {
      final box = Hive.box(_settingsBox);
      await box.put(key, value);
    } catch (e) {
      debugPrint('📦 [CACHE] Failed to save setting $key: $e');
    }
  }

  /// Get a user preference
  T? getSetting<T>(String key, {T? defaultValue}) {
    if (!_isInitialized) return defaultValue;
    try {
      final box = Hive.box(_settingsBox);
      return box.get(key, defaultValue: defaultValue) as T?;
    } catch (e) {
      debugPrint('📦 [CACHE] Failed to get setting $key: $e');
      return defaultValue;
    }
  }

  /// Clear all cached data (for logout or privacy)
  Future<void> clearAll() async {
    if (!_isInitialized) return;
    try {
      await Hive.box<Map>(_recentSearchesBox).clear();
      await Hive.box<Map>(_drugCatalogBox).clear();
      debugPrint('📦 [CACHE] All cached data cleared');
    } catch (e) {
      debugPrint('📦 [CACHE] Failed to clear all caches: $e');
    }
  }
}
