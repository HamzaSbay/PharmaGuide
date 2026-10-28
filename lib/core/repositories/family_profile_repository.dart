import '../models/family_profile_model.dart';

abstract interface class IFamilyProfileRepository {
  List<FamilyProfileModel> get familyProfiles;
  Future<void> addFamilyProfile(FamilyProfileModel profile);
  Future<void> removeFamilyProfile(String profileId);
  Future<void> toggleMedicationInProfile(String profileId, String drugId);
}
