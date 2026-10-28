import 'drug_model.dart';
import 'pharmacy_model.dart';

enum ReservationStatus { pending, confirmed, collected, expired, declined }

class ReservationModel {
  final String id;
  final String patientId;
  final String patientPhone;
  final String pharmacyId;
  final String drugId;
  final String? prescriptionImageUrl;
  final ReservationStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DrugModel? drug;
  final PharmacyModel? pharmacy;

  ReservationModel({
    required this.id,
    required this.patientId,
    required this.patientPhone,
    required this.pharmacyId,
    required this.drugId,
    this.prescriptionImageUrl,
    this.status = ReservationStatus.pending,
    required this.createdAt,
    required this.expiresAt,
    this.drug,
    this.pharmacy,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get remainingTime {
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      patientPhone: json['patient_phone'] ?? '',
      pharmacyId: json['pharmacy_id'] ?? '',
      drugId: json['drug_id'] ?? '',
      prescriptionImageUrl: json['prescription_image_url'],
      status: _parseStatus(json['status']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString()) ?? DateTime.now().add(const Duration(hours: 2))
          : DateTime.now().add(const Duration(hours: 2)),
      drug: json['drug'] != null ? DrugModel.fromJson(json['drug']) : null,
      pharmacy: json['pharmacy'] != null
          ? PharmacyModel.fromJson(json['pharmacy'])
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReservationModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  static ReservationStatus _parseStatus(String? statusStr) {
    switch (statusStr?.toUpperCase()) {
      case 'CONFIRMED':
        return ReservationStatus.confirmed;
      case 'COLLECTED':
        return ReservationStatus.collected;
      case 'EXPIRED':
        return ReservationStatus.expired;
      case 'DECLINED':
        return ReservationStatus.declined;
      default:
        return ReservationStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'patient_phone': patientPhone,
      'pharmacy_id': pharmacyId,
      'drug_id': drugId,
      'prescription_image_url': prescriptionImageUrl,
      'status': status.name.toUpperCase(),
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      if (drug != null) 'drug': drug!.toJson(),
      if (pharmacy != null) 'pharmacy': pharmacy!.toJson(),
    };
  }

  ReservationModel copyWith({
    String? id,
    String? patientId,
    String? patientPhone,
    String? pharmacyId,
    String? drugId,
    String? prescriptionImageUrl,
    ReservationStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    DrugModel? drug,
    PharmacyModel? pharmacy,
  }) {
    return ReservationModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientPhone: patientPhone ?? this.patientPhone,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      drugId: drugId ?? this.drugId,
      prescriptionImageUrl: prescriptionImageUrl ?? this.prescriptionImageUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      drug: drug ?? this.drug,
      pharmacy: pharmacy ?? this.pharmacy,
    );
  }
}
