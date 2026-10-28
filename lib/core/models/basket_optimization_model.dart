import 'pharmacy_model.dart';

class SingleStopResult {
  final PharmacyModel pharmacy;
  final double distanceKm;
  final List<String> availableDrugIds;
  final List<String> missingDrugIds;
  final double fulfillmentRate; // 1.0 = 100%

  const SingleStopResult({
    required this.pharmacy,
    required this.distanceKm,
    required this.availableDrugIds,
    this.missingDrugIds = const [],
    required this.fulfillmentRate,
  });

  bool get isFullMatch => fulfillmentRate >= 1.0;
}

class SplitStopResult {
  final PharmacyModel pharmacyA;
  final PharmacyModel pharmacyB;
  final List<String> pharmacyADrugIds;
  final List<String> pharmacyBDrugIds;
  final double distanceToA;
  final double distanceAToB;
  final double totalDistanceKm;
  final double combinedFulfillmentRate;

  const SplitStopResult({
    required this.pharmacyA,
    required this.pharmacyB,
    required this.pharmacyADrugIds,
    required this.pharmacyBDrugIds,
    required this.distanceToA,
    required this.distanceAToB,
    required this.totalDistanceKm,
    required this.combinedFulfillmentRate,
  });

  bool get isFullMatch => combinedFulfillmentRate >= 1.0;
}

class BasketOptimizationResult {
  final List<SingleStopResult> singleStopOptions;
  final List<SplitStopResult> splitStopOptions;
  final int totalRequestedDrugs;

  const BasketOptimizationResult({
    required this.singleStopOptions,
    required this.splitStopOptions,
    required this.totalRequestedDrugs,
  });

  bool get hasSingleStopSolution =>
      singleStopOptions.any((opt) => opt.isFullMatch);
}

class GenericSubstituteResult {
  final String substituteDrugId;
  final String substituteBrandName;
  final String dciName;
  final String dosage;
  final String form;
  final int totalPharmaciesInStock;
  final PharmacyModel? nearestPharmacy;
  final double? nearestDistanceKm;

  const GenericSubstituteResult({
    required this.substituteDrugId,
    required this.substituteBrandName,
    required this.dciName,
    required this.dosage,
    required this.form,
    required this.totalPharmaciesInStock,
    this.nearestPharmacy,
    this.nearestDistanceKm,
  });
}
