import 'package:flutter_test/flutter_test.dart';
import 'package:pharmaguide_tn/core/models/family_profile_model.dart';
import 'package:pharmaguide_tn/core/models/reservation_model.dart';
import 'package:pharmaguide_tn/core/models/b2b_request_model.dart';
import 'package:pharmaguide_tn/core/repositories/repository_registry.dart';
import 'package:pharmaguide_tn/core/utils/result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    RepositoryRegistry.instance.init();
  });

  group('Result<T> Monad', () {
    test('Success holds value and reports isSuccess', () {
      const res = Success<int>(42);
      expect(res.isSuccess, isTrue);
      expect(res.isFailure, isFalse);
      expect(res.data, equals(42));
      expect(res.dataOrNull, equals(42));
      expect(res.errorOrNull, isNull);

      final transformed = res.when(
        success: (val) => 'Value: $val',
        failure: (msg, _) => 'Failed: $msg',
      );
      expect(transformed, equals('Value: 42'));
    });

    test('Failure holds message and reports isFailure', () {
      const res = Failure<int>('Network timeout');
      expect(res.isFailure, isTrue);
      expect(res.isSuccess, isFalse);
      expect(res.error, equals('Network timeout'));
      expect(res.errorOrNull, equals('Network timeout'));
      expect(res.dataOrNull, isNull);
      expect(() => res.data, throwsStateError);

      final transformed = res.when(
        success: (val) => 'Value: $val',
        failure: (msg, _) => 'Error: $msg',
      );
      expect(transformed, equals('Error: Network timeout'));
    });
  });

  group('RepositoryRegistry & Contracts', () {
    test('IDrugRepository searches drugs and resolves barcodes', () async {
      final repo = RepositoryRegistry.instance.drugs;
      expect(repo.masterDrugs, isNotEmpty);

      // Search
      final searchResults = await repo.searchDrugs('Doliprane');
      expect(searchResults, isNotEmpty);
      expect(searchResults.first.brandName, contains('Doliprane'));

      // Barcode lookup
      final drug = repo.findDrugByBarcode('3400935824921');
      expect(drug, isNotNull);
      expect(drug!.brandName, contains('Doliprane'));
    });

    test('IPharmacyRepository finds nearby pharmacies with stock', () async {
      final repo = RepositoryRegistry.instance.pharmacies;
      expect(repo.pharmacies, isNotEmpty);

      final nearby = await repo.findNearbyWithStock(
        drugId: 'drug-1',
        lat: 36.8368,
        lng: 10.1815,
        radiusKm: 20.0,
      );
      expect(nearby, isNotEmpty);
    });

    test('IReservationRepository creates reservation and returns Result<ReservationModel>', () async {
      final repo = RepositoryRegistry.instance.reservations;
      final uid = 'patient-repo-test-${DateTime.now().millisecondsSinceEpoch}';

      final result = await repo.createReservation(
        patientId: uid,
        patientPhone: '+216 98 777 666',
        pharmacyId: 'ph-1',
        drugId: 'drug-1',
      );

      expect(result.isSuccess, isTrue);
      final res = result.data;
      expect(res.status, equals(ReservationStatus.PENDING));
      expect(res.patientId, equals(uid));
    });

    test('IInventoryRepository queries and updates stock quantity', () async {
      final repo = RepositoryRegistry.instance.inventories;
      expect(repo.inventories, isNotEmpty);

      const phId = 'ph-1';
      const drugId = 'drug-1';

      await repo.updateStockQuantity(phId, drugId, 25);
      expect(repo.getStock(phId, drugId), equals(25));
    });

    test('IB2BRepository creates request and updates status', () async {
      final repo = RepositoryRegistry.instance.b2b;

      await repo.createB2BRequest(
        requestingPharmacyId: 'ph-1',
        targetPharmacyId: 'ph-2',
        drugId: 'drug-1',
        quantity: 3,
        notes: 'Dépannage d\'urgence',
      );

      final latest = repo.b2bRequests.first;
      expect(latest.quantity, equals(3));
      expect(latest.status, equals(B2BRequestStatus.PENDING));

      await repo.updateB2BRequestStatus(latest.id, B2BRequestStatus.APPROVED);
      final updated = repo.b2bRequests.firstWhere((r) => r.id == latest.id);
      expect(updated.status, equals(B2BRequestStatus.APPROVED));
    });

    test('IFamilyProfileRepository manages profiles', () async {
      final repo = RepositoryRegistry.instance.familyProfiles;
      final newProfile = FamilyProfileModel(
        id: 'fam-repo-test-${DateTime.now().millisecondsSinceEpoch}',
        displayName: 'Nadia Ben Ali',
        relation: 'Mère',
        cnamAffiliation: 'Filière publique',
      );

      await repo.addFamilyProfile(newProfile);
      expect(repo.familyProfiles.any((p) => p.id == newProfile.id), isTrue);

      await repo.removeFamilyProfile(newProfile.id);
      expect(repo.familyProfiles.any((p) => p.id == newProfile.id), isFalse);
    });
  });
}
