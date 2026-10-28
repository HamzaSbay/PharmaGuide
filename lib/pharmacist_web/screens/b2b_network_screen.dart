import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';
import '../../core/models/drug_model.dart';
import '../../core/models/pharmacy_model.dart';
import '../../core/services/mock_data_service.dart';
import '../../core/models/b2b_request_model.dart';

class B2bNetworkScreen extends StatefulWidget {
  final String pharmacyId;

  const B2bNetworkScreen({
    super.key,
    required this.pharmacyId,
  });

  @override
  State<B2bNetworkScreen> createState() => _B2bNetworkScreenState();
}

class _B2bNetworkScreenState extends State<B2bNetworkScreen> {
  final MockDataService _mockData = MockDataService();
  DrugModel? _selectedDrug;
  List<PharmacyModel> _matchingPharmacies = [];
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _mockData.addListener(_onDataChanged);
    _selectedDrug = _mockData.masterDrugs.isNotEmpty
        ? _mockData.masterDrugs.firstWhere(
            (d) => d.id == 'drug-3',
            orElse: () => _mockData.masterDrugs.first,
          )
        : null;
    _searchB2bStock();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _quantityController.dispose();
    _mockData.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  void _searchB2bStock() {
    if (_selectedDrug == null) return;
    final results = _mockData.findNearbyPharmaciesWithStock(
      drugId: _selectedDrug!.id,
      lat: _mockData.userLat,
      lng: _mockData.userLng,
      radiusKm: 25.0,
    );

    // Filter out own pharmacy
    setState(() {
      _matchingPharmacies = results.where((p) => p.id != widget.pharmacyId).toList();
    });
  }

  void _sendB2bPing(PharmacyModel targetPharmacy) {
    if (_selectedDrug == null) return;
    _mockData.createB2BRequest(
      requestingPharmacyId: widget.pharmacyId,
      targetPharmacyId: targetPharmacy.id,
      drugId: _selectedDrug!.id,
      quantity: math.max(1, int.tryParse(_quantityController.text) ?? 1),
      notes: _notesController.text.isNotEmpty ? _notesController.text : 'Patient au comptoir ayant besoin du médicament.',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚡ Demande de transfert B2B envoyée à ${targetPharmacy.name}!'),
        backgroundColor: AppTheme.secondaryEmerald,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b2bRequests = _mockData.b2bRequests;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Search & Transfer Section
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.cnamBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.swap_horizontal_circle, color: AppTheme.cnamBlue, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Réseau Inter-Pharmacies B2B (Dépannage Confrères)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                          ),
                          Text(
                            'Recherchez et demandez des dépannages de stock entre officines voisines pour vos patients au comptoir.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Drug Picker for B2B Transfer
                DropdownButtonFormField<DrugModel>(
                  initialValue: _selectedDrug,
                  decoration: const InputDecoration(
                    labelText: 'Sélectionner le Médicament en Rupture au Comptoir',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.medication, color: AppTheme.primaryTeal),
                  ),
                  items: _mockData.masterDrugs.where((d) => !d.isBlacklisted).map((drug) {
                    return DropdownMenuItem<DrugModel>(
                      value: drug,
                      child: Text('${drug.brandName} (${drug.dciName})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedDrug = val);
                    _searchB2bStock();
                  },
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Note de dépannage pour le confrère (optionnel)...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note_add),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantité demandée',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Officines Voisines en Stock (${_matchingPharmacies.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: ListView.builder(
                    itemCount: _matchingPharmacies.length,
                    itemBuilder: (context, index) {
                      final ph = _matchingPharmacies[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const Icon(Icons.storefront, color: AppTheme.primaryTeal),
                          title: Text(ph.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${ph.address} (${ph.phoneLandline})'),
                          trailing: ElevatedButton.icon(
                            onPressed: () => _sendB2bPing(ph),
                            icon: const Icon(Icons.send, size: 16),
                            label: const Text('Envoyer Dépannage B2B'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cnamBlue),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Right Live B2B Activity Feed
          Expanded(
            flex: 4,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.history, color: AppTheme.primaryTeal),
                        SizedBox(width: 8),
                        Text(
                          'Historique Demandes B2B',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Expanded(
                      child: b2bRequests.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox, size: 48, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('Aucune demande B2B pour le moment', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : ListView.builder(
                        itemCount: b2bRequests.length,
                        itemBuilder: (context, index) {
                          final req = b2bRequests[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.lightBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.borderGrey),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      req.drug?.brandName ?? 'Médicament',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentAmber.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        req.status.name,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.accentAmber),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'De: ${req.requestingPharmacy?.name} ➔ Vers: ${req.targetPharmacy?.name}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                ),
                                if (req.notes != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '"${req.notes}"',
                                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade800),
                                  ),
                                ],
                                if (req.targetPharmacyId == widget.pharmacyId && req.status == B2BRequestStatus.pending) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () => _mockData.updateB2BRequestStatus(req.id, B2BRequestStatus.rejected),
                                        child: const Text('Refuser', style: TextStyle(color: Colors.red)),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () => _mockData.updateB2BRequestStatus(req.id, B2BRequestStatus.approved),
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.pharmacyGreen),
                                        child: const Text('Accepter'),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
