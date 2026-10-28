class PharmacyModel {
  final String id;
  final String cnopId;
  final String name;
  final String governorate;
  final String municipality;
  final String address;
  final String phoneLandline;
  final double latitude;
  final double longitude;
  final bool acceptsCnam;
  final bool isGarde;
  final String status; // PENDING, APPROVED, SUSPENDED
  final String openingHours; // e.g. 08:30 - 19:30 or Garde 24h/24
  final double? distanceKm;

  PharmacyModel({
    required this.id,
    required this.cnopId,
    required this.name,
    required this.governorate,
    required this.municipality,
    required this.address,
    required this.phoneLandline,
    required this.latitude,
    required this.longitude,
    this.acceptsCnam = false,
    this.isGarde = false,
    this.status = 'APPROVED',
    this.openingHours = '08:30 - 19:30',
    this.distanceKm,
  });

  factory PharmacyModel.fromJson(Map<String, dynamic> json) {
    return PharmacyModel(
      id: json['id'] ?? json['pharmacy_id'] ?? '',
      cnopId: json['cnop_id'] ?? '',
      name: json['name'] ?? json['pharmacy_name'] ?? '',
      governorate: json['governorate'] ?? '',
      municipality: json['municipality'] ?? '',
      address: json['address'] ?? '',
      phoneLandline: json['phone_landline'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 36.8065,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 10.1815,
      acceptsCnam: json['accepts_cnam'] ?? false,
      isGarde: json['is_garde'] ?? false,
      status: json['status'] ?? 'APPROVED',
      openingHours: json['opening_hours'] ?? (json['is_garde'] == true ? 'Garde 24/7' : '08:30 - 19:30'),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cnop_id': cnopId,
      'name': name,
      'governorate': governorate,
      'municipality': municipality,
      'address': address,
      'phone_landline': phoneLandline,
      'latitude': latitude,
      'longitude': longitude,
      'accepts_cnam': acceptsCnam,
      'is_garde': isGarde,
      'status': status,
      'opening_hours': openingHours,
      'distance_km': distanceKm,
    };
  }

  PharmacyModel copyWith({
    String? id,
    String? cnopId,
    String? name,
    String? governorate,
    String? municipality,
    String? address,
    String? phoneLandline,
    double? latitude,
    double? longitude,
    bool? acceptsCnam,
    bool? isGarde,
    String? status,
    String? openingHours,
    double? distanceKm,
  }) {
    return PharmacyModel(
      id: id ?? this.id,
      cnopId: cnopId ?? this.cnopId,
      name: name ?? this.name,
      governorate: governorate ?? this.governorate,
      municipality: municipality ?? this.municipality,
      address: address ?? this.address,
      phoneLandline: phoneLandline ?? this.phoneLandline,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      acceptsCnam: acceptsCnam ?? this.acceptsCnam,
      isGarde: isGarde ?? this.isGarde,
      status: status ?? this.status,
      openingHours: openingHours ?? this.openingHours,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PharmacyModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
