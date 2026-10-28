import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmaguide_tn/main.dart';
import 'package:pharmaguide_tn/core/models/b2b_request_model.dart';
import 'package:pharmaguide_tn/core/models/family_profile_model.dart';
import 'package:pharmaguide_tn/core/models/reservation_model.dart';
import 'package:pharmaguide_tn/core/services/mock_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('B2B Request update status method modifies status to APPROVED or REJECTED', () {
    final mockService = MockDataService();
    mockService.createB2BRequest(
      requestingPharmacyId: 'ph-1',
      targetPharmacyId: 'ph-2',
      drugId: 'drug-1',
      quantity: 5,
      notes: 'Transfert urgent 5 boîtes',
    );

    final latestReq = mockService.b2bRequests.first;
    expect(latestReq.status, equals(B2BRequestStatus.pending));
    expect(latestReq.quantity, equals(5));

    // Approve the request
    mockService.updateB2BRequestStatus(latestReq.id, B2BRequestStatus.approved);
    final approvedReq = mockService.b2bRequests.firstWhere((r) => r.id == latestReq.id);
    expect(approvedReq.status, equals(B2BRequestStatus.approved));

    // Reject the request
    mockService.updateB2BRequestStatus(latestReq.id, B2BRequestStatus.rejected);
    final rejectedReq = mockService.b2bRequests.firstWhere((r) => r.id == latestReq.id);
    expect(rejectedReq.status, equals(B2BRequestStatus.rejected));
  });

  test('Reservation cancellation or decline restores stock in inventory', () async {
    final mockService = MockDataService();
    const pharmacyId = 'ph-1';
    const drugId = 'drug-1';

    // Ensure inventory exists and record quantity
    mockService.updateStockQuantity(pharmacyId, drugId, 10);
    final initialQty = mockService.inventories
        .firstWhere((i) => i.pharmacyId == pharmacyId && i.drugId == drugId)
        .quantity;

    // Create reservation (which decrements stock by 1)
    final resList = await mockService.createMultiDrugReservation(
      patientId: 'patient-test-cancel',
      patientPhone: '+216 55 999 888',
      pharmacyId: pharmacyId,
      drugIds: [drugId],
    );

    expect(resList, isNotEmpty);
    final res = resList.first;

    final decrementedQty = mockService.inventories
        .firstWhere((i) => i.pharmacyId == pharmacyId && i.drugId == drugId)
        .quantity;
    expect(decrementedQty, equals(initialQty - 1));

    // Cancel reservation (declined) restores the stock (+1)
    mockService.updateReservationStatus(res.id, ReservationStatus.declined);
    final restoredQty = mockService.inventories
        .firstWhere((i) => i.pharmacyId == pharmacyId && i.drugId == drugId)
        .quantity;
    expect(restoredQty, equals(initialQty));
  });

  test('Theme and Locale notifiers switch modes and languages dynamically', () {
    // Theme notifier
    PharmaGuideApp.themeNotifier.value = ThemeMode.dark;
    expect(PharmaGuideApp.themeNotifier.value, equals(ThemeMode.dark));

    PharmaGuideApp.themeNotifier.value = ThemeMode.light;
    expect(PharmaGuideApp.themeNotifier.value, equals(ThemeMode.light));

    // Locale notifier
    PharmaGuideApp.localeNotifier.value = const Locale('ar');
    expect(PharmaGuideApp.localeNotifier.value.languageCode, equals('ar'));

    PharmaGuideApp.localeNotifier.value = const Locale('fr');
    expect(PharmaGuideApp.localeNotifier.value.languageCode, equals('fr'));
  });

  test('Family Profile supports pediatric and chronic notes with validation attributes', () {
    final mockService = MockDataService();
    final profile = FamilyProfileModel(
      id: 'fam-test-${DateTime.now().millisecondsSinceEpoch}',
      displayName: 'Youssef Ben Salah',
      relation: 'Enfant',
      cnamAffiliation: 'Filière privée (Médecin de famille)',
      notes: '7 ans • 24.5 kg • Allergie Pénicilline',
    );

    mockService.addFamilyProfile(profile);

    final stored = mockService.familyProfiles.firstWhere((p) => p.id == profile.id);
    expect(stored.displayName, equals('Youssef Ben Salah'));
    expect(stored.notes, contains('24.5 kg'));
    expect(stored.notes, contains('Allergie Pénicilline'));

    // Remove profile
    mockService.removeFamilyProfile(profile.id);
    expect(mockService.familyProfiles.any((p) => p.id == profile.id), isFalse);
  });
}
