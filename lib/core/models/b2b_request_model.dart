import 'drug_model.dart';
import 'pharmacy_model.dart';

enum B2BRequestStatus { pending, approved, rejected, completed }

class B2BRequestModel {
  final String id;
  final String requestingPharmacyId;
  final String targetPharmacyId;
  final String drugId;
  final int quantity;
  final B2BRequestStatus status;
  final String? notes;
  final DateTime createdAt;
  final PharmacyModel? requestingPharmacy;
  final PharmacyModel? targetPharmacy;
  final DrugModel? drug;

  B2BRequestModel({
    required this.id,
    required this.requestingPharmacyId,
    required this.targetPharmacyId,
    required this.drugId,
    required this.quantity,
    this.status = B2BRequestStatus.pending,
    this.notes,
    required this.createdAt,
    this.requestingPharmacy,
    this.targetPharmacy,
    this.drug,
  });

  factory B2BRequestModel.fromJson(Map<String, dynamic> json) {
    return B2BRequestModel(
      id: json['id'] ?? '',
      requestingPharmacyId: json['requesting_pharmacy_id'] ?? '',
      targetPharmacyId: json['target_pharmacy_id'] ?? '',
      drugId: json['drug_id'] ?? '',
      quantity: json['quantity'] ?? 1,
      status: _parseStatus(json['status']),
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      requestingPharmacy: json['requesting_pharmacy'] != null
          ? PharmacyModel.fromJson(json['requesting_pharmacy'])
          : null,
      targetPharmacy: json['target_pharmacy'] != null
          ? PharmacyModel.fromJson(json['target_pharmacy'])
          : null,
      drug: json['drug'] != null ? DrugModel.fromJson(json['drug']) : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is B2BRequestModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  static B2BRequestStatus _parseStatus(String? statusStr) {
    switch (statusStr?.toUpperCase()) {
      case 'APPROVED':
        return B2BRequestStatus.approved;
      case 'REJECTED':
        return B2BRequestStatus.rejected;
      case 'COMPLETED':
        return B2BRequestStatus.completed;
      default:
        return B2BRequestStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requesting_pharmacy_id': requestingPharmacyId,
      'target_pharmacy_id': targetPharmacyId,
      'drug_id': drugId,
      'quantity': quantity,
      'status': status.name.toUpperCase(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
