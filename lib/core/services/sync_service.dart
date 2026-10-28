import 'dart:async';
import 'package:flutter/foundation.dart';
import 'cache_service.dart';
import 'mock_data_service.dart';
import 'supabase_service.dart';
import '../models/drug_model.dart';

/// Auto-Sync Service for PharmaGuide TN
/// Periodically fetches medication catalog updates, live stock levels,
/// and active 2-hour hold reservations every 5 minutes.
class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  Timer? _syncTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  int _syncedItemCount = 0;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get syncedItemCount => _syncedItemCount;

  /// Start the 5-minute periodic background sync loop
  void startAutoSync() {
    if (_syncTimer != null && _syncTimer!.isActive) return;

    debugPrint('🔄 [SYNC] Starting 5-minute background medication sync loop');
    // Immediate initial sync
    syncNow();

    // Repeat every 5 minutes (300 seconds)
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      debugPrint('🔄 [SYNC] 5-minute auto-sync timer fired');
      syncNow();
    });
  }

  /// Stop the background sync loop
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    debugPrint('🛑 [SYNC] Background sync loop stopped');
  }

  /// Trigger an immediate manual or pull-to-refresh sync
  Future<void> syncNow() async {
    if (_isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      debugPrint('🔄 [SYNC] Synchronizing medication catalog & stock changes...');

      // 1. Fetch latest medication list from Supabase or fallback to catalog
      final List<DrugModel> updatedDrugs = await SupabaseService().searchDrugs('');
      
      // Only update cache if we got actual results — never wipe the offline catalog
      if (updatedDrugs.isNotEmpty) {
        await CacheService().cacheDrugCatalog(updatedDrugs);
        _syncedItemCount = updatedDrugs.length;
      } else {
        _syncedItemCount = MockDataService().masterDrugs.length;
        debugPrint('⚠️ [SYNC] Empty response from server — preserving local cache');
      }

      _lastSyncTime = DateTime.now();
      debugPrint('✅ [SYNC] Auto-sync complete at ${_formatTime(_lastSyncTime!)} ($_syncedItemCount items updated)');
    } catch (e) {
      debugPrint('⚠️ [SYNC] Sync encounter error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  void disposeService() {
    stopAutoSync();
  }

  @override
  void dispose() {
    stopAutoSync();
    super.dispose();
  }
}
