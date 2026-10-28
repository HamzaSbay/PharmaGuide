import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/pharmacy_model.dart';
import 'mock_data_service.dart';

class OfflineEmergencyService {
  static final OfflineEmergencyService _instance = OfflineEmergencyService._internal();
  factory OfflineEmergencyService() => _instance;
  OfflineEmergencyService._internal();

  static const String _boxName = 'offline_pharmacies_phonebook';
  Box? _phonebookBox;

  /// Initialize Hive offline box and pre-cache pharmacy directory
  Future<void> initOfflineCache() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        _phonebookBox = await Hive.openBox(_boxName);
      } else {
        _phonebookBox = Hive.box(_boxName);
      }

      // Pre-cache all pharmacies across 24 governorates for offline access
      final allPharmacies = MockDataService().pharmacies;
      for (var pharmacy in allPharmacies) {
        await _phonebookBox?.put(pharmacy.id, pharmacy.toJson());
      }

      debugPrint('📶 [OFFLINE CACHE] Cached ${allPharmacies.length} pharmacies across 24 governorates for 0-internet offline access.');
    } catch (e) {
      debugPrint('📶 [OFFLINE CACHE] Hive init error: $e');
    }
  }

  /// Get cached offline pharmacies for a specific governorate
  List<PharmacyModel> getOfflinePharmacies(String governorate) {
    if (_phonebookBox == null || !_phonebookBox!.isOpen) {
      return MockDataService().pharmacies.where((p) => p.governorate.toLowerCase() == governorate.toLowerCase()).toList();
    }

    final List<PharmacyModel> cached = [];
    for (var key in _phonebookBox!.keys) {
      final jsonMap = _phonebookBox!.get(key);
      if (jsonMap != null && jsonMap is Map) {
        final pharmacy = PharmacyModel.fromJson(Map<String, dynamic>.from(jsonMap));
        if (pharmacy.governorate.toLowerCase() == governorate.toLowerCase() || governorate == 'Tous') {
          cached.add(pharmacy);
        }
      }
    }

    return cached.isNotEmpty
        ? cached
        : MockDataService().pharmacies.where((p) => p.governorate.toLowerCase() == governorate.toLowerCase() || governorate == 'Tous').toList();
  }
}
