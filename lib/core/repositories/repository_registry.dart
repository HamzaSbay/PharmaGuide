import 'drug_repository.dart';
import 'pharmacy_repository.dart';
import 'reservation_repository.dart';
import 'inventory_repository.dart';
import 'b2b_repository.dart';
import 'family_profile_repository.dart';
import '../models/drug_model.dart';
import '../models/pharmacy_model.dart';
import '../models/reservation_model.dart';
import '../models/inventory_model.dart';
import '../models/b2b_request_model.dart';
import '../models/family_profile_model.dart';
import '../models/basket_optimization_model.dart';
import '../utils/result.dart';
import '../services/mock_data_service.dart';

/// Central Dependency Injection Service Locator for PharmaGuide Domain Repositories.
class RepositoryRegistry {
  static final RepositoryRegistry instance = RepositoryRegistry._internal();
  factory RepositoryRegistry() => instance;
  RepositoryRegistry._internal();

  late IDrugRepository drugs;
  late IPharmacyRepository pharmacies;
  late IReservationRepository reservations;
  late IInventoryRepository inventories;
  late IB2BRepository b2b;
  late IFamilyProfileRepository familyProfiles;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  void init({
    IDrugRepository? drugRepo,
    IPharmacyRepository? pharmacyRepo,
    IReservationRepository? reservationRepo,
    IInventoryRepository? inventoryRepo,
    IB2BRepository? b2bRepo,
    IFamilyProfileRepository? familyProfileRepo,
  }) {
    final mock = MockDataService();

    drugs = drugRepo ?? _MockDrugRepositoryAdapter(mock);
    pharmacies = pharmacyRepo ?? _MockPharmacyRepositoryAdapter(mock);
    reservations = reservationRepo ?? _MockReservationRepositoryAdapter(mock);
    inventories = inventoryRepo ?? _MockInventoryRepositoryAdapter(mock);
    b2b = b2bRepo ?? _MockB2BRepositoryAdapter(mock);
    familyProfiles = familyProfileRepo ?? _MockFamilyProfileRepositoryAdapter(mock);

    _isInitialized = true;
  }
}

// ---------------------------------------------------------------------------
// Adapters connecting Repository contracts to MockDataService
// ---------------------------------------------------------------------------

class _MockDrugRepositoryAdapter implements IDrugRepository {
  final MockDataService _mock;
  _MockDrugRepositoryAdapter(this._mock);

  @override
  List<DrugModel> get masterDrugs => _mock.masterDrugs;

  @override
  Future<List<DrugModel>> searchDrugs(String query) async => _mock.searchDrugs(query);

  @override
  DrugModel? findDrugByBarcode(String barcode) => _mock.findDrugByBarcode(barcode);

  @override
  List<GenericSubstituteResult> getGenericSubstitutes(DrugModel drug) => _mock.getGenericSubstitutes(drug);

  @override
  Future<void> toggleDrugBlacklist(String drugId) async => _mock.toggleDrugBlacklist(drugId);

  @override
  Future<void> addDrug(DrugModel drug) async => _mock.addMasterDrug(drug);
}

class _MockPharmacyRepositoryAdapter implements IPharmacyRepository {
  final MockDataService _mock;
  _MockPharmacyRepositoryAdapter(this._mock);

  @override
  List<PharmacyModel> get pharmacies => _mock.pharmacies;

  @override
  PharmacyModel? getPharmacyById(String id) {
    final matches = _mock.pharmacies.where((p) => p.id == id);
    return matches.isNotEmpty ? matches.first : null;
  }

  @override
  Future<List<PharmacyModel>> findNearbyWithStock({
    required String drugId,
    required double lat,
    required double lng,
    double radiusKm = 15.0,
    bool requiresCnam = false,
    bool onlyGarde = false,
  }) async {
    return _mock.findNearbyPharmaciesWithStock(
      drugId: drugId,
      lat: lat,
      lng: lng,
      radiusKm: radiusKm,
      requiresCnam: requiresCnam,
      onlyGarde: onlyGarde,
    );
  }

  @override
  Future<void> updatePharmacyStatus(String id, String status) async {
    if (status == 'APPROVED') {
      _mock.approvePharmacy(id);
    }
  }

  @override
  Future<void> addPharmacy(PharmacyModel pharmacy) async {
    _mock.addPharmacy(pharmacy);
  }
}

class _MockReservationRepositoryAdapter implements IReservationRepository {
  final MockDataService _mock;
  _MockReservationRepositoryAdapter(this._mock);

  @override
  List<ReservationModel> get reservations => _mock.reservations;

  @override
  Future<Result<ReservationModel>> createReservation({
    required String patientId,
    required String patientPhone,
    required String pharmacyId,
    required String drugId,
    String? prescriptionUrl,
  }) async {
    try {
      final success = await _mock.createReservation(
        patientId: patientId,
        patientPhone: patientPhone,
        pharmacyId: pharmacyId,
        drugId: drugId,
        prescriptionUrl: prescriptionUrl,
      );
      if (success) {
        final res = _mock.reservations.firstWhere((r) => r.patientId == patientId && r.drugId == drugId);
        return Success(res);
      }
      return const Failure('Impossible de créer la réservation (quota atteint ou stock épuisé).');
    } catch (e) {
      return Failure(e.toString(), e);
    }
  }

  @override
  Future<Result<List<ReservationModel>>> createMultiDrugReservation({
    required String patientId,
    required String patientPhone,
    required String pharmacyId,
    required List<String> drugIds,
    String? prescriptionUrl,
  }) async {
    try {
      final created = await _mock.createMultiDrugReservation(
        patientId: patientId,
        patientPhone: patientPhone,
        pharmacyId: pharmacyId,
        drugIds: drugIds,
      );
      return Success(created);
    } catch (e) {
      return Failure(e.toString(), e);
    }
  }

  @override
  Future<void> updateReservationStatus(String resId, ReservationStatus newStatus) async {
    _mock.updateReservationStatus(resId, newStatus);
  }
}

class _MockInventoryRepositoryAdapter implements IInventoryRepository {
  final MockDataService _mock;
  _MockInventoryRepositoryAdapter(this._mock);

  @override
  List<InventoryModel> get inventories => _mock.inventories;

  @override
  int getStock(String pharmacyId, String drugId) {
    final matches = _mock.inventories.where((i) => i.pharmacyId == pharmacyId && i.drugId == drugId);
    return matches.isNotEmpty ? matches.first.quantity : 0;
  }

  @override
  Future<void> updateStockQuantity(String pharmacyId, String drugId, int newQuantity) async {
    _mock.updateStockQuantity(pharmacyId, drugId, newQuantity);
  }

  @override
  Future<void> confirmAllInventoryFresh(String pharmacyId) async {
    _mock.confirmAllInventoryFresh(pharmacyId);
  }
}

class _MockB2BRepositoryAdapter implements IB2BRepository {
  final MockDataService _mock;
  _MockB2BRepositoryAdapter(this._mock);

  @override
  List<B2BRequestModel> get b2bRequests => _mock.b2bRequests;

  @override
  Future<void> createB2BRequest({
    required String requestingPharmacyId,
    required String targetPharmacyId,
    required String drugId,
    required int quantity,
    String? notes,
  }) async {
    _mock.createB2BRequest(
      requestingPharmacyId: requestingPharmacyId,
      targetPharmacyId: targetPharmacyId,
      drugId: drugId,
      quantity: quantity,
      notes: notes,
    );
  }

  @override
  Future<void> updateB2BRequestStatus(String requestId, B2BRequestStatus newStatus) async {
    _mock.updateB2BRequestStatus(requestId, newStatus);
  }
}

class _MockFamilyProfileRepositoryAdapter implements IFamilyProfileRepository {
  final MockDataService _mock;
  _MockFamilyProfileRepositoryAdapter(this._mock);

  @override
  List<FamilyProfileModel> get familyProfiles => _mock.familyProfiles;

  @override
  Future<void> addFamilyProfile(FamilyProfileModel profile) async {
    _mock.addFamilyProfile(profile);
  }

  @override
  Future<void> removeFamilyProfile(String profileId) async {
    _mock.removeFamilyProfile(profileId);
  }

  @override
  Future<void> toggleMedicationInProfile(String profileId, String drugId) async {
    _mock.toggleMedicationInProfile(profileId, drugId);
  }
}
