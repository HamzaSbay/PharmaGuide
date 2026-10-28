class ChronicReminderModel {
  final String id;
  final String patientPhone;
  final String drugId;
  final String drugName;
  final String dciName;
  final String pharmacyId;
  final String pharmacyName;
  final int cycleDays;
  final DateTime startDate;
  final DateTime nextRefillDate;
  bool isActive;

  ChronicReminderModel({
    required this.id,
    required this.patientPhone,
    required this.drugId,
    required this.drugName,
    required this.dciName,
    required this.pharmacyId,
    required this.pharmacyName,
    this.cycleDays = 30,
    required this.startDate,
    DateTime? nextRefillDate,
    this.isActive = true,
  }) : nextRefillDate = nextRefillDate ?? startDate.add(Duration(days: cycleDays));

  int get daysUntilRefill {
    final diff = nextRefillDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  bool get isDueSoon => daysUntilRefill <= 5;

  factory ChronicReminderModel.fromJson(Map<String, dynamic> json) {
    return ChronicReminderModel(
      id: json['id'] ?? '',
      patientPhone: json['patient_phone'] ?? '',
      drugId: json['drug_id'] ?? '',
      drugName: json['drug_name'] ?? '',
      dciName: json['dci_name'] ?? '',
      pharmacyId: json['pharmacy_id'] ?? '',
      pharmacyName: json['pharmacy_name'] ?? '',
      cycleDays: json['cycle_days'] ?? 30,
      startDate: DateTime.tryParse(json['start_date'] ?? '') ?? DateTime.now(),
      nextRefillDate: DateTime.tryParse(json['next_refill_date'] ?? ''),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_phone': patientPhone,
      'drug_id': drugId,
      'drug_name': drugName,
      'dci_name': dciName,
      'pharmacy_id': pharmacyId,
      'pharmacy_name': pharmacyName,
      'cycle_days': cycleDays,
      'start_date': startDate.toIso8601String(),
      'next_refill_date': nextRefillDate.toIso8601String(),
      'is_active': isActive,
    };
  }
}
