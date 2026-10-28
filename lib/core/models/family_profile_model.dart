class FamilyProfileModel {
  final String id;
  final String displayName;
  final String relation; // 'Moi', 'Père', 'Mère', 'Enfant', 'Conjoint', 'Autre'
  final String? cnamAffiliation; // e.g. 'Filière publique', 'Médecin de famille', 'Remboursement'
  final List<String> chronicMedicationIds; // IDs of recurring medications
  final DateTime? birthDate;
  final String? notes;

  const FamilyProfileModel({
    required this.id,
    required this.displayName,
    required this.relation,
    this.cnamAffiliation,
    this.chronicMedicationIds = const [],
    this.birthDate,
    this.notes,
  });

  factory FamilyProfileModel.fromJson(Map<String, dynamic> json) {
    return FamilyProfileModel(
      id: json['id'] ?? '',
      displayName: json['display_name'] ?? '',
      relation: json['relation'] ?? 'Autre',
      cnamAffiliation: json['cnam_affiliation'],
      chronicMedicationIds: (json['chronic_medication_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      birthDate: json['birth_date'] != null
          ? DateTime.tryParse(json['birth_date'])
          : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'relation': relation,
      'cnam_affiliation': cnamAffiliation,
      'chronic_medication_ids': chronicMedicationIds,
      'birth_date': birthDate?.toIso8601String(),
      'notes': notes,
    };
  }

  FamilyProfileModel copyWith({
    String? id,
    String? displayName,
    String? relation,
    String? cnamAffiliation,
    List<String>? chronicMedicationIds,
    DateTime? birthDate,
    String? notes,
  }) {
    return FamilyProfileModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      relation: relation ?? this.relation,
      cnamAffiliation: cnamAffiliation ?? this.cnamAffiliation,
      chronicMedicationIds: chronicMedicationIds ?? this.chronicMedicationIds,
      birthDate: birthDate ?? this.birthDate,
      notes: notes ?? this.notes,
    );
  }
}
