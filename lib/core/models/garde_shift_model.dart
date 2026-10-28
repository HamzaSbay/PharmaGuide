enum GardeType { nuit, dimancheFerie, jour }

class GardeShiftModel {
  final String id;
  final String pharmacyId;
  final String pharmacyName;
  final String governorate;
  final DateTime shiftDate;
  final GardeType shiftType;
  final String notes;

  GardeShiftModel({
    required this.id,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.governorate,
    required this.shiftDate,
    this.shiftType = GardeType.nuit,
    this.notes = 'Garde Officielle CNOP',
  });

  factory GardeShiftModel.fromJson(Map<String, dynamic> json) {
    return GardeShiftModel(
      id: json['id'] ?? '',
      pharmacyId: json['pharmacy_id'] ?? '',
      pharmacyName: json['pharmacy_name'] ?? '',
      governorate: json['governorate'] ?? '',
      shiftDate: DateTime.tryParse(json['shift_date'] ?? '') ?? DateTime.now(),
      shiftType: _parseShiftType(json['shift_type']?.toString()),
      notes: json['notes'] ?? 'Garde Officielle CNOP',
    );
  }

  static GardeType _parseShiftType(String? str) {
    final s = (str ?? '').toUpperCase();
    if (s.contains('DIMANCHE') || s.contains('FERIE')) return GardeType.dimancheFerie;
    if (s.contains('JOUR')) return GardeType.jour;
    return GardeType.nuit;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pharmacy_id': pharmacyId,
      'pharmacy_name': pharmacyName,
      'governorate': governorate,
      'shift_date': shiftDate.toIso8601String(),
      'shift_type': shiftType == GardeType.dimancheFerie ? 'DIMANCHE_FERIE' : (shiftType == GardeType.jour ? 'JOUR' : 'NUIT'),
      'notes': notes,
    };
  }
}
