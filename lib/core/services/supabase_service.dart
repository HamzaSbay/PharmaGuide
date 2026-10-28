import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import '../models/drug_model.dart';
import '../models/pharmacy_model.dart';
import '../models/reservation_model.dart';
import 'mock_data_service.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final MockDataService _mock = MockDataService();

  SupabaseClient? get client =>
      SupabaseConstants.isConfigured ? Supabase.instance.client : null;

  /// Real-time fuzzy drug search from Supabase Postgres `drugs` table
  Future<List<DrugModel>> searchDrugs(String query) async {
    if (client == null) return _mock.searchDrugs(query);

    try {
      final response = await client!
          .from('master_drugs')
          .select()
          .eq('is_blacklisted', false)
          .or('brand_name.ilike.%$query%,dci_name.ilike.%$query%,pct_code.ilike.%$query%')
          .limit(25);

      return (response as List).map((row) => DrugModel(
        id: row['id'] as String,
        brandName: row['brand_name'] as String,
        dciName: row['dci_name'] as String,
        dosage: row['dosage'] as String,
        form: row['form'] as String,
        pctCode: row['pct_code'] as String,
        requiresPrescription: row['requires_prescription'] as bool? ?? false,
        isBlacklisted: row['is_blacklisted'] as bool? ?? false,
      )).toList();
    } catch (e) {
      debugPrint('⚠️ [SUPABASE] Search fallback to mock: $e');
      return _mock.searchDrugs(query);
    }
  }

  /// Spatial query for nearby pharmacies with live stock via PostGIS RPC `find_nearby_pharmacies_with_stock`
  Future<List<PharmacyModel>> findNearbyPharmaciesWithStock({
    required String drugId,
    required double lat,
    required double lng,
    double radiusKm = 15.0,
    bool requiresCnam = false,
    bool onlyGarde = false,
  }) async {
    if (client == null) {
      return _mock.findNearbyPharmaciesWithStock(
        drugId: drugId,
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
        requiresCnam: requiresCnam,
        onlyGarde: onlyGarde,
      );
    }

    try {
      final List<dynamic> response = await client!.rpc('find_nearby_pharmacies_with_stock', params: {
        'target_drug_id': drugId,
        'user_lat': lat,
        'user_lng': lng,
        'max_distance_km': radiusKm,
        'filter_cnam': requiresCnam,
        'filter_garde': onlyGarde,
      });

      return response.map((row) => PharmacyModel.fromJson(Map<String, dynamic>.from(row as Map))).toList();
    } catch (e) {
      debugPrint('⚠️ [SUPABASE] PostGIS RPC fallback to mock: $e');
      return _mock.findNearbyPharmaciesWithStock(
        drugId: drugId,
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
        requiresCnam: requiresCnam,
        onlyGarde: onlyGarde,
      );
    }
  }

  /// Insert a 2-hour hold reservation in Supabase `reservations` table
  Future<bool> createReservation({
    required String patientId,
    required String patientPhone,
    required String pharmacyId,
    required String drugId,
    String? prescriptionUrl,
  }) async {
    if (client == null) {
      return _mock.createReservation(
        patientId: patientId,
        patientPhone: patientPhone,
        pharmacyId: pharmacyId,
        drugId: drugId,
        prescriptionUrl: prescriptionUrl,
      );
    }

    try {
      final now = DateTime.now();
      final expires = now.add(const Duration(hours: 2));

      await client!.from('reservations').insert({
        'patient_id': patientId,
        'patient_phone': patientPhone,
        'pharmacy_id': pharmacyId,
        'drug_id': drugId,
        'prescription_url': prescriptionUrl,
        'status': 'PENDING',
        'created_at': now.toIso8601String(),
        'expires_at': expires.toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('⚠️ [SUPABASE] Create reservation fallback to mock: $e');
      return _mock.createReservation(
        patientId: patientId,
        patientPhone: patientPhone,
        pharmacyId: pharmacyId,
        drugId: drugId,
        prescriptionUrl: prescriptionUrl,
      );
    }
  }

  /// Update reservation status in Supabase `reservations` table
  Future<void> updateReservationStatus(String resId, ReservationStatus status) async {
    if (client == null) {
      _mock.updateReservationStatus(resId, status);
      return;
    }

    try {
      await client!
          .from('reservations')
          .update({'status': status.name})
          .eq('id', resId);
    } catch (e) {
      debugPrint('⚠️ [SUPABASE] Update status fallback to mock: $e');
      _mock.updateReservationStatus(resId, status);
    }
  }

  /// Subscribe to real-time reservation changes for a pharmacy (WebSocket)
  RealtimeChannel? subscribeToPharmacyReservations(
    String pharmacyId,
    void Function(Map<String, dynamic> payload) onReservationReceived,
  ) {
    if (client == null) return null;

    return client!
        .channel('public:reservations:pharmacy_id=eq.$pharmacyId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'reservations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'pharmacy_id',
            value: pharmacyId,
          ),
          callback: (payload) => onReservationReceived(payload.newRecord),
        )
        .subscribe();
  }
}
