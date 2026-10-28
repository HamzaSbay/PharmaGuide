class AvailabilityAlert {
  final String id;
  final String patientPhone;
  final String drugId;
  final String drugName;
  final DateTime createdAt;
  bool isNotified;

  AvailabilityAlert({
    required this.id,
    required this.patientPhone,
    required this.drugId,
    required this.drugName,
    required this.createdAt,
    this.isNotified = false,
  });

  factory AvailabilityAlert.fromJson(Map<String, dynamic> json) {
    return AvailabilityAlert(
      id: json['id'] ?? '',
      patientPhone: json['patient_phone'] ?? '',
      drugId: json['drug_id'] ?? '',
      drugName: json['drug_name'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isNotified: json['is_notified'] ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailabilityAlert && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_phone': patientPhone,
      'drug_id': drugId,
      'drug_name': drugName,
      'created_at': createdAt.toIso8601String(),
      'is_notified': isNotified,
    };
  }
}

class EmergencyBroadcast {
  final String id;
  final String patientPhone;
  final String drugName;
  final String governorate;
  final String? prescriptionImageUrl;
  final DateTime createdAt;
  final List<String> respondingPharmacyNames;

  EmergencyBroadcast({
    required this.id,
    required this.patientPhone,
    required this.drugName,
    required this.governorate,
    this.prescriptionImageUrl,
    required this.createdAt,
    this.respondingPharmacyNames = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmergencyBroadcast && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  factory EmergencyBroadcast.fromJson(Map<String, dynamic> json) {
    return EmergencyBroadcast(
      id: json['id'] ?? '',
      patientPhone: json['patient_phone'] ?? '',
      drugName: json['drug_name'] ?? '',
      governorate: json['governorate'] ?? '',
      prescriptionImageUrl: json['prescription_image_url'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      respondingPharmacyNames: (json['responding_pharmacy_names'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_phone': patientPhone,
      'drug_name': drugName,
      'governorate': governorate,
      'prescription_image_url': prescriptionImageUrl,
      'created_at': createdAt.toIso8601String(),
      'responding_pharmacy_names': respondingPharmacyNames,
    };
  }
}
