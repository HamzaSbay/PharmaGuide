import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';
import '../../core/models/drug_model.dart';
import '../../core/models/pharmacy_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/mock_data_service.dart';
import '../../core/services/supabase_service.dart';
import '../widgets/pharmacy_card.dart';
import '../widgets/generic_alternative_modal.dart';
import 'hold_request_modal.dart';

class PharmacyResultsScreen extends StatefulWidget {
  final DrugModel drug;
  final double radiusKm;
  final bool requiresCnam;
  final bool onlyGarde;

  const PharmacyResultsScreen({
    super.key,
    required this.drug,
    this.radiusKm = 15.0,
    this.requiresCnam = false,
    this.onlyGarde = false,
  });

  @override
  State<PharmacyResultsScreen> createState() => _PharmacyResultsScreenState();
}

class _PharmacyResultsScreenState extends State<PharmacyResultsScreen> {
  final MockDataService _mockData = MockDataService();
  late DrugModel _currentDrug;
  List<PharmacyModel> _nearbyPharmacies = [];
  List<DrugModel> _genericAlternatives = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentDrug = widget.drug;
    _fetchPharmacies();
  }

  Future<void> _fetchPharmacies() async {
    setState(() => _isLoading = true);
    try {
      final userLat = LocationService().currentLat;
      final userLng = LocationService().currentLng;

      final pharmacies = await SupabaseService().findNearbyPharmaciesWithStock(
        drugId: _currentDrug.id,
        lat: userLat,
        lng: userLng,
        radiusKm: widget.radiusKm,
        requiresCnam: widget.requiresCnam,
        onlyGarde: widget.onlyGarde,
      );

      final alternatives = _mockData.getGenericAlternatives(_currentDrug);
      if (mounted) {
        setState(() {
          _nearbyPharmacies = pharmacies;
          _genericAlternatives = alternatives;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [PHARMACY_RESULTS] Fetch error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de recherche: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openHoldModal(PharmacyModel pharmacy) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => HoldRequestModal(
        pharmacy: pharmacy,
        drug: _currentDrug,
      ),
    );

    if (result == true && mounted) {
      _fetchPharmacies();
    }
  }

  void _showGenericAlternativesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GenericAlternativeModal(
        requestedDrug: _currentDrug,
        alternatives: _genericAlternatives,
        onSelectDrug: (selectedAlt) {
          setState(() {
            _currentDrug = selectedAlt;
          });
          _fetchPharmacies();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_currentDrug.brandName),
            Text(
              'DCI: ${_currentDrug.dciName} (${_currentDrug.dosage})',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Summary Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.primaryTeal.withValues(alpha: 0.05),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: AppTheme.primaryTeal),
                const SizedBox(width: 6),
                Text(
                  'Rayon: ${widget.radiusKm.toInt()} km (Tunis)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                if (widget.requiresCnam)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppTheme.cnamBlue, borderRadius: BorderRadius.circular(4)),
                    child: const Text('CNAM', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                if (widget.onlyGarde)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppTheme.gardePurple, borderRadius: BorderRadius.circular(4)),
                    child: const Text('GARDE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),

          // National Rupture Banner
          if (_currentDrug.isNationalRupture)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade800, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tensions PCT : Rupture nationale signalée pour ce médicament.',
                      style: TextStyle(color: Colors.red.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          // Out of stock or low stock generic suggestion banner
          if (_nearbyPharmacies.isEmpty && _genericAlternatives.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.accentAmber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentAmber),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppTheme.accentAmber, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Rupture de stock locale pour "${_currentDrug.brandName}".',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkSlate),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_genericAlternatives.length} alternative(s) générique(s) disponible(s) en officine avec le même principe actif (${_currentDrug.dciName}).',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showGenericAlternativesModal,
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: const Text('Voir Équivalents Génériques'),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppTheme.pharmacyGreen),
                        SizedBox(height: 16),
                        Text(
                          'Recherche des pharmacies à proximité...',
                          style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  )
                : _nearbyPharmacies.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucune pharmacie avec stock disponible trouvée',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Essayez d\'augmenter le rayon de recherche ou activez une alerte de disponibilité.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              _mockData.addAvailabilityAlert(
                                patientPhone: AuthService().currentUser?.phone ?? '+216',
                                drugId: _currentDrug.id,
                                drugName: _currentDrug.brandName,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('🔔 Alerte SMS activée pour "${_currentDrug.brandName}"!'),
                                  backgroundColor: AppTheme.pharmacyGreen,
                                ),
                              );
                            },
                            icon: const Icon(Icons.notifications_active, size: 18),
                            label: const Text('🔔 M\'alerter dès disponibilité (SMS)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.pharmacyGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _nearbyPharmacies.length,
                    itemBuilder: (context, index) {
                      final ph = _nearbyPharmacies[index];
                      return PharmacyCard(
                        pharmacy: ph,
                        selectedDrug: _currentDrug,
                        onReservePressed: () => _openHoldModal(ph),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
