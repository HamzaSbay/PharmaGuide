import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';
import '../../core/models/drug_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/favorites_service.dart';
import '../../core/services/mock_data_service.dart';
import 'pharmacy_results_screen.dart';

class DrugDetailScreen extends StatefulWidget {
  final DrugModel drug;

  const DrugDetailScreen({
    super.key,
    required this.drug,
  });

  @override
  State<DrugDetailScreen> createState() => _DrugDetailScreenState();
}

class _DrugDetailScreenState extends State<DrugDetailScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  final MockDataService _mockData = MockDataService();
  final AuthService _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _mockData.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _mockData.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  void _toggleRadar() {
    final patientPhone = _auth.currentUser?.phone ?? '+216 22 123 456';
    final wasActive = _mockData.hasRadarAlert(widget.drug.id);
    _mockData.toggleRadarAlert(
      drugId: widget.drug.id,
      drugName: widget.drug.brandName,
      patientPhone: patientPhone,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasActive
              ? 'Radar désactivé pour ${widget.drug.brandName}'
              : '⚡ Radar activé ! Vous recevrez une alerte dès retour en stock.',
        ),
        backgroundColor: wasActive ? Colors.grey.shade800 : AppTheme.pharmacyGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drug = widget.drug;
    final isFav = _favoritesService.isDrugFavorite(drug.id);
    final hasRadar = _mockData.hasRadarAlert(drug.id);
    final richSubstitutes = _mockData.getGenericSubstitutes(drug);

    return Scaffold(
      appBar: AppBar(
        title: Text(drug.brandName),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.star : Icons.star_border,
              color: isFav ? Colors.amber : Colors.white,
            ),
            tooltip: isFav ? 'Retirer des favoris' : 'Ajouter aux favoris',
            onPressed: () async {
              await _favoritesService.toggleDrugFavorite(drug.id);
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
            // Main Header Card
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
                            drug.brandName,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.deepBlack),
                          ),
                        ),
                        if (drug.arabicName.isNotEmpty)
                          Text(
                            drug.arabicName,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.pharmacyGreen),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'DCI: ${drug.dciName}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dosage: ${drug.dosage} • Forme: ${drug.form}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const Divider(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.category, size: 16),
                          label: Text(drug.category),
                          backgroundColor: AppTheme.pharmacyGreen.withValues(alpha: 0.1),
                        ),
                        Chip(
                          avatar: const Icon(Icons.qr_code, size: 16),
                          label: Text('PCT: ${drug.pctCode}'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Prescription & CNAM Status Badges
            Card(
              color: drug.requiresPrescription ? Colors.orange.shade50 : Colors.green.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(
                      drug.requiresPrescription ? Icons.assignment_late : Icons.check_circle,
                      color: drug.requiresPrescription ? Colors.orange.shade800 : Colors.green.shade800,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            drug.requiresPrescription
                                ? 'Ordonnance Obligatoire (Sous prescription)'
                                : 'Disponible sans ordonnance',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: drug.requiresPrescription ? Colors.orange.shade900 : Colors.green.shade900,
                            ),
                          ),
                          Text(
                            drug.isCnamReimbursable
                                ? 'Pris en charge par la CNAM (Remboursable)'
                                : 'Non remboursé par la CNAM',
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // National Shortage Alert Banner (if applicable)
            if (drug.isNationalRupture) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_rounded, color: Colors.red.shade800, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tensions d\'Approvisionnement (Rupture PCT)',
                            style: TextStyle(
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Ce médicament subit une pénurie temporaire en Tunisie. Activez le Radar ci-dessous pour être notifié dès réapprovisionnement, ou consultez les génériques disponibles.',
                            style: TextStyle(color: Colors.black87, fontSize: 12, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Back-in-Stock Radar Button
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: hasRadar ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: hasRadar ? AppTheme.pharmacyGreen : Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    hasRadar ? Icons.radar : Icons.notifications_none,
                    color: hasRadar ? AppTheme.pharmacyGreen : Colors.black54,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasRadar ? 'Radar Actif (Surveillance 24/7)' : 'Radar de Disponibilité',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: hasRadar ? Colors.green.shade900 : Colors.black87,
                          ),
                        ),
                        Text(
                          hasRadar
                              ? 'Vous serez alerté par SMS et notification dès retour en stock.'
                              : 'Recevez une alerte dès qu\'une officine reçoit du stock.',
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _toggleRadar,
                    style: TextButton.styleFrom(
                      foregroundColor: hasRadar ? Colors.red : AppTheme.pharmacyGreen,
                    ),
                    child: Text(
                      hasRadar ? 'Désactiver' : 'M\'alerter',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            // Clinical / Usage Information
            const Text('Informations Médicales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoSection(
                      icon: Icons.warning_amber_rounded,
                      title: 'Effets Secondaires',
                      content: drug.sideEffects ?? 'Nausées légères, somnolence possible en cas de surdosage.',
                    ),
                    const Divider(height: 20),
                    _buildInfoSection(
                      icon: Icons.block,
                      title: 'Contre-indications',
                      content: drug.contraindications ?? 'Hypersensibilité à la substance active ou aux excipients.',
                    ),
                    const Divider(height: 20),
                    _buildInfoSection(
                      icon: Icons.swap_horiz,
                      title: 'Interactions Médicamenteuses',
                      content: drug.interactions ?? 'Consultez votre pharmacien avant association avec d\'autres traitements.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Enriched Generic Substitutes Section
            if (richSubstitutes.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Alternatives Génériques Identiques (${richSubstitutes.length})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: const Text('Même DCI', style: TextStyle(fontSize: 10, color: AppTheme.pharmacyGreen, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...richSubstitutes.map((sub) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: sub.totalPharmaciesInStock > 0 ? Colors.green.shade200 : Colors.grey.shade300),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    leading: CircleAvatar(
                      backgroundColor: sub.totalPharmaciesInStock > 0 ? Colors.green.shade50 : Colors.grey.shade100,
                      child: Icon(
                        Icons.medication,
                        color: sub.totalPharmaciesInStock > 0 ? AppTheme.pharmacyGreen : Colors.grey,
                      ),
                    ),
                    title: Text(sub.substituteBrandName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${sub.dciName} • ${sub.dosage}'),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: sub.totalPharmaciesInStock > 0 ? Colors.green : Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              sub.totalPharmaciesInStock > 0
                                  ? 'En stock chez ${sub.totalPharmaciesInStock} officine(s)${sub.nearestDistanceKm != null ? " • Dès ${sub.nearestDistanceKm!.toStringAsFixed(1)} km" : ""}'
                                  : 'Faible disponibilité',
                              style: TextStyle(
                                fontSize: 11,
                                color: sub.totalPharmaciesInStock > 0 ? Colors.green.shade800 : Colors.orange.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      final targetDrug = _mockData.masterDrugs.firstWhere(
                        (d) => d.id == sub.substituteDrugId,
                        orElse: () => drug,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PharmacyResultsScreen(drug: targetDrug),
                        ),
                      );
                    },
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Action Button: Search Availability
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PharmacyResultsScreen(drug: drug),
                    ),
                  );
                },
                icon: const Icon(Icons.search),
                label: const Text('Trouver les Officines Disponibles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.pharmacyGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({required IconData icon, required String title, required String content}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.pharmacyGreen),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(content, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}
