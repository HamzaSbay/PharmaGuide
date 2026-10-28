import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/theme.dart';
import '../../core/models/pharmacy_model.dart';
import '../../core/services/favorites_service.dart';
import '../../core/services/mock_data_service.dart';
import '../widgets/cnam_garde_badge.dart';

class PharmacyDetailScreen extends StatefulWidget {
  final PharmacyModel pharmacy;

  const PharmacyDetailScreen({
    super.key,
    required this.pharmacy,
  });

  @override
  State<PharmacyDetailScreen> createState() => _PharmacyDetailScreenState();
}

class _PharmacyDetailScreenState extends State<PharmacyDetailScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  final MockDataService _mockData = MockDataService();

  Future<void> _makeCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('⚠️ [PHARMACY_DETAIL] Call launch error: $e');
    }
  }

  Future<void> _openDirections(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('⚠️ [PHARMACY_DETAIL] Directions launch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pharmacy = widget.pharmacy;
    final isFav = _favoritesService.isPharmacyFavorite(pharmacy.id);
    final pharmacyStock = _mockData.getPharmacyStock(pharmacy.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(pharmacy.name),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.star : Icons.star_border,
              color: isFav ? Colors.amber : Colors.white,
            ),
            tooltip: isFav ? 'Retirer des favoris' : 'Ajouter aux favoris',
            onPressed: () async {
              await _favoritesService.togglePharmacyFavorite(pharmacy.id);
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            pharmacy.name,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.deepBlack),
                          ),
                        ),
                        CnamGardeBadge(
                          isCnam: pharmacy.acceptsCnam,
                          isGarde: pharmacy.isGarde,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: AppTheme.pharmacyGreen),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${pharmacy.address}, ${pharmacy.municipality} (${pharmacy.governorate})',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: AppTheme.deepBlack),
                        const SizedBox(width: 4),
                        Text(
                          pharmacy.phoneLandline,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          'CNOP: ${pharmacy.cnopId}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.access_time_filled, size: 16, color: AppTheme.pharmacyGreen),
                        const SizedBox(width: 6),
                        Text(
                          'Horaires: ${pharmacy.openingHours}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.pharmacyGreen),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Action Buttons (Call & Directions)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _makeCall(pharmacy.phoneLandline),
                    icon: const Icon(Icons.phone),
                    label: const Text('Appeler Officine'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.pharmacyGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openDirections(pharmacy.latitude, pharmacy.longitude),
                    icon: const Icon(Icons.directions),
                    label: const Text('Itinéraire GPS'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.pharmacyGreen,
                      side: const BorderSide(color: AppTheme.pharmacyGreen),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Inventory / Available Stock at this Pharmacy
            Text(
              'Médicaments en Stock en Officine (${pharmacyStock.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            pharmacyStock.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Aucun médicament répertorié en stock pour le moment.', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pharmacyStock.length,
                    itemBuilder: (ctx, idx) {
                      final item = pharmacyStock[idx];
                      final drug = _mockData.masterDrugs.firstWhere(
                        (d) => d.id == item.drugId,
                        orElse: () => _mockData.masterDrugs.first,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(drug.brandName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('DCI: ${drug.dciName} • ${drug.dosage}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: item.isAvailable ? AppTheme.pharmacyGreen.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.isAvailable ? '${item.quantity} en stock' : 'Rupture',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: item.isAvailable ? AppTheme.pharmacyGreen : Colors.red,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
