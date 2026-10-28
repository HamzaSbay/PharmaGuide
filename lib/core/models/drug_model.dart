class DrugModel {
  final String id;
  final String brandName;
  final String dciName; // Active Ingredient (e.g. Paracetamol)
  final String dosage;
  final String form;
  final String pctCode;
  final String category; // e.g. Fièvre & Douleur, Cœur, Yeux, Jambes
  final String arabicName; // Arabic Script (e.g. دولبران)
  final List<String> aliases; // Darija & Phonetic terms (e.g. dawaa el sekkri, wjaa al rass, tension)
  final bool requiresPrescription;
  final bool isControlledSubstance; // Tableau A, B, C safeguard
  final bool isBlacklisted;
  final String? sideEffects; // e.g. Nausées, somnolence
  final String? contraindications; // e.g. Insuffisance hépatique sévère
  final String? interactions; // e.g. Alcool, anticoagulants
  final bool isCnamReimbursable; // CNAM reimbursement eligibility
  final bool isNationalRupture; // PCT official national shortage
  final String? barcode; // EAN-13 or Datamatrix packaging barcode
  final List<String> substituteIds; // Verified generic/therapeutic alternatives

  DrugModel({
    required this.id,
    required this.brandName,
    required this.dciName,
    required this.dosage,
    required this.form,
    required this.pctCode,
    this.category = 'Général',
    this.arabicName = '',
    this.aliases = const [],
    this.requiresPrescription = false,
    this.isControlledSubstance = false,
    this.isBlacklisted = false,
    this.sideEffects,
    this.contraindications,
    this.interactions,
    this.isCnamReimbursable = true,
    this.isNationalRupture = false,
    this.barcode,
    this.substituteIds = const [],
  });

  factory DrugModel.fromJson(Map<String, dynamic> json) {
    return DrugModel(
      id: json['id'] ?? '',
      brandName: json['brand_name'] ?? '',
      dciName: json['dci_name'] ?? '',
      dosage: json['dosage'] ?? '',
      form: json['form'] ?? '',
      pctCode: json['pct_code'] ?? '',
      category: json['category'] ?? 'Général',
      arabicName: json['arabic_name'] ?? '',
      aliases: (json['aliases'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      requiresPrescription: json['requires_prescription'] ?? false,
      isControlledSubstance: json['is_controlled_substance'] ?? false,
      isBlacklisted: json['is_blacklisted'] ?? false,
      sideEffects: json['side_effects'],
      contraindications: json['contraindications'],
      interactions: json['interactions'],
      isCnamReimbursable: json['is_cnam_reimbursable'] ?? true,
      isNationalRupture: json['is_national_rupture'] ?? false,
      barcode: json['barcode'],
      substituteIds: (json['substitute_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand_name': brandName,
      'dci_name': dciName,
      'dosage': dosage,
      'form': form,
      'pct_code': pctCode,
      'category': category,
      'arabic_name': arabicName,
      'aliases': aliases,
      'requires_prescription': requiresPrescription,
      'is_controlled_substance': isControlledSubstance,
      'is_blacklisted': isBlacklisted,
      'side_effects': sideEffects,
      'contraindications': contraindications,
      'interactions': interactions,
      'is_cnam_reimbursable': isCnamReimbursable,
      'is_national_rupture': isNationalRupture,
      'barcode': barcode,
      'substitute_ids': substituteIds,
    };
  }

  DrugModel copyWith({
    String? id,
    String? brandName,
    String? dciName,
    String? dosage,
    String? form,
    String? pctCode,
    String? category,
    String? arabicName,
    List<String>? aliases,
    bool? requiresPrescription,
    bool? isControlledSubstance,
    bool? isBlacklisted,
    String? sideEffects,
    String? contraindications,
    String? interactions,
    bool? isCnamReimbursable,
    bool? isNationalRupture,
    String? barcode,
    List<String>? substituteIds,
  }) {
    return DrugModel(
      id: id ?? this.id,
      brandName: brandName ?? this.brandName,
      dciName: dciName ?? this.dciName,
      dosage: dosage ?? this.dosage,
      form: form ?? this.form,
      pctCode: pctCode ?? this.pctCode,
      category: category ?? this.category,
      arabicName: arabicName ?? this.arabicName,
      aliases: aliases ?? this.aliases,
      requiresPrescription: requiresPrescription ?? this.requiresPrescription,
      isControlledSubstance: isControlledSubstance ?? this.isControlledSubstance,
      isBlacklisted: isBlacklisted ?? this.isBlacklisted,
      sideEffects: sideEffects ?? this.sideEffects,
      contraindications: contraindications ?? this.contraindications,
      interactions: interactions ?? this.interactions,
      isCnamReimbursable: isCnamReimbursable ?? this.isCnamReimbursable,
      isNationalRupture: isNationalRupture ?? this.isNationalRupture,
      barcode: barcode ?? this.barcode,
      substituteIds: substituteIds ?? this.substituteIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrugModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
