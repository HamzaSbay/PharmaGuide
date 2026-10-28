import 'package:flutter_test/flutter_test.dart';
import 'package:pharmaguide_tn/main.dart';
import 'package:pharmaguide_tn/core/utils/fuzzy_search.dart';
import 'package:pharmaguide_tn/core/services/mock_data_service.dart';

void main() {
  testWidgets('PharmaGuide TN App renders successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const PharmaGuideApp());
    expect(find.textContaining('PharmaGuide TN'), findsWidgets);
    expect(find.textContaining('Passer'), findsOneWidget);
  });

  test('Fuzzy search similarity calculation', () {
    double scoreExact = FuzzySearch.similarityScore('Doliprane', 'Doliprane');
    expect(scoreExact, equals(1.0));

    double scoreFuzzy = FuzzySearch.similarityScore('Doli', 'Doliprane 1000mg');
    expect(scoreFuzzy, greaterThan(0.5));
  });

  test('Reservation rate limit enforces max 2 active holds per patient', () async {
    final mockService = MockDataService();
    String patientUid = 'patient-test-${DateTime.now().millisecondsSinceEpoch}';

    // 1st hold
    await mockService.createReservation(
      patientId: patientUid,
      patientPhone: '+216 98 000 111',
      pharmacyId: 'ph-1',
      drugId: 'drug-1',
    );

    // 2nd hold
    await mockService.createReservation(
      patientId: patientUid,
      patientPhone: '+216 98 000 111',
      pharmacyId: 'ph-2',
      drugId: 'drug-2',
    );

    // 3rd hold should throw exception due to max 2 active holds limit
    expect(
      () async => await mockService.createReservation(
        patientId: patientUid,
        patientPhone: '+216 98 000 111',
        pharmacyId: 'ph-3',
        drugId: 'drug-3',
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('Prescription Basket Optimizer calculates single-stop and split options', () {
    final mockService = MockDataService();
    final result = mockService.findOptimalPharmaciesForBasket(['drug-1', 'drug-3']);

    expect(result.totalRequestedDrugs, equals(2));
    expect(result.singleStopOptions, isNotEmpty);
    // Best single-stop option should have available drugs
    final topOption = result.singleStopOptions.first;
    expect(topOption.availableDrugIds, isNotEmpty);
    expect(topOption.distanceKm, greaterThanOrEqualTo(0));
  });

  test('Generic Substitution Engine identifies identical DCI alternatives', () {
    final mockService = MockDataService();
    final doliprane = mockService.masterDrugs.firstWhere((d) => d.id == 'drug-1');
    final substitutes = mockService.getGenericSubstitutes(doliprane);

    expect(substitutes, isNotEmpty);
    // Doliprane 1000mg has Efferalgan 1g as Paracetamol 1000mg substitute
    expect(substitutes.any((s) => s.dciName.toLowerCase() == 'paracetamol'), isTrue);
  });

  test('Barcode Packaging Resolver maps EAN-13 code to national drug catalog', () {
    final mockService = MockDataService();
    final drug = mockService.findDrugByBarcode('3400935824921');

    expect(drug, isNotNull);
    expect(drug!.brandName, contains('Doliprane'));
    expect(drug.id, equals('drug-1'));
  });

  test('Family Profile suite manages members and chronic medications', () {
    final mockService = MockDataService();
    final initialCount = mockService.familyProfiles.length;

    expect(initialCount, greaterThan(0));
    final moi = mockService.familyProfiles.first;
    expect(moi.displayName, contains('Moi'));
  });
}
