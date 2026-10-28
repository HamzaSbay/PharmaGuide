import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';
import '../../core/models/pharmacy_model.dart';
import '../../core/models/drug_model.dart';
import 'cnam_garde_badge.dart';

import '../screens/pharmacy_detail_screen.dart';

class PharmacyCard extends StatelessWidget {
  final PharmacyModel pharmacy;
  final DrugModel selectedDrug;
  final VoidCallback onReservePressed;

  const PharmacyCard({
    super.key,
    required this.pharmacy,
    required this.selectedDrug,
    required this.onReservePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shadowColor: AppTheme.deepBlack.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.borderGrey, width: 1),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PharmacyDetailScreen(pharmacy: pharmacy),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.pharmacyGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_pharmacy, color: AppTheme.pharmacyGreen, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pharmacy.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.deepBlack,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${pharmacy.municipality}, ${pharmacy.governorate}',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                if (pharmacy.distanceKm != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.pharmacyGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.pharmacyGreen.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${pharmacy.distanceKm!.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.pharmacyGreen,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              pharmacy.address,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.pharmacyGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 14, color: AppTheme.pharmacyGreen),
                  const SizedBox(width: 4),
                  Text(
                    '${selectedDrug.brandName} en stock',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.pharmacyGreen),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            CnamGardeBadge(
              isCnam: pharmacy.acceptsCnam,
              isGarde: pharmacy.isGarde,
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.phone_in_talk, size: 13, color: AppTheme.deepBlack),
                          const SizedBox(width: 4),
                          Text(
                            pharmacy.phoneLandline,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.deepBlack),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.access_time_filled, size: 13, color: AppTheme.pharmacyGreen),
                          const SizedBox(width: 4),
                          Text(
                            'Horaires: ${pharmacy.openingHours}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.pharmacyGreen),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onReservePressed,
                  icon: const Icon(Icons.bookmark_add, size: 18),
                  label: const Text('Réserver (2h)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.pharmacyGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }
}
