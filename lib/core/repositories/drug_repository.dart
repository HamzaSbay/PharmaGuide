import '../models/drug_model.dart';
import '../models/basket_optimization_model.dart';

abstract interface class IDrugRepository {
  List<DrugModel> get masterDrugs;
  Future<List<DrugModel>> searchDrugs(String query);
  DrugModel? findDrugByBarcode(String barcode);
  List<GenericSubstituteResult> getGenericSubstitutes(DrugModel drug);
  Future<void> toggleDrugBlacklist(String drugId);
  Future<void> addDrug(DrugModel drug);
}
