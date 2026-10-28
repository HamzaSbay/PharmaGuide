enum GardeType { NUIT, DIMANCHE_FERIE, JOUR }

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
    this.shiftType = GardeType.NUIT,
    this.notes = 'Garde Officielle CNOP',
  });

  factory GardeShiftModel.fromJson(Map<String, dynamic> json) {
    return GardeShiftModel(
      id: json['id'] ?? '',
      pharmacyId: json['pharmacy_id'] ?? '',
      pharmacyName: json['pharmacy_name'] ?? '',
      governorate: json['governorate'] ?? '',
      shiftDate: DateTime.tryParse(json['shift_date'] ?? '') ?? DateTime.now(),
      shiftType: GardeType.values.firstWhere(
        (e) => e.name == json['shift_type'],
        orElse: () => GardeType.NUIT,
      ),
      notes: json['notes'] ?? 'Garde Officielle CNOP',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pharmacy_id': pharmacyId,
      'pharmacy_name': pharmacyName,
      'governorate': governorate,
      'shift_date': shiftDate.toIso8601String(),
      'shift_type': shiftType.name,
      'notes': notes,
    };
  }
}
