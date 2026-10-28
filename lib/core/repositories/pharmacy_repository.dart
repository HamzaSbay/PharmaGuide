import '../models/pharmacy_model.dart';

abstract interface class IPharmacyRepository {
  List<PharmacyModel> get pharmacies;
  PharmacyModel? getPharmacyById(String id);
  Future<List<PharmacyModel>> findNearbyWithStock({
    required String drugId,
    required double lat,
    required double lng,
    double radiusKm = 15.0,
    bool requiresCnam = false,
    bool onlyGarde = false,
  });
  Future<void> updatePharmacyStatus(String id, String status);
  Future<void> addPharmacy(PharmacyModel pharmacy);
}
