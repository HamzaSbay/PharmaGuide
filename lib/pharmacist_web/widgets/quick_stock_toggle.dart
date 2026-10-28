import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';
import '../../core/models/drug_model.dart';
import '../../core/services/mock_data_service.dart';

class QuickStockToggle extends StatelessWidget {
  final DrugModel drug;
  final int currentQuantity;
  final String pharmacyId;

  const QuickStockToggle({
    super.key,
    required this.drug,
    required this.currentQuantity,
    required this.pharmacyId,
  });

  @override
  Widget build(BuildContext context) {
    bool inStock = currentQuantity > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drug.brandName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    'DCI: ${drug.dciName} (${drug.dosage})',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: AppTheme.errorRed),
                  onPressed: currentQuantity > 0
                      ? () {
                          MockDataService().updateStockQuantity(pharmacyId, drug.id, currentQuantity - 1);
                        }
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: inStock ? AppTheme.secondaryEmerald.withValues(alpha: 0.15) : AppTheme.errorRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$currentQuantity Qte',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: inStock ? AppTheme.secondaryEmerald : AppTheme.errorRed,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.secondaryEmerald),
                  onPressed: () {
                    MockDataService().updateStockQuantity(pharmacyId, drug.id, currentQuantity + 5);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
