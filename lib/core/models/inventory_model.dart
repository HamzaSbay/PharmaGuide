import 'drug_model.dart';

class InventoryModel {
  final String id;
  final String pharmacyId;
  final String drugId;
  final int quantity;
  final DateTime lastUpdatedAt;
  final DrugModel? drug;

  bool get isAvailable => quantity > 0;

  InventoryModel({
    required this.id,
    required this.pharmacyId,
    required this.drugId,
    required this.quantity,
    required this.lastUpdatedAt,
    this.drug,
  });

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      id: json['id'] ?? '',
      pharmacyId: json['pharmacy_id'] ?? '',
      drugId: json['drug_id'] ?? '',
      quantity: json['quantity'] ?? 0,
      lastUpdatedAt: json['last_updated_at'] != null
          ? DateTime.tryParse(json['last_updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      drug: json['drug'] != null ? DrugModel.fromJson(json['drug']) : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pharmacy_id': pharmacyId,
      'drug_id': drugId,
      'quantity': quantity,
      'last_updated_at': lastUpdatedAt.toIso8601String(),
      if (drug != null) 'drug': drug!.toJson(),
    };
  }

  InventoryModel copyWith({
    String? id,
    String? pharmacyId,
    String? drugId,
    int? quantity,
    DateTime? lastUpdatedAt,
    DrugModel? drug,
  }) {
    return InventoryModel(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      drugId: drugId ?? this.drugId,
      quantity: quantity ?? this.quantity,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      drug: drug ?? this.drug,
    );
  }
}
