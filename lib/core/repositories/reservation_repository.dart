import '../models/reservation_model.dart';
import '../utils/result.dart';

abstract interface class IReservationRepository {
  List<ReservationModel> get reservations;
  Future<Result<ReservationModel>> createReservation({
    required String patientId,
    required String patientPhone,
    required String pharmacyId,
    required String drugId,
    String? prescriptionUrl,
  });
  Future<Result<List<ReservationModel>>> createMultiDrugReservation({
    required String patientId,
    required String patientPhone,
    required String pharmacyId,
    required List<String> drugIds,
    String? prescriptionUrl,
  });
  Future<void> updateReservationStatus(String resId, ReservationStatus newStatus);
}
