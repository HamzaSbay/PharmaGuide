import '../models/b2b_request_model.dart';

abstract interface class IB2BRepository {
  List<B2BRequestModel> get b2bRequests;
  Future<void> createB2BRequest({
    required String requestingPharmacyId,
    required String targetPharmacyId,
    required String drugId,
    required int quantity,
    String? notes,
  });
  Future<void> updateB2BRequestStatus(String requestId, B2BRequestStatus newStatus);
}
