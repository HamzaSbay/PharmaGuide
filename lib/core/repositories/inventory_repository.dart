import '../models/inventory_model.dart';

abstract interface class IInventoryRepository {
  List<InventoryModel> get inventories;
  int getStock(String pharmacyId, String drugId);
  Future<void> updateStockQuantity(String pharmacyId, String drugId, int newQuantity);
  Future<void> confirmAllInventoryFresh(String pharmacyId);
}
