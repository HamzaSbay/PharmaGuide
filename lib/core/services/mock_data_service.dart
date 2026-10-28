import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/drug_model.dart';
import '../models/pharmacy_model.dart';
import '../models/inventory_model.dart';
import '../models/reservation_model.dart';
import '../models/b2b_request_model.dart';
import '../models/broadcast_alert_model.dart';
import '../models/garde_shift_model.dart';
import '../models/chronic_reminder_model.dart';
import '../models/family_profile_model.dart';
import '../models/basket_optimization_model.dart';
import '../utils/fuzzy_search.dart';
import 'audio_service.dart';
import 'sms_service.dart';

class MockDataService extends ChangeNotifier {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal() {
    _initMockData();
    // Auto-expire 2h holds every 30 seconds
    Timer.periodic(const Duration(seconds: 30), (_) => _autoExpireHolds());
  }

  void _autoExpireHolds() {
    bool changed = false;
    for (int i = 0; i < _reservations.length; i++) {
      if (_reservations[i].isExpired && _reservations[i].status == ReservationStatus.PENDING) {
        _reservations[i] = _reservations[i].copyWith(status: ReservationStatus.EXPIRED);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  // State Containers
  final List<DrugModel> _masterDrugs = [];
  final List<PharmacyModel> _pharmacies = [];
  final List<InventoryModel> _inventories = [];
  final List<ReservationModel> _reservations = [];
  final List<B2BRequestModel> _b2bRequests = [];
  final List<AvailabilityAlert> _availabilityAlerts = [];
  final List<EmergencyBroadcast> _emergencyBroadcasts = [];
  final List<GardeShiftModel> _gardeShifts = [];
  final List<ChronicReminderModel> _chronicReminders = [];
  final List<FamilyProfileModel> _familyProfiles = [];

  // Getters
  List<DrugModel> get masterDrugs => List.unmodifiable(_masterDrugs);
  List<PharmacyModel> get pharmacies => List.unmodifiable(_pharmacies);
  List<InventoryModel> get inventories => List.unmodifiable(_inventories);
  List<ReservationModel> get reservations => List.unmodifiable(_reservations);
  List<B2BRequestModel> get b2bRequests => List.unmodifiable(_b2bRequests);
  List<AvailabilityAlert> get availabilityAlerts => List.unmodifiable(_availabilityAlerts);
  List<EmergencyBroadcast> get emergencyBroadcasts => List.unmodifiable(_emergencyBroadcasts);
  List<GardeShiftModel> get gardeShifts => List.unmodifiable(_gardeShifts);
  List<ChronicReminderModel> get chronicReminders => List.unmodifiable(_chronicReminders);
  List<FamilyProfileModel> get familyProfiles => List.unmodifiable(_familyProfiles);

  /// Add chronic disease re-order reminder
  void addChronicReminder(ChronicReminderModel reminder) {
    _chronicReminders.add(reminder);
    notifyListeners();
  }

  /// Delete chronic disease reminder
  void removeChronicReminder(String reminderId) {
    _chronicReminders.removeWhere((r) => r.id == reminderId);
    notifyListeners();
  }

  /// Check if pharmacy is on official CNOP night guard duty tonight
  bool isPharmacyOnGardeTonight(String pharmacyId) {
    final now = DateTime.now();
    return _gardeShifts.any((shift) =>
        shift.pharmacyId == pharmacyId &&
        shift.shiftDate.year == now.year &&
        shift.shiftDate.month == now.month &&
        shift.shiftDate.day == now.day);
  }

  /// Add official CNOP Garde shift
  void addGardeShift(GardeShiftModel shift) {
    _gardeShifts.add(shift);
    notifyListeners();
  }

  /// Remove CNOP Garde shift
  void removeGardeShift(String shiftId) {
    _gardeShifts.removeWhere((s) => s.id == shiftId);
    notifyListeners();
  }

  /// Register patient stock availability alert
  void addAvailabilityAlert({
    required String patientPhone,
    required String drugId,
    required String drugName,
  }) {
    _availabilityAlerts.add(AvailabilityAlert(
      id: 'alert-${DateTime.now().millisecondsSinceEpoch}',
      patientPhone: patientPhone,
      drugId: drugId,
      drugName: drugName,
      createdAt: DateTime.now(),
    ));
    notifyListeners();
  }

  /// Check if user has an active Back-in-Stock Radar alert for a drug
  bool hasRadarAlert(String drugId) {
    return _availabilityAlerts.any((a) => a.drugId == drugId && !a.isNotified);
  }

  /// Toggle Back-in-Stock Radar alert for a drug
  void toggleRadarAlert({
    required String drugId,
    required String drugName,
    required String patientPhone,
  }) {
    final existingIdx = _availabilityAlerts.indexWhere((a) => a.drugId == drugId && !a.isNotified);
    if (existingIdx != -1) {
      _availabilityAlerts.removeAt(existingIdx);
    } else {
      addAvailabilityAlert(
        patientPhone: patientPhone,
        drugId: drugId,
        drugName: drugName,
      );
    }
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // FAMILY PROFILES & CHRONIC PRESCRIPTION SUITE
  // ──────────────────────────────────────────────

  void addMasterDrug(DrugModel drug) {
    _masterDrugs.add(drug);
    notifyListeners();
  }

  void addPharmacy(PharmacyModel pharmacy) {
    _pharmacies.add(pharmacy);
    notifyListeners();
  }

  void addFamilyProfile(FamilyProfileModel profile) {
    _familyProfiles.add(profile);
    notifyListeners();
  }

  void updateFamilyProfile(FamilyProfileModel profile) {
    final index = _familyProfiles.indexWhere((p) => p.id == profile.id);
    if (index != -1) {
      _familyProfiles[index] = profile;
      notifyListeners();
    }
  }

  void removeFamilyProfile(String profileId) {
    _familyProfiles.removeWhere((p) => p.id == profileId);
    notifyListeners();
  }

  void toggleMedicationInProfile(String profileId, String drugId) {
    final index = _familyProfiles.indexWhere((p) => p.id == profileId);
    if (index != -1) {
      final current = List<String>.from(_familyProfiles[index].chronicMedicationIds);
      if (current.contains(drugId)) {
        current.remove(drugId);
      } else {
        current.add(drugId);
      }
      _familyProfiles[index] = _familyProfiles[index].copyWith(chronicMedicationIds: current);
      notifyListeners();
    }
  }

  /// Register emergency broadcast request for rare/critical medications
  void addEmergencyBroadcast({
    required String drugName,
    required String governorate,
    required String patientPhone,
    String? prescriptionImageUrl,
  }) {
    _emergencyBroadcasts.add(EmergencyBroadcast(
      id: 'bcast-${DateTime.now().millisecondsSinceEpoch}',
      patientPhone: patientPhone,
      drugName: drugName,
      governorate: governorate,
      prescriptionImageUrl: prescriptionImageUrl,
      createdAt: DateTime.now(),
    ));
    AudioService().playNotificationSound();
    notifyListeners();
  }

  /// Confirm all inventory stock fresh (Stale Stock Health Score re-confirmation)
  void confirmAllInventoryFresh(String pharmacyId) {
    for (int i = 0; i < _inventories.length; i++) {
      if (_inventories[i].pharmacyId == pharmacyId) {
        _inventories[i] = InventoryModel(
          id: _inventories[i].id,
          pharmacyId: _inventories[i].pharmacyId,
          drugId: _inventories[i].drugId,
          quantity: _inventories[i].quantity,
          lastUpdatedAt: DateTime.now(),
        );
      }
    }
    notifyListeners();
  }

  // Default User Coordinate (Tunis City Center / Avenue Habib Bourguiba)
  double userLat = 36.8002;
  double userLng = 10.1860;

  void _initMockData() {
    // 1. Enriched Master Drugs Catalog by Category (Tunisia PCT)
    _masterDrugs.addAll([
      // Fièvre & Douleur (Fever & Pain)
      DrugModel(
        id: 'drug-1',
        brandName: 'Doliprane 1000mg',
        dciName: 'Paracetamol',
        dosage: '1000mg',
        form: 'Comprimé / Gélule',
        pctCode: 'PCT-10492',
        category: 'Fièvre & Douleur',
        arabicName: 'دولبران 1000',
        aliases: ['dawaa el sekkri', 'wjaa al rass', 'sodaa', 'grippe', 'fevre'],
        requiresPrescription: false,
        isCnamReimbursable: true,
        sideEffects: 'Nausées légères, somnolence possible en cas de surdosage.',
        contraindications: 'Insuffisance hépatique sévère ou hypersensibilité au paracétamol.',
        interactions: 'Consommation d\'alcool, anticoagulants oraux.',
        barcode: '3400935824921',
        substituteIds: ['drug-10'],
      ),
      DrugModel(
        id: 'drug-2',
        brandName: 'Doliprane Sirop 2.4%',
        dciName: 'Paracetamol',
        dosage: '2.4%',
        form: 'Sirop Pédiatrique',
        pctCode: 'PCT-10493',
        category: 'Fièvre & Douleur',
        arabicName: 'دولبران سيرو',
        aliases: ['dawaa al atfal', 'khonjo', 'grippe'],
        requiresPrescription: false,
        barcode: '3400935824938',
      ),
      DrugModel(
        id: 'drug-4',
        brandName: 'Aspegic 500mg',
        dciName: 'Acide Acétylsalicylique',
        dosage: '500mg',
        form: 'Sachet Poudre',
        pctCode: 'PCT-10114',
        category: 'Fièvre & Douleur',
        arabicName: 'أسبجيك 500',
        aliases: ['aspegic', 'wjaa', 'ras'],
        requiresPrescription: false,
        isCnamReimbursable: true,
        sideEffects: 'Maux d\'estomac, bourdonnements d\'oreilles.',
        contraindications: 'Ulcère gastrique, risque hémorragique, allergie à l\'aspirine.',
        interactions: 'Anticoagulants (Sintrom), Ibuprofène, AINS.',
        barcode: '3400931234567',
      ),
      DrugModel(
        id: 'drug-10',
        brandName: 'Efferalgan 1g',
        dciName: 'Paracetamol',
        dosage: '1000mg',
        form: 'Comprimé Effervescent',
        pctCode: 'PCT-10499',
        category: 'Fièvre & Douleur',
        arabicName: 'إيفرالغان',
        aliases: ['efferalgan', 'fevre'],
        requiresPrescription: false,
        barcode: '3400934987654',
        substituteIds: ['drug-1'],
      ),
      DrugModel(
        id: 'drug-11',
        brandName: 'Advil 400mg',
        dciName: 'Ibuprofène',
        dosage: '400mg',
        form: 'Comprimé Enrobé',
        pctCode: 'PCT-10811',
        category: 'Fièvre & Douleur',
        arabicName: 'أدفيل 400',
        aliases: ['advil', 'wjaa dhhar'],
        requiresPrescription: false,
        isCnamReimbursable: true,
        sideEffects: 'Brûlures d\'estomac, étourdissements.',
        contraindications: 'Grossesse (3ème trimestre), insuffisance rénale ou cardiaque.',
        interactions: 'Aspirine, antihypertenseurs, diurétiques.',
      ),

      // Cœur & Tension (Heart / Cardiovascular)
      DrugModel(
        id: 'drug-12',
        brandName: 'Tencor 50mg',
        dciName: 'Aténolol',
        dosage: '50mg',
        form: 'Comprimé Pelliculé',
        pctCode: 'PCT-60101',
        category: 'Cœur & Tension',
        requiresPrescription: true,
      ),
      DrugModel(
        id: 'drug-13',
        brandName: 'Aprovel 150mg',
        dciName: 'Irbésartan',
        dosage: '150mg',
        form: 'Comprimé',
        pctCode: 'PCT-60205',
        category: 'Cœur & Tension',
        requiresPrescription: true,
      ),
      DrugModel(
        id: 'drug-14',
        brandName: 'Kardegic 75mg',
        dciName: 'Acétylsalicylate de DL-Lysine',
        dosage: '75mg',
        form: 'Sachet Poudre',
        pctCode: 'PCT-60310',
        category: 'Cœur & Tension',
        requiresPrescription: true,
      ),
      DrugModel(
        id: 'drug-15',
        brandName: 'Tahor 20mg',
        dciName: 'Atorvastatine',
        dosage: '20mg',
        form: 'Comprimé',
        pctCode: 'PCT-60450',
        category: 'Cœur & Tension',
        requiresPrescription: true,
      ),

      // Jambes & Veines (Legs / Venous Circulation)
      DrugModel(
        id: 'drug-16',
        brandName: 'Daflon 500mg',
        dciName: 'Fraction Flavonoïque Purifiée',
        dosage: '500mg',
        form: 'Comprimé Pelliculé',
        pctCode: 'PCT-70102',
        category: 'Jambes & Veines',
        requiresPrescription: false,
      ),
      DrugModel(
        id: 'drug-17',
        brandName: 'Cyclo 3 Fort',
        dciName: 'Petit Houx + Hespéridine + Vitamine C',
        dosage: 'Gélule',
        form: 'Gélule',
        pctCode: 'PCT-70105',
        category: 'Jambes & Veines',
        requiresPrescription: false,
      ),
      DrugModel(
        id: 'drug-18',
        brandName: 'Veinamitol 3500mg',
        dciName: 'Troxérutine',
        dosage: '3500mg',
        form: 'Sachet Solution Buvable',
        pctCode: 'PCT-70120',
        category: 'Jambes & Veines',
        requiresPrescription: false,
      ),

      // Yeux & Vision (Eyes / Ophtalmology)
      DrugModel(
        id: 'drug-19',
        brandName: 'Tobradex Collyre',
        dciName: 'Tobramycine + Dexaméthasone',
        dosage: '5ml',
        form: 'Collyre en Suspension',
        pctCode: 'PCT-80101',
        category: 'Yeux & Vision',
        requiresPrescription: true,
      ),
      DrugModel(
        id: 'drug-20',
        brandName: 'Rifamycin Collyre',
        dciName: 'Rifamiycine Sodique',
        dosage: '1%',
        form: 'Collyre',
        pctCode: 'PCT-80104',
        category: 'Yeux & Vision',
        requiresPrescription: true,
      ),
      DrugModel(
        id: 'drug-21',
        brandName: 'Dacryoserum',
        dciName: 'Borate de Sodium + Acide Borique',
        dosage: '5ml',
        form: 'Rince Yeux Unidose',
        pctCode: 'PCT-80110',
        category: 'Yeux & Vision',
        requiresPrescription: false,
      ),

      // Infections & Antibiotiques (Antibiotics)
      DrugModel(
        id: 'drug-3',
        brandName: 'Augmentin 1g/125mg',
        dciName: 'Amoxicilline + Acide Clavulanique',
        dosage: '1g/125mg',
        form: 'Comprimé Pelliculé',
        pctCode: 'PCT-20381',
        category: 'Infections & Antibio',
        requiresPrescription: true,
      ),
      DrugModel(
        id: 'drug-6',
        brandName: 'Clamoxyl 500mg',
        dciName: 'Amoxicilline',
        dosage: '500mg',
        form: 'Gélule',
        pctCode: 'PCT-20104',
        category: 'Infections & Antibio',
        requiresPrescription: true,
      ),

      // Estomac & Digestion (Stomach / Gastro)
      DrugModel(
        id: 'drug-7',
        brandName: 'Spasfon 80mg',
        dciName: 'Phloroglucinol',
        dosage: '80mg',
        form: 'Comprimé',
        pctCode: 'PCT-30421',
        category: 'Estomac & Digestion',
        requiresPrescription: false,
      ),
      DrugModel(
        id: 'drug-22',
        brandName: 'Inexium 20mg',
        dciName: 'Ésoméprazole',
        dosage: '20mg',
        form: 'Comprimé Gastro-résistant',
        pctCode: 'PCT-30450',
        category: 'Estomac & Digestion',
        requiresPrescription: true,
      ),
      DrugModel(
        id: 'drug-23',
        brandName: 'Gaviscon Suspension',
        dciName: 'Alginate de Sodium + Bicarbonate',
        dosage: '250ml',
        form: 'Flacon Suspension Oral',
        pctCode: 'PCT-30480',
        category: 'Estomac & Digestion',
        requiresPrescription: false,
      ),

      // Diabète (Diabetes)
      DrugModel(
        id: 'drug-24',
        brandName: 'Glucophage 1000mg',
        dciName: 'Metformine',
        dosage: '1000mg',
        form: 'Comprimé Pelliculé',
        pctCode: 'PCT-90101',
        category: 'Diabète & Métabolisme',
        requiresPrescription: true,
        isNationalRupture: true,
        barcode: '3400936123456',
        substituteIds: ['drug-26'],
      ),
      DrugModel(
        id: 'drug-25',
        brandName: 'Lantus SoloStar',
        dciName: 'Insuline Glargine',
        dosage: '100U/ml',
        form: 'Stylo Injectable Prérempli',
        pctCode: 'PCT-90150',
        category: 'Diabète & Métabolisme',
        requiresPrescription: true,
        isNationalRupture: true,
        barcode: '3400936987654',
      ),
      DrugModel(
        id: 'drug-26',
        brandName: 'Metformine Saiph 1000mg',
        dciName: 'Metformine',
        dosage: '1000mg',
        form: 'Comprimé Pelliculé',
        pctCode: 'PCT-90102',
        category: 'Diabète & Métabolisme',
        requiresPrescription: true,
        barcode: '6191234567890',
        substituteIds: ['drug-24'],
      ),
    ]);

    // 2. Pharmacies across Tunisia (All Key Governorates)
    _pharmacies.addAll([
      // Tunis & Ariana
      PharmacyModel(
        id: 'ph-1',
        cnopId: 'CNOP-TN-4012',
        name: 'Pharmacie Principale El Menzah',
        governorate: 'Tunis',
        municipality: 'El Menzah 6',
        address: '12 Avenue Ahmed Tlili, El Menzah 6, Tunis',
        phoneLandline: '+216 71 750 120',
        latitude: 36.8333,
        longitude: 10.1833,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-2',
        cnopId: 'CNOP-TN-4015',
        name: 'Pharmacie Central Habib Bourguiba',
        governorate: 'Tunis',
        municipality: 'Ville Basse',
        address: '45 Avenue Habib Bourguiba, Tunis',
        phoneLandline: '+216 71 254 890',
        latitude: 36.8005,
        longitude: 10.1850,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-3',
        cnopId: 'CNOP-TN-4088',
        name: 'Pharmacie du Lac',
        governorate: 'Tunis',
        municipality: 'Les Berges du Lac 1',
        address: 'Rue du Lac Biwa, Les Berges du Lac, Tunis',
        phoneLandline: '+216 71 960 411',
        latitude: 36.8360,
        longitude: 10.2370,
        acceptsCnam: false,
        isGarde: true,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-4',
        cnopId: 'CNOP-TN-4090',
        name: 'Pharmacie Ennasr',
        governorate: 'Ariana',
        municipality: 'Ennasr 2',
        address: 'Avenue Hédi Nouira, Ennasr 2, Ariana',
        phoneLandline: '+216 71 827 300',
        latitude: 36.8570,
        longitude: 10.1600,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),

      // Sousse & Monastir
      PharmacyModel(
        id: 'ph-5',
        cnopId: 'CNOP-SO-2010',
        name: 'Pharmacie de la Corniche Sousse',
        governorate: 'Sousse',
        municipality: 'Bouhsina / Corniche',
        address: 'Boulevard 14 Janvier, Corniche, Sousse',
        phoneLandline: '+216 73 225 100',
        latitude: 35.8333,
        longitude: 10.6333,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-6',
        cnopId: 'CNOP-MO-3011',
        name: 'Pharmacie Ibn Sina Monastir',
        governorate: 'Monastir',
        municipality: 'Centre Ville Monastir',
        address: 'Avenue de la République, Monastir',
        phoneLandline: '+216 73 461 200',
        latitude: 35.7780,
        longitude: 10.8260,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),

      // Sfax
      PharmacyModel(
        id: 'ph-7',
        cnopId: 'CNOP-SF-5012',
        name: 'Pharmacie El Hédi Chaker Sfax',
        governorate: 'Sfax',
        municipality: 'Sfax Ville',
        address: 'Avenue Majida Boulila, Sfax',
        phoneLandline: '+216 74 240 550',
        latitude: 34.7406,
        longitude: 10.7603,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),

      // Bizerte & Nabeul
      PharmacyModel(
        id: 'ph-8',
        cnopId: 'CNOP-BI-6010',
        name: 'Pharmacie du Vieux Port Bizerte',
        governorate: 'Bizerte',
        municipality: 'Bizerte Nord',
        address: 'Quai Tarak Ibn Ziad, Bizerte',
        phoneLandline: '+216 72 431 800',
        latitude: 37.2746,
        longitude: 9.8739,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-9',
        cnopId: 'CNOP-NA-7015',
        name: 'Pharmacie Hammamet Sud',
        governorate: 'Nabeul',
        municipality: 'Hammamet',
        address: 'Zone Touristique Yasmine Hammamet, Nabeul',
        phoneLandline: '+216 72 240 110',
        latitude: 36.3760,
        longitude: 10.5400,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),

      // Gabès & Medenine / Djerba
      PharmacyModel(
        id: 'ph-10',
        cnopId: 'CNOP-GA-8020',
        name: 'Pharmacie de l\'Oasis Gabès',
        governorate: 'Gabès',
        municipality: 'Gabès Ville',
        address: 'Avenue Farhat Hached, Gabès',
        phoneLandline: '+216 75 270 300',
        latitude: 33.8815,
        longitude: 10.0982,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-11',
        cnopId: 'CNOP-ME-9030',
        name: 'Pharmacie Djerba Houmt Souk',
        governorate: 'Medenine',
        municipality: 'Djerba Houmt Souk',
        address: 'Avenue Habib Bourguiba, Houmt Souk, Djerba',
        phoneLandline: '+216 75 650 220',
        latitude: 33.8750,
        longitude: 10.8580,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),

      // Ben Arous & Manouba
      PharmacyModel(
        id: 'ph-12',
        cnopId: 'CNOP-BA-1020',
        name: 'Pharmacie Ezzahra Center',
        governorate: 'Ben Arous',
        municipality: 'Ezzahra',
        address: 'Avenue 14 Janvier, Ezzahra, Ben Arous',
        phoneLandline: '+216 71 450 110',
        latitude: 36.7430,
        longitude: 10.3080,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-13',
        cnopId: 'CNOP-MN-1030',
        name: 'Pharmacie Manouba Université',
        governorate: 'Manouba',
        municipality: 'Manouba',
        address: 'Route de la Ksar Saïd, Manouba',
        phoneLandline: '+216 71 600 220',
        latitude: 36.8101,
        longitude: 10.0956,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),

      // Zaghouan & Béja
      PharmacyModel(
        id: 'ph-14',
        cnopId: 'CNOP-ZG-1040',
        name: 'Pharmacie Temple des Eaux',
        governorate: 'Zaghouan',
        municipality: 'Zaghouan',
        address: 'Avenue de l\'Indépendance, Zaghouan',
        phoneLandline: '+216 72 675 300',
        latitude: 36.4029,
        longitude: 10.1429,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-15',
        cnopId: 'CNOP-BJ-1050',
        name: 'Pharmacie Béja Médina',
        governorate: 'Béja',
        municipality: 'Béja Nord',
        address: 'Avenue Habib Bourguiba, Béja',
        phoneLandline: '+216 78 450 120',
        latitude: 36.7256,
        longitude: 9.1817,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),

      // Jendouba & Le Kef & Siliana
      PharmacyModel(
        id: 'ph-16',
        cnopId: 'CNOP-JN-1060',
        name: 'Pharmacie Tabarka Corniche',
        governorate: 'Jendouba',
        municipality: 'Tabarka',
        address: 'Avenue Habib Bourguiba, Tabarka',
        phoneLandline: '+216 78 670 400',
        latitude: 36.9540,
        longitude: 8.7580,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-17',
        cnopId: 'CNOP-KF-1070',
        name: 'Pharmacie Le Kef Kasbah',
        governorate: 'Le Kef',
        municipality: 'Le Kef Est',
        address: 'Rue Ali Belhouane, Le Kef',
        phoneLandline: '+216 78 200 110',
        latitude: 36.1742,
        longitude: 8.7048,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-18',
        cnopId: 'CNOP-SL-1080',
        name: 'Pharmacie Siliana Center',
        governorate: 'Siliana',
        municipality: 'Siliana Ville',
        address: 'Avenue de l\'Environnement, Siliana',
        phoneLandline: '+216 78 870 200',
        latitude: 36.0849,
        longitude: 9.3708,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),

      // Mahdia & Kairouan & Kasserine & Sidi Bouzid
      PharmacyModel(
        id: 'ph-19',
        cnopId: 'CNOP-MH-1090',
        name: 'Pharmacie Cap Zouila Mahdia',
        governorate: 'Mahdia',
        municipality: 'Mahdia Ville',
        address: 'Avenue Taïeb Hachicha, Mahdia',
        phoneLandline: '+216 73 680 150',
        latitude: 35.5047,
        longitude: 11.0622,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-20',
        cnopId: 'CNOP-KR-1100',
        name: 'Pharmacie Okba Kairouan',
        governorate: 'Kairouan',
        municipality: 'Kairouan Nord',
        address: 'Avenue Beit El Hikma, Kairouan',
        phoneLandline: '+216 77 230 400',
        latitude: 35.6781,
        longitude: 10.0963,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-21',
        cnopId: 'CNOP-KS-1110',
        name: 'Pharmacie Kasserine Center',
        governorate: 'Kasserine',
        municipality: 'Kasserine Ville',
        address: 'Avenue Habib Bourguiba, Kasserine',
        phoneLandline: '+216 77 470 300',
        latitude: 35.1676,
        longitude: 8.8365,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-22',
        cnopId: 'CNOP-SB-1120',
        name: 'Pharmacie Sidi Bouzid Center',
        governorate: 'Sidi Bouzid',
        municipality: 'Sidi Bouzid Ville',
        address: 'Avenue de la République, Sidi Bouzid',
        phoneLandline: '+216 76 630 200',
        latitude: 35.0382,
        longitude: 9.4858,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),

      // Tataouine & Gafsa & Tozeur & Kebili
      PharmacyModel(
        id: 'ph-23',
        cnopId: 'CNOP-TT-1130',
        name: 'Pharmacie Tataouine Ksour',
        governorate: 'Tataouine',
        municipality: 'Tataouine Ville',
        address: 'Avenue Farhat Hached, Tataouine',
        phoneLandline: '+216 75 860 100',
        latitude: 32.9297,
        longitude: 10.4518,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-24',
        cnopId: 'CNOP-GF-1140',
        name: 'Pharmacie Gafsa Oasis',
        governorate: 'Gafsa',
        municipality: 'Gafsa Ville',
        address: 'Avenue Palestine, Gafsa',
        phoneLandline: '+216 76 220 500',
        latitude: 34.4250,
        longitude: 8.7842,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-25',
        cnopId: 'CNOP-TZ-1150',
        name: 'Pharmacie Tozeur Palmeraie',
        governorate: 'Tozeur',
        municipality: 'Tozeur Ville',
        address: 'Avenue Aboulkacem Chebbi, Tozeur',
        phoneLandline: '+216 76 450 300',
        latitude: 33.9197,
        longitude: 8.1336,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-26',
        cnopId: 'CNOP-KB-1160',
        name: 'Pharmacie Kebili Oasis',
        governorate: 'Kebili',
        municipality: 'Kebili Ville',
        address: 'Avenue de la Liberté, Kebili',
        phoneLandline: '+216 75 490 200',
        latitude: 33.7044,
        longitude: 8.9690,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),

      // Additional Real Pharmacies across all 24 Governorates
      // Tunis
      PharmacyModel(
        id: 'ph-27',
        cnopId: 'CNOP-TN-5011',
        name: 'Pharmacie de Nuit Liberté',
        governorate: 'Tunis',
        municipality: 'Lafayette',
        address: '89 Avenue de la Liberté, Lafayette, Tunis',
        phoneLandline: '+216 71 280 450',
        latitude: 36.8120,
        longitude: 10.1810,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-28',
        cnopId: 'CNOP-TN-5022',
        name: 'Pharmacie La Marsa Plage',
        governorate: 'Tunis',
        municipality: 'La Marsa',
        address: '14 Avenue Habib Bourguiba, La Marsa Plage',
        phoneLandline: '+216 71 740 330',
        latitude: 36.8830,
        longitude: 10.3250,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-29',
        cnopId: 'CNOP-TN-5033',
        name: 'Pharmacie Carthage Byrsa',
        governorate: 'Tunis',
        municipality: 'Carthage',
        address: '22 Rue Hannibal, Carthage Byrsa',
        phoneLandline: '+216 71 731 220',
        latitude: 36.8520,
        longitude: 10.3310,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),

      // Ariana
      PharmacyModel(
        id: 'ph-30',
        cnopId: 'CNOP-AR-2020',
        name: 'Pharmacie Ariana Ville',
        governorate: 'Ariana',
        municipality: 'Ariana Centre',
        address: 'Avenue Habib Bourguiba, Ariana',
        phoneLandline: '+216 71 710 450',
        latitude: 36.8625,
        longitude: 10.1956,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-31',
        cnopId: 'CNOP-AR-2030',
        name: 'Pharmacie La Soukra 24/7',
        governorate: 'Ariana',
        municipality: 'La Soukra',
        address: 'Route de la Soukra, Chotrana 1',
        phoneLandline: '+216 71 765 800',
        latitude: 36.8850,
        longitude: 10.2520,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),

      // Ben Arous
      PharmacyModel(
        id: 'ph-32',
        cnopId: 'CNOP-BA-3010',
        name: 'Pharmacie Médina Mégrine',
        governorate: 'Ben Arous',
        municipality: 'Mégrine',
        address: 'Avenue Habib Bourguiba, Mégrine',
        phoneLandline: '+216 71 295 440',
        latitude: 36.7680,
        longitude: 10.2380,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-33',
        cnopId: 'CNOP-BA-3020',
        name: 'Pharmacie Radès Plage',
        governorate: 'Ben Arous',
        municipality: 'Radès',
        address: 'Avenue de la République, Radès Plage',
        phoneLandline: '+216 71 441 200',
        latitude: 36.7670,
        longitude: 10.2800,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-34',
        cnopId: 'CNOP-BA-3030',
        name: 'Pharmacie Hammam Lif Centre',
        governorate: 'Ben Arous',
        municipality: 'Hammam Lif',
        address: 'Avenue Habib Thameur, Hammam Lif',
        phoneLandline: '+216 71 290 100',
        latitude: 36.7310,
        longitude: 10.3370,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),

      // Manouba
      PharmacyModel(
        id: 'ph-35',
        cnopId: 'CNOP-MN-2010',
        name: 'Pharmacie Denden 24/7',
        governorate: 'Manouba',
        municipality: 'Denden',
        address: 'Boulevard de l\'Environnement, Denden',
        phoneLandline: '+216 71 602 110',
        latitude: 36.8080,
        longitude: 10.1120,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-36',
        cnopId: 'CNOP-MN-2020',
        name: 'Pharmacie Oued Ellil',
        governorate: 'Manouba',
        municipality: 'Oued Ellil',
        address: 'Route de Bizerte km 7, Oued Ellil',
        phoneLandline: '+216 71 620 300',
        latitude: 36.8320,
        longitude: 10.0380,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),

      // Nabeul
      PharmacyModel(
        id: 'ph-37',
        cnopId: 'CNOP-NA-3010',
        name: 'Pharmacie du Port Nabeul',
        governorate: 'Nabeul',
        municipality: 'Nabeul Ville',
        address: 'Avenue Habib Thameur, Nabeul Centre',
        phoneLandline: '+216 72 285 300',
        latitude: 36.4550,
        longitude: 10.7350,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-38',
        cnopId: 'CNOP-NA-3020',
        name: 'Pharmacie Kélibia Plage',
        governorate: 'Nabeul',
        municipality: 'Kélibia',
        address: 'Avenue Ali Belhouane, Kélibia',
        phoneLandline: '+216 72 296 400',
        latitude: 36.8480,
        longitude: 11.0920,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),

      // Zaghouan
      PharmacyModel(
        id: 'ph-39',
        cnopId: 'CNOP-ZG-2010',
        name: 'Pharmacie El Fahs',
        governorate: 'Zaghouan',
        municipality: 'El Fahs',
        address: 'Avenue Habib Bourguiba, El Fahs',
        phoneLandline: '+216 72 680 150',
        latitude: 36.3720,
        longitude: 9.9050,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),

      // Bizerte
      PharmacyModel(
        id: 'ph-40',
        cnopId: 'CNOP-BI-3010',
        name: 'Pharmacie Menzel Bourguiba',
        governorate: 'Bizerte',
        municipality: 'Menzel Bourguiba',
        address: 'Avenue 15 Octobre, Menzel Bourguiba',
        phoneLandline: '+216 72 460 200',
        latitude: 37.1530,
        longitude: 9.7860,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-41',
        cnopId: 'CNOP-BI-3020',
        name: 'Pharmacie Zarzouna',
        governorate: 'Bizerte',
        municipality: 'Zarzouna',
        address: 'Route de Ras Djebel, Zarzouna',
        phoneLandline: '+216 72 590 110',
        latitude: 37.2610,
        longitude: 9.8820,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),

      // Béja
      PharmacyModel(
        id: 'ph-42',
        cnopId: 'CNOP-BJ-2010',
        name: 'Pharmacie Medjez El Bab',
        governorate: 'Béja',
        municipality: 'Medjez El Bab',
        address: 'Avenue de la République, Medjez El Bab',
        phoneLandline: '+216 78 560 300',
        latitude: 36.6500,
        longitude: 9.6100,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),

      // Jendouba
      PharmacyModel(
        id: 'ph-43',
        cnopId: 'CNOP-JN-2010',
        name: 'Pharmacie Jendouba Centre',
        governorate: 'Jendouba',
        municipality: 'Jendouba Ville',
        address: 'Boulevard de l\'Environnement, Jendouba',
        phoneLandline: '+216 78 600 110',
        latitude: 36.5011,
        longitude: 8.7803,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-44',
        cnopId: 'CNOP-JN-2020',
        name: 'Pharmacie Ain Draham',
        governorate: 'Jendouba',
        municipality: 'Ain Draham',
        address: 'Route de Babouch, Ain Draham',
        phoneLandline: '+216 78 655 200',
        latitude: 36.7800,
        longitude: 8.6870,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),

      // Le Kef
      PharmacyModel(
        id: 'ph-45',
        cnopId: 'CNOP-KF-2010',
        name: 'Pharmacie Dahmani',
        governorate: 'Le Kef',
        municipality: 'Dahmani',
        address: 'Avenue Habib Bourguiba, Dahmani',
        phoneLandline: '+216 78 260 400',
        latitude: 35.9400,
        longitude: 8.8300,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),

      // Siliana
      PharmacyModel(
        id: 'ph-46',
        cnopId: 'CNOP-SL-2010',
        name: 'Pharmacie Makthar',
        governorate: 'Siliana',
        municipality: 'Makthar',
        address: 'Avenue de la République, Makthar',
        phoneLandline: '+216 78 890 100',
        latitude: 35.8580,
        longitude: 9.2060,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),

      // Sousse
      PharmacyModel(
        id: 'ph-47',
        cnopId: 'CNOP-SO-3010',
        name: 'Pharmacie Ribat Sousse',
        governorate: 'Sousse',
        municipality: 'Sousse Médina',
        address: 'Avenue Habib Bourguiba, Sousse Centre',
        phoneLandline: '+216 73 225 600',
        latitude: 35.8280,
        longitude: 10.6380,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-48',
        cnopId: 'CNOP-SO-3020',
        name: 'Pharmacie Port El Kantaoui',
        governorate: 'Sousse',
        municipality: 'Hammam Sousse',
        address: 'Zone Touristique El Kantaoui',
        phoneLandline: '+216 73 348 200',
        latitude: 35.8940,
        longitude: 10.5980,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-49',
        cnopId: 'CNOP-SO-3030',
        name: 'Pharmacie Sahloul',
        governorate: 'Sousse',
        municipality: 'Sahloul',
        address: 'Route Ceinture Sahloul, Sousse',
        phoneLandline: '+216 73 369 400',
        latitude: 35.8450,
        longitude: 10.5920,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),

      // Monastir
      PharmacyModel(
        id: 'ph-50',
        cnopId: 'CNOP-MO-3020',
        name: 'Pharmacie Marina Monastir',
        governorate: 'Monastir',
        municipality: 'Monastir Ville',
        address: 'Port de Plaisance Marina, Monastir',
        phoneLandline: '+216 73 462 800',
        latitude: 35.7740,
        longitude: 10.8350,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-51',
        cnopId: 'CNOP-MO-3030',
        name: 'Pharmacie Sahline',
        governorate: 'Monastir',
        municipality: 'Sahline',
        address: 'Avenue Habib Bourguiba, Sahline',
        phoneLandline: '+216 73 525 100',
        latitude: 35.7520,
        longitude: 10.7100,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),

      // Mahdia
      PharmacyModel(
        id: 'ph-52',
        cnopId: 'CNOP-MH-2010',
        name: 'Pharmacie Ksour Essef',
        governorate: 'Mahdia',
        municipality: 'Ksour Essef',
        address: 'Avenue de l\'Indépendance, Ksour Essef',
        phoneLandline: '+216 73 660 200',
        latitude: 35.4200,
        longitude: 10.9800,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),

      // Sfax
      PharmacyModel(
        id: 'ph-53',
        cnopId: 'CNOP-SF-3010',
        name: 'Pharmacie du Port de Sfax',
        governorate: 'Sfax',
        municipality: 'Sfax Ville',
        address: 'Avenue Hédi Chaker, Sfax Port',
        phoneLandline: '+216 74 220 880',
        latitude: 34.7390,
        longitude: 10.7640,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-54',
        cnopId: 'CNOP-SF-3020',
        name: 'Pharmacie Sakiet Ezzit',
        governorate: 'Sfax',
        municipality: 'Sakiet Ezzit',
        address: 'Route de Tunis km 6, Sakiet Ezzit',
        phoneLandline: '+216 74 250 300',
        latitude: 34.8000,
        longitude: 10.7700,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-55',
        cnopId: 'CNOP-SF-3030',
        name: 'Pharmacie Sfax Bab Diwan',
        governorate: 'Sfax',
        municipality: 'Sfax Médina',
        address: 'Place Bab Diwan, Sfax Médina',
        phoneLandline: '+216 74 298 100',
        latitude: 34.7350,
        longitude: 10.7610,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),

      // Kairouan
      PharmacyModel(
        id: 'ph-56',
        cnopId: 'CNOP-KR-2010',
        name: 'Pharmacie Bab El Jalladine',
        governorate: 'Kairouan',
        municipality: 'Kairouan Sud',
        address: 'Rue Ali Belhouane, Bab El Jalladine',
        phoneLandline: '+216 77 228 150',
        latitude: 35.6720,
        longitude: 10.1010,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),

      // Kasserine
      PharmacyModel(
        id: 'ph-57',
        cnopId: 'CNOP-KS-2010',
        name: 'Pharmacie Sbeitla Antique',
        governorate: 'Kasserine',
        municipality: 'Sbeitla',
        address: 'Avenue de l\'Indépendance, Sbeitla',
        phoneLandline: '+216 77 465 100',
        latitude: 35.2300,
        longitude: 9.1200,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),

      // Sidi Bouzid
      PharmacyModel(
        id: 'ph-58',
        cnopId: 'CNOP-SB-2010',
        name: 'Pharmacie Regueb',
        governorate: 'Sidi Bouzid',
        municipality: 'Regueb',
        address: 'Avenue Habib Bourguiba, Regueb',
        phoneLandline: '+216 76 680 100',
        latitude: 34.8600,
        longitude: 9.7900,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),

      // Gabès
      PharmacyModel(
        id: 'ph-59',
        cnopId: 'CNOP-GA-2010',
        name: 'Pharmacie Bab Bhar Gabès',
        governorate: 'Gabès',
        municipality: 'Gabès Médina',
        address: 'Avenue Habib Bourguiba, Bab Bhar',
        phoneLandline: '+216 75 274 500',
        latitude: 33.8860,
        longitude: 10.1050,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),

      // Medenine / Djerba / Zarzis
      PharmacyModel(
        id: 'ph-60',
        cnopId: 'CNOP-ME-2010',
        name: 'Pharmacie Zarzis Plage',
        governorate: 'Medenine',
        municipality: 'Zarzis',
        address: 'Route Touristique Souihel, Zarzis',
        phoneLandline: '+216 75 683 400',
        latitude: 33.5050,
        longitude: 11.1150,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-61',
        cnopId: 'CNOP-ME-2020',
        name: 'Pharmacie Medenine Ville',
        governorate: 'Medenine',
        municipality: 'Medenine Centre',
        address: 'Avenue 14 Janvier, Medenine',
        phoneLandline: '+216 75 640 150',
        latitude: 33.3549,
        longitude: 10.5055,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),
      PharmacyModel(
        id: 'ph-62',
        cnopId: 'CNOP-ME-2030',
        name: 'Pharmacie Djerba Midoun',
        governorate: 'Medenine',
        municipality: 'Djerba Midoun',
        address: 'Place du Marché, Midoun, Djerba',
        phoneLandline: '+216 75 730 800',
        latitude: 33.8080,
        longitude: 10.9920,
        acceptsCnam: true,
        isGarde: false,
        status: 'APPROVED',
      ),

      // Tataouine
      PharmacyModel(
        id: 'ph-63',
        cnopId: 'CNOP-TT-2010',
        name: 'Pharmacie Ghomrassen',
        governorate: 'Tataouine',
        municipality: 'Ghomrassen',
        address: 'Avenue Habib Bourguiba, Ghomrassen',
        phoneLandline: '+216 75 870 250',
        latitude: 33.0560,
        longitude: 10.3340,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),

      // Gafsa
      PharmacyModel(
        id: 'ph-64',
        cnopId: 'CNOP-GF-2010',
        name: 'Pharmacie Métlaoui Centre',
        governorate: 'Gafsa',
        municipality: 'Métlaoui',
        address: 'Avenue Farhat Hached, Métlaoui',
        phoneLandline: '+216 76 240 100',
        latitude: 34.3330,
        longitude: 8.4000,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),

      // Tozeur
      PharmacyModel(
        id: 'ph-65',
        cnopId: 'CNOP-TZ-2010',
        name: 'Pharmacie Nefta Oasis',
        governorate: 'Tozeur',
        municipality: 'Nefta',
        address: 'Avenue Habib Bourguiba, Nefta',
        phoneLandline: '+216 76 430 200',
        latitude: 33.8730,
        longitude: 7.8780,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),

      // Kebili
      PharmacyModel(
        id: 'ph-66',
        cnopId: 'CNOP-KB-2010',
        name: 'Pharmacie Douz Sahara',
        governorate: 'Kebili',
        municipality: 'Douz',
        address: 'Place du Festival, Douz',
        phoneLandline: '+216 75 470 300',
        latitude: 33.4660,
        longitude: 9.0200,
        acceptsCnam: true,
        isGarde: true,
        status: 'APPROVED',
      ),
    ]);

    // 3. Populate Inventory for All Pharmacies
    for (var pharmacy in _pharmacies) {
      for (var drug in _masterDrugs) {
        if (!drug.isBlacklisted) {
          _inventories.add(InventoryModel(
            id: 'inv-${pharmacy.id}-${drug.id}',
            pharmacyId: pharmacy.id,
            drugId: drug.id,
            quantity: 10 + Random().nextInt(40),
            lastUpdatedAt: DateTime.now().subtract(Duration(minutes: Random().nextInt(120))),
          ));
        }
      }
    }

    // 4. Populate CNOP Garde Roster Shifts
    final today = DateTime.now();
    _gardeShifts.addAll([
      GardeShiftModel(
        id: 'shift-1',
        pharmacyId: 'ph-1',
        pharmacyName: 'Pharmacie Principale El Menzah',
        governorate: 'Tunis',
        shiftDate: today,
        shiftType: GardeType.NUIT,
        notes: 'Garde Officielle de Nuit CNOP (19:30 - 08:30)',
      ),
      GardeShiftModel(
        id: 'shift-2',
        pharmacyId: 'ph-2',
        pharmacyName: 'Pharmacie Central Habib Bourguiba',
        governorate: 'Ariana',
        shiftDate: today,
        shiftType: GardeType.NUIT,
        notes: 'Garde Officielle de Nuit CNOP (19:30 - 08:30)',
      ),
      GardeShiftModel(
        id: 'shift-3',
        pharmacyId: 'ph-3',
        pharmacyName: 'Pharmacie du Lac',
        governorate: 'Ariana',
        shiftDate: today.add(const Duration(days: 1)),
        shiftType: GardeType.DIMANCHE_FERIE,
        notes: 'Garde Dimanche / Jour Férié (24h)',
      ),
      GardeShiftModel(
        id: 'shift-4',
        pharmacyId: 'ph-4',
        pharmacyName: 'Pharmacie Ennasr',
        governorate: 'Sousse',
        shiftDate: today,
        shiftType: GardeType.NUIT,
        notes: 'Garde Officielle de Nuit CNOP (19:30 - 08:30)',
      ),
    ]);

    // 5. Populate Chronic Disease Reminders
    _chronicReminders.addAll([
      ChronicReminderModel(
        id: 'rem-1',
        patientPhone: '+216 22 123 456',
        drugId: 'd-2',
        drugName: 'Aprovel 150mg',
        dciName: 'Irbésartan (Hypertension)',
        pharmacyId: 'ph-1',
        pharmacyName: 'Pharmacie Principale El Menzah',
        cycleDays: 30,
        startDate: today.subtract(const Duration(days: 27)),
        nextRefillDate: today.add(const Duration(days: 3)),
      ),
      ChronicReminderModel(
        id: 'rem-2',
        patientPhone: '+216 22 123 456',
        drugId: 'd-3',
        drugName: 'Glucophage 1000mg',
        dciName: 'Metformine (Diabète)',
        pharmacyId: 'ph-2',
        pharmacyName: 'Pharmacie de Nuit Ennasr',
        cycleDays: 30,
        startDate: today.subtract(const Duration(days: 28)),
        nextRefillDate: today.add(const Duration(days: 2)),
      ),
    ]);

    // 6. Populate Family Profiles
    _familyProfiles.addAll([
      const FamilyProfileModel(
        id: 'fam-1',
        displayName: 'Moi (Titulaire)',
        relation: 'Moi',
        cnamAffiliation: 'Filière privée (Médecin de famille)',
        chronicMedicationIds: ['drug-3', 'drug-13'],
        notes: 'Renouvellement ordonnance tous les 3 mois (CNAM)',
      ),
      const FamilyProfileModel(
        id: 'fam-2',
        displayName: 'Fatma (Mère)',
        relation: 'Mère',
        cnamAffiliation: 'Filière publique',
        chronicMedicationIds: ['drug-24', 'drug-7'],
        notes: 'Suivi diabète type 2 et spasmes',
      ),
      const FamilyProfileModel(
        id: 'fam-3',
        displayName: 'Youssef (Enfant)',
        relation: 'Enfant',
        chronicMedicationIds: ['drug-2'],
        notes: 'Pédiatrie',
      ),
    ]);
  }

  List<DrugModel> searchDrugs(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return _masterDrugs.where((d) => !d.isBlacklisted).toList();
    }

    return _masterDrugs.where((d) {
      if (d.isBlacklisted) return false;
      if (d.brandName.toLowerCase().contains(q) ||
          d.dciName.toLowerCase().contains(q) ||
          d.arabicName.toLowerCase().contains(q) ||
          d.pctCode.toLowerCase().contains(q) ||
          d.category.toLowerCase().contains(q) ||
          d.aliases.any((alias) => alias.toLowerCase().contains(q))) {
        return true;
      }
      return FuzzySearch.similarityScore(q, d.brandName) > 0.35 ||
          FuzzySearch.similarityScore(q, d.dciName) > 0.35 ||
          FuzzySearch.similarityScore(q, d.arabicName) > 0.35;
    }).toList();
  }

  List<DrugModel> filterDrugsByCategory(String category) {
    if (category == 'Tous' || category.isEmpty) {
      return _masterDrugs.where((d) => !d.isBlacklisted).toList();
    }
    return _masterDrugs.where((d) => !d.isBlacklisted && d.category.toLowerCase().contains(category.toLowerCase())).toList();
  }

  List<PharmacyModel> findNearbyPharmaciesWithStock({
    required String drugId,
    required double lat,
    required double lng,
    double radiusKm = 15.0,
    bool requiresCnam = false,
    bool onlyGarde = false,
  }) {
    List<PharmacyModel> results = [];

    for (var pharmacy in _pharmacies) {
      if (pharmacy.status != 'APPROVED') continue;
      if (requiresCnam && !pharmacy.acceptsCnam) continue;
      if (onlyGarde && !pharmacy.isGarde) continue;

      bool hasStock = _inventories.any((inv) =>
          inv.pharmacyId == pharmacy.id && inv.drugId == drugId && inv.quantity > 0);

      if (hasStock) {
        double dist = _calculateDistance(lat, lng, pharmacy.latitude, pharmacy.longitude);
        if (dist <= radiusKm) {
          results.add(PharmacyModel(
            id: pharmacy.id,
            cnopId: pharmacy.cnopId,
            name: pharmacy.name,
            governorate: pharmacy.governorate,
            municipality: pharmacy.municipality,
            address: pharmacy.address,
            phoneLandline: pharmacy.phoneLandline,
            latitude: pharmacy.latitude,
            longitude: pharmacy.longitude,
            acceptsCnam: pharmacy.acceptsCnam,
            isGarde: pharmacy.isGarde,
            status: pharmacy.status,
            distanceKm: dist,
          ));
        }
      }
    }

    results.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
    return results;
  }

  List<DrugModel> getGenericAlternatives(DrugModel targetDrug) {
    return _masterDrugs.where((d) =>
        d.id != targetDrug.id &&
        !d.isBlacklisted &&
        d.dciName.toLowerCase() == targetDrug.dciName.toLowerCase()
    ).toList();
  }

  Future<bool> createReservation({
    required String patientId,
    required String patientPhone,
    required String pharmacyId,
    required String drugId,
    String? prescriptionUrl,
  }) async {
    final activeHolds = _reservations.where((r) =>
        r.patientId == patientId && r.status == ReservationStatus.PENDING && !r.isExpired).length;

    if (activeHolds >= 2) {
      throw Exception('Limite atteinte: Vous ne pouvez pas avoir plus de 2 réservations actives simultanément.');
    }

    final drug = _masterDrugs.firstWhere((d) => d.id == drugId);
    final pharmacy = _pharmacies.firstWhere((p) => p.id == pharmacyId);

    final newReservation = ReservationModel(
      id: 'res-${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      patientPhone: patientPhone,
      pharmacyId: pharmacyId,
      drugId: drugId,
      prescriptionImageUrl: prescriptionUrl,
      status: ReservationStatus.PENDING,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 2)),
      drug: drug,
      pharmacy: pharmacy,
    );

    _reservations.insert(0, newReservation);

    try {
      await AudioService().playNotificationChime();
    } catch (_) {}

    notifyListeners();
    return true;
  }

  void updateReservationStatus(String resId, ReservationStatus newStatus) {
    int index = _reservations.indexWhere((r) => r.id == resId);
    if (index != -1) {
      final oldRes = _reservations[index];
      _reservations[index] = oldRes.copyWith(status: newStatus);

      // Trigger instant SMS notification when reservation is confirmed
      if (newStatus == ReservationStatus.CONFIRMED) {
        int hash = oldRes.id.hashCode.abs() % 900000 + 100000;
        String counterCode = 'PG-$hash';
        SmsService().sendReservationConfirmedSms(
          phoneNumber: oldRes.patientPhone,
          pharmacyName: oldRes.pharmacy?.name ?? 'Pharmacie',
          drugName: oldRes.drug?.brandName ?? 'Médicament',
          counterCode: counterCode,
        );
      } else if (newStatus == ReservationStatus.DECLINED || newStatus == ReservationStatus.EXPIRED) {
        // Restore stock for the pharmacy (+1 box)
        final invIndex = _inventories.indexWhere((i) => i.pharmacyId == oldRes.pharmacyId && i.drugId == oldRes.drugId);
        if (invIndex != -1) {
          updateStockQuantity(oldRes.pharmacyId, oldRes.drugId, _inventories[invIndex].quantity + 1);
        }
      }

      notifyListeners();
    }
  }

  void updateStockQuantity(String pharmacyId, String drugId, int newQuantity) {
    int index = _inventories.indexWhere((i) => i.pharmacyId == pharmacyId && i.drugId == drugId);
    if (index != -1) {
      int prevQty = _inventories[index].quantity;
      int updatedQty = (newQuantity < 0) ? max(0, prevQty + newQuantity) : newQuantity;

      _inventories[index] = InventoryModel(
        id: _inventories[index].id,
        pharmacyId: pharmacyId,
        drugId: drugId,
        quantity: updatedQty,
        lastUpdatedAt: DateTime.now(),
      );

      // Trigger Availability SMS Alert if stock restocked (>0)
      if (prevQty == 0 && updatedQty > 0) {
        final drug = _masterDrugs.firstWhere((d) => d.id == drugId);
        final pharmacy = _pharmacies.firstWhere((p) => p.id == pharmacyId);
        final alerts = _availabilityAlerts.where((a) => a.drugId == drugId && !a.isNotified).toList();

        for (var alert in alerts) {
          SmsService().sendAvailabilityAlertSms(
            phoneNumber: alert.patientPhone,
            drugName: drug.brandName,
            pharmacyName: pharmacy.name,
          );
          alert.isNotified = true;
        }
      }

      notifyListeners();
    } else {
      _inventories.add(InventoryModel(
        id: 'inv-$pharmacyId-$drugId',
        pharmacyId: pharmacyId,
        drugId: drugId,
        quantity: newQuantity,
        lastUpdatedAt: DateTime.now(),
      ));
      notifyListeners();
    }
  }

  void approvePharmacy(String id) {
    int index = _pharmacies.indexWhere((p) => p.id == id);
    if (index != -1) {
      _pharmacies[index] = _pharmacies[index].copyWith(status: 'APPROVED');
      notifyListeners();
    }
  }

  void toggleDrugBlacklist(String id) {
    int index = _masterDrugs.indexWhere((d) => d.id == id);
    if (index != -1) {
      _masterDrugs[index] = _masterDrugs[index].copyWith(
        isBlacklisted: !_masterDrugs[index].isBlacklisted,
      );
      notifyListeners();
    }
  }

  void createB2BRequest({
    required String requestingPharmacyId,
    required String targetPharmacyId,
    required String drugId,
    required int quantity,
    String? notes,
  }) {
    final req = B2BRequestModel(
      id: 'b2b-${DateTime.now().millisecondsSinceEpoch}',
      requestingPharmacyId: requestingPharmacyId,
      targetPharmacyId: targetPharmacyId,
      drugId: drugId,
      quantity: quantity,
      status: B2BRequestStatus.PENDING,
      notes: notes,
      createdAt: DateTime.now(),
    );
    _b2bRequests.insert(0, req);
    notifyListeners();
  }

  void updateB2BRequestStatus(String requestId, B2BRequestStatus newStatus) {
    final index = _b2bRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final old = _b2bRequests[index];
      _b2bRequests[index] = B2BRequestModel(
        id: old.id,
        requestingPharmacyId: old.requestingPharmacyId,
        targetPharmacyId: old.targetPharmacyId,
        drugId: old.drugId,
        quantity: old.quantity,
        status: newStatus,
        notes: old.notes,
        createdAt: old.createdAt,
        requestingPharmacy: old.requestingPharmacy,
        targetPharmacy: old.targetPharmacy,
        drug: old.drug,
      );
      notifyListeners();
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  /// Find generic alternative medications with same active ingredient (DCI)
  List<DrugModel> findGenericAlternatives(String drugId) {
    final target = _masterDrugs.firstWhere(
      (d) => d.id == drugId,
      orElse: () => _masterDrugs.first,
    );
    return _masterDrugs
        .where((d) => d.id != drugId && (d.dciName.toLowerCase() == target.dciName.toLowerCase() || target.substituteIds.contains(d.id)))
        .toList();
  }

  /// Get inventory items for a specific pharmacy
  List<InventoryModel> getPharmacyStock(String pharmacyId) {
    return _inventories.where((i) => i.pharmacyId == pharmacyId).toList();
  }

  // ──────────────────────────────────────────────
  // PILLAR 1: MULTI-DRUG PRESCRIPTION BASKET OPTIMIZER
  // ──────────────────────────────────────────────

  /// Finds optimal single-stop and 2-stop split pharmacy itineraries for a multi-drug prescription basket
  BasketOptimizationResult findOptimalPharmaciesForBasket(
    List<String> drugIds, {
    double? latitude,
    double? longitude,
  }) {
    if (drugIds.isEmpty) {
      return const BasketOptimizationResult(
        singleStopOptions: [],
        splitStopOptions: [],
        totalRequestedDrugs: 0,
      );
    }

    final lat = latitude ?? userLat;
    final lng = longitude ?? userLng;

    // 1. Build stock map: pharmacyId -> set of available drugIds
    final Map<String, Set<String>> pharmacyStockMap = {};
    for (var inv in _inventories) {
      if (drugIds.contains(inv.drugId) && inv.isAvailable) {
        pharmacyStockMap.putIfAbsent(inv.pharmacyId, () => <String>{}).add(inv.drugId);
      }
    }

    final List<SingleStopResult> singleStopResults = [];
    final approvedPharmacies = _pharmacies.where((p) => p.status == 'APPROVED').toList();

    for (var pharmacy in approvedPharmacies) {
      final available = pharmacyStockMap[pharmacy.id] ?? <String>{};
      if (available.isEmpty) continue;

      final distance = _calculateDistance(lat, lng, pharmacy.latitude, pharmacy.longitude);
      final missing = drugIds.where((id) => !available.contains(id)).toList();
      final fulfillment = available.length / drugIds.length;

      singleStopResults.add(SingleStopResult(
        pharmacy: pharmacy,
        distanceKm: distance,
        availableDrugIds: available.toList(),
        missingDrugIds: missing,
        fulfillmentRate: fulfillment,
      ));
    }

    // Sort single-stop: full 100% matches first, then by shortest distance
    singleStopResults.sort((a, b) {
      if (a.isFullMatch && !b.isFullMatch) return -1;
      if (!a.isFullMatch && b.isFullMatch) return 1;
      if (a.fulfillmentRate != b.fulfillmentRate) {
        return b.fulfillmentRate.compareTo(a.fulfillmentRate);
      }
      return a.distanceKm.compareTo(b.distanceKm);
    });

    // 2. Compute 2-stop split combinations
    final List<SplitStopResult> splitStopResults = [];
    final candidatePharmacies = singleStopResults.take(15).toList();

    for (int i = 0; i < candidatePharmacies.length; i++) {
      for (int j = i + 1; j < candidatePharmacies.length; j++) {
        final optA = candidatePharmacies[i];
        final optB = candidatePharmacies[j];

        final combinedDrugs = {...optA.availableDrugIds, ...optB.availableDrugIds};
        final combinedRate = combinedDrugs.length / drugIds.length;

        // Only keep if the combination covers more than each individual pharmacy
        if (combinedRate > optA.fulfillmentRate && combinedRate > optB.fulfillmentRate) {
          final distUserToA = optA.distanceKm;
          final distAToB = _calculateDistance(
            optA.pharmacy.latitude,
            optA.pharmacy.longitude,
            optB.pharmacy.latitude,
            optB.pharmacy.longitude,
          );
          final totalDist = distUserToA + distAToB;

          final onlyInA = optA.availableDrugIds.toList();
          final onlyInB = optB.availableDrugIds
              .where((id) => !optA.availableDrugIds.contains(id))
              .toList();

          splitStopResults.add(SplitStopResult(
            pharmacyA: optA.pharmacy,
            pharmacyB: optB.pharmacy,
            pharmacyADrugIds: onlyInA,
            pharmacyBDrugIds: onlyInB,
            distanceToA: distUserToA,
            distanceAToB: distAToB,
            totalDistanceKm: totalDist,
            combinedFulfillmentRate: combinedRate,
          ));
        }
      }
    }

    // Sort split combinations: full coverage first, then minimal total travel distance
    splitStopResults.sort((a, b) {
      if (a.isFullMatch && !b.isFullMatch) return -1;
      if (!a.isFullMatch && b.isFullMatch) return 1;
      return a.totalDistanceKm.compareTo(b.totalDistanceKm);
    });

    return BasketOptimizationResult(
      singleStopOptions: singleStopResults,
      splitStopOptions: splitStopResults.take(8).toList(),
      totalRequestedDrugs: drugIds.length,
    );
  }

  // ──────────────────────────────────────────────
  // PILLAR 2: GENERIC SUBSTITUTION ENGINE
  // ──────────────────────────────────────────────

  /// Finds identical DCI or approved therapeutic substitutes with live stock availability
  List<GenericSubstituteResult> getGenericSubstitutes(
    DrugModel drug, {
    double? userLat,
    double? userLng,
  }) {
    final lat = userLat ?? this.userLat;
    final lng = userLng ?? this.userLng;

    final substitutes = _masterDrugs.where((d) {
      if (d.id == drug.id) return false;
      final sameDci = d.dciName.trim().toLowerCase() == drug.dciName.trim().toLowerCase();
      final isLinked = drug.substituteIds.contains(d.id) || d.substituteIds.contains(drug.id);
      return sameDci || isLinked;
    }).toList();

    final List<GenericSubstituteResult> results = [];

    for (var sub in substitutes) {
      final inStockPharmaIds = _inventories
          .where((inv) => inv.drugId == sub.id && inv.isAvailable)
          .map((inv) => inv.pharmacyId)
          .toSet();

      PharmacyModel? nearest;
      double? nearestDist;

      for (var phId in inStockPharmaIds) {
        final ph = _pharmacies.firstWhere((p) => p.id == phId, orElse: () => _pharmacies.first);
        final dist = _calculateDistance(lat, lng, ph.latitude, ph.longitude);
        if (nearestDist == null || dist < nearestDist) {
          nearestDist = dist;
          nearest = ph;
        }
      }

      results.add(GenericSubstituteResult(
        substituteDrugId: sub.id,
        substituteBrandName: sub.brandName,
        dciName: sub.dciName,
        dosage: sub.dosage,
        form: sub.form,
        totalPharmaciesInStock: inStockPharmaIds.length,
        nearestPharmacy: nearest,
        nearestDistanceKm: nearestDist,
      ));
    }

    results.sort((a, b) => (a.nearestDistanceKm ?? 999).compareTo(b.nearestDistanceKm ?? 999));
    return results;
  }

  // ──────────────────────────────────────────────
  // PILLAR 6: PACKAGING BARCODE RESOLVER
  // ──────────────────────────────────────────────

  /// Resolves an EAN-13 or Datamatrix barcode to a drug in the national catalog
  DrugModel? findDrugByBarcode(String barcode) {
    final clean = barcode.trim();
    try {
      return _masterDrugs.firstWhere(
        (d) => d.barcode != null && d.barcode == clean,
      );
    } catch (_) {
      try {
        return _masterDrugs.firstWhere(
          (d) => d.pctCode.replaceAll(RegExp(r'[^0-9]'), '') == clean,
        );
      } catch (_) {
        return null;
      }
    }
  }

  // ──────────────────────────────────────────────
  // MULTI-DRUG HOLD RESERVATION (2-Hour Counter Hold)
  // ──────────────────────────────────────────────

  Future<List<ReservationModel>> createMultiDrugReservation({
    required String pharmacyId,
    required List<String> drugIds,
    required String patientId,
    required String patientPhone,
  }) async {
    final List<ReservationModel> created = [];
    final pharmacy = _pharmacies.firstWhere((p) => p.id == pharmacyId);

    for (var drugId in drugIds) {
      final drug = _masterDrugs.firstWhere((d) => d.id == drugId);
      final res = ReservationModel(
        id: 'res-${DateTime.now().millisecondsSinceEpoch}-$drugId',
        patientId: patientId,
        patientPhone: patientPhone,
        pharmacyId: pharmacyId,
        drugId: drugId,
        status: ReservationStatus.PENDING,
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
        createdAt: DateTime.now(),
        pharmacy: pharmacy,
        drug: drug,
      );

      _reservations.insert(0, res);
      created.add(res);

      // Decrement stock quantity by 1
      updateStockQuantity(pharmacyId, drugId, -1);
    }

    try {
      await AudioService().playNotificationChime();
    } catch (_) {}

    notifyListeners();
    return created;
  }
}
