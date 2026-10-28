import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/theme.dart';
import '../../core/models/drug_model.dart';
import '../../core/models/basket_optimization_model.dart';
import '../../core/services/mock_data_service.dart';
import '../../core/services/auth_service.dart';
import 'active_holds_screen.dart';

class MultiDrugBasketScreen extends StatefulWidget {
  final List<DrugModel>? initialDrugs;

  const MultiDrugBasketScreen({super.key, this.initialDrugs});

  @override
  State<MultiDrugBasketScreen> createState() => _MultiDrugBasketScreenState();
}

class _MultiDrugBasketScreenState extends State<MultiDrugBasketScreen>
    with SingleTickerProviderStateMixin {
  final MockDataService _mockData = MockDataService();
  final AuthService _auth = AuthService();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  final List<DrugModel> _basket = [];
  List<DrugModel> _searchResults = [];
  bool _isSearching = false;
  BasketOptimizationResult? _optimizationResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.initialDrugs != null) {
      _basket.addAll(widget.initialDrugs!);
    } else {
      // Default common prescription demo
      final doliprane = _mockData.masterDrugs.firstWhere(
        (d) => d.id == 'drug-1',
        orElse: () => _mockData.masterDrugs.first,
      );
      final augmentin = _mockData.masterDrugs.firstWhere(
        (d) => d.id == 'drug-3',
        orElse: () => _mockData.masterDrugs[1],
      );
      _basket.addAll([doliprane, augmentin]);
    }

    _recomputeOptimization();
    _mockData.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _mockData.removeListener(_onDataChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      _recomputeOptimization();
    }
  }

  void _recomputeOptimization() {
    if (_basket.isEmpty) {
      setState(() {
        _optimizationResult = null;
      });
      return;
    }

    final drugIds = _basket.map((d) => d.id).toList();
    final result = _mockData.findOptimalPharmaciesForBasket(drugIds);
    setState(() {
      _optimizationResult = result;
    });
  }

  void _addDrugToBasket(DrugModel drug) {
    if (!_basket.any((d) => d.id == drug.id)) {
      setState(() {
        _basket.add(drug);
        _searchController.clear();
        _searchResults.clear();
        _isSearching = false;
      });
      _recomputeOptimization();
    }
  }

  void _removeDrugFromBasket(String drugId) {
    setState(() {
      _basket.removeWhere((d) => d.id == drugId);
    });
    _recomputeOptimization();
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    final results = _mockData.searchDrugs(query);
    setState(() {
      _searchResults = results.where((d) => !_basket.any((b) => b.id == d.id)).toList();
      _isSearching = true;
    });
  }

  Future<void> _makePhoneCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('⚠️ [BASKET] Phone call error: $e');
    }
  }

  Future<void> _openDirections(double lat, double lng, String label) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('⚠️ [BASKET] Directions error: $e');
    }
  }

  Future<void> _reserveFullBasket({
    required String pharmacyId,
    required String pharmacyName,
    required List<String> drugIdsToReserve,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.timer, color: AppTheme.pharmacyGreen),
            const SizedBox(width: 8),
            const Expanded(child: Text('Bloquer au Guichet (2h)')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Réserver ${drugIdsToReserve.length} médicament(s) chez :',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              pharmacyName,
              style: const TextStyle(color: AppTheme.pharmacyGreen, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ce service est 100% gratuit. La pharmacie réserve vos boîtes pendant 2h maximum.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.pharmacyGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer la Réservation'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final patientPhone = _auth.currentUser?.phone ?? '+216 22 123 456';
      final patientId = _auth.currentUser?.id ?? 'guest-patient';

      await _mockData.createMultiDrugReservation(
        pharmacyId: pharmacyId,
        drugIds: drugIdsToReserve,
        patientId: patientId,
        patientPhone: patientPhone,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${drugIdsToReserve.length} médicament(s) bloqué(s) pendant 2h !'),
            backgroundColor: AppTheme.pharmacyGreen,
            action: SnackBarAction(
              label: 'Voir mes réservations',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ActiveHoldsScreen()),
                );
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final singleOptions = _optimizationResult?.singleStopOptions ?? [];
    final splitOptions = _optimizationResult?.splitStopOptions ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trouver toute mon ordonnance'),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        actions: [
          if (_basket.isNotEmpty)
            IconButton(
              tooltip: 'Vider le panier',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () {
                setState(() {
                  _basket.clear();
                });
                _recomputeOptimization();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar to add drugs
          Container(
            color: AppTheme.primaryDark,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ajouter un médicament (ex: Doliprane, Inexium...)',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white70),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.15),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Autocomplete search results overlay
          if (_isSearching && _searchResults.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              color: Colors.white,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, index) {
                  final drug = _searchResults[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE8F5E9),
                      child: Icon(Icons.medication, color: AppTheme.pharmacyGreen),
                    ),
                    title: Text(drug.brandName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${drug.dciName} • ${drug.dosage}'),
                    trailing: const Icon(Icons.add_circle, color: AppTheme.pharmacyGreen),
                    onTap: () => _addDrugToBasket(drug),
                  );
                },
              ),
            ),

          // 2. Basket Chips Row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Médicaments recherchés (${_basket.length})',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    if (_basket.isNotEmpty)
                      Text(
                        'Optimisation en direct ⚡',
                        style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_basket.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Votre ordonnance est vide. Tapez ci-dessus pour ajouter des médicaments.',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _basket.map((drug) {
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Text(
                            drug.brandName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.pharmacyGreen),
                          ),
                        ),
                        label: Text(
                          drug.brandName,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _removeDrugFromBasket(drug.id),
                        backgroundColor: const Color(0xFFE8F5E9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          // 3. Tab Bar (Single Stop vs Split Itinerary)
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.pharmacyGreen,
            unselectedLabelColor: Colors.black54,
            indicatorColor: AppTheme.pharmacyGreen,
            indicatorWeight: 3,
            tabs: [
              Tab(
                icon: const Icon(Icons.storefront, size: 20),
                text: 'Pharmacie Unique (${singleOptions.where((o) => o.isFullMatch).length})',
              ),
              Tab(
                icon: const Icon(Icons.alt_route, size: 20),
                text: 'Combinaison 2 Pharmacies (${splitOptions.length})',
              ),
            ],
          ),

          // 4. Tab Views
          Expanded(
            child: _basket.isEmpty
                ? _buildEmptyState()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Single Stop
                      _buildSingleStopTab(singleOptions),
                      // Tab 2: Split Stop
                      _buildSplitStopTab(splitOptions),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.playlist_add_check, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Composez votre ordonnance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ajoutez 2 médicaments ou plus. Notre algorithme calculera la pharmacie la plus proche ayant 100% de votre ordonnance disponible en stock.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('+ Doliprane 1000'),
                  onPressed: () {
                    final d = _mockData.masterDrugs.firstWhere((d) => d.id == 'drug-1');
                    _addDrugToBasket(d);
                  },
                ),
                ActionChip(
                  label: const Text('+ Augmentin 1g'),
                  onPressed: () {
                    final d = _mockData.masterDrugs.firstWhere((d) => d.id == 'drug-3');
                    _addDrugToBasket(d);
                  },
                ),
                ActionChip(
                  label: const Text('+ Spasfon'),
                  onPressed: () {
                    final d = _mockData.masterDrugs.firstWhere((d) => d.id == 'drug-7');
                    _addDrugToBasket(d);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleStopTab(List<SingleStopResult> options) {
    if (options.isEmpty) {
      return const Center(
        child: Text('Aucune pharmacie trouvée avec ces médicaments.'),
      );
    }

    final fullMatches = options.where((o) => o.isFullMatch).toList();
    final partialMatches = options.where((o) => !o.isFullMatch).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (fullMatches.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppTheme.pharmacyGreen, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${fullMatches.length} officine(s) ont 100% de votre ordonnance disponible en stock.',
                    style: TextStyle(color: Colors.green.shade900, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...fullMatches.map((opt) => _buildSingleOptionCard(opt, isFullMatch: true)),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Aucune pharmacie n\'a 100% du panier en stock. Consultez l\'onglet "Combinaison 2 Pharmacies" pour un trajet complet.',
                    style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (partialMatches.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Disponibilités partielles :',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          ...partialMatches.take(5).map((opt) => _buildSingleOptionCard(opt, isFullMatch: false)),
        ],
      ],
    );
  }

  Widget _buildSingleOptionCard(SingleStopResult opt, {required bool isFullMatch}) {
    final pharmacy = opt.pharmacy;
    final pct = (opt.fulfillmentRate * 100).toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isFullMatch ? AppTheme.pharmacyGreen.withValues(alpha: 0.5) : Colors.grey.shade300,
          width: isFullMatch ? 1.5 : 1,
        ),
      ),
      elevation: isFullMatch ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pharmacy.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${pharmacy.municipality}, ${pharmacy.governorate} • ${opt.distanceKm.toStringAsFixed(1)} km',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFullMatch ? AppTheme.pharmacyGreen : Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isFullMatch ? '100% EN STOCK' : '$pct% EN STOCK',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Drugs list breakdown
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _basket.map((drug) {
                final inStock = opt.availableDrugIds.contains(drug.id);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: inStock ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: inStock ? Colors.green.shade200 : Colors.red.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        inStock ? Icons.check : Icons.close,
                        size: 12,
                        color: inStock ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        drug.brandName,
                        style: TextStyle(
                          fontSize: 11,
                          color: inStock ? Colors.green.shade900 : Colors.red.shade900,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.call, size: 16),
                    label: const Text('Appeler'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _makePhoneCall(pharmacy.phoneLandline),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.directions, size: 16),
                    label: const Text('Itinéraire'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _openDirections(pharmacy.latitude, pharmacy.longitude, pharmacy.name),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.timer, size: 16),
                    label: Text(
                      isFullMatch ? 'Bloquer 2h (Tout)' : 'Bloquer (${opt.availableDrugIds.length})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.pharmacyGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _reserveFullBasket(
                      pharmacyId: pharmacy.id,
                      pharmacyName: pharmacy.name,
                      drugIdsToReserve: opt.availableDrugIds,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitStopTab(List<SplitStopResult> splitOptions) {
    if (splitOptions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.done_all, size: 54, color: Colors.green.shade400),
              const SizedBox(height: 12),
              const Text(
                'Pas de scission requise',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Une seule officine suffit pour obtenir tous vos médicaments ! Consultez l\'onglet "Pharmacie Unique".',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: splitOptions.length,
      itemBuilder: (ctx, index) {
        final split = splitOptions[index];
        final ratePct = (split.combinedFulfillmentRate * 100).toInt();

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.alt_route, color: Colors.indigo, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Trajet 2 Arrêts • ${split.totalDistanceKm.toStringAsFixed(1)} km total',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: split.isFullMatch ? AppTheme.pharmacyGreen : Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$ratePct% COUVERT',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stop 1
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(radius: 10, backgroundColor: Colors.blue, child: Text('1', style: TextStyle(fontSize: 10, color: Colors.white))),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              split.pharmacyA.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          Text(
                            '${split.distanceToA.toStringAsFixed(1)} km',
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Prendre ici : ${split.pharmacyADrugIds.map((id) => _basket.firstWhere((d) => d.id == id, orElse: () => _basket.first).brandName).join(', ')}',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Stop 2
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(radius: 10, backgroundColor: Colors.purple, child: Text('2', style: TextStyle(fontSize: 10, color: Colors.white))),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              split.pharmacyB.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          Text(
                            '+${split.distanceAToB.toStringAsFixed(1)} km',
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Prendre ici : ${split.pharmacyBDrugIds.map((id) => _basket.firstWhere((d) => d.id == id, orElse: () => _basket.first).brandName).join(', ')}',
                        style: TextStyle(fontSize: 12, color: Colors.purple.shade900),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.directions, size: 14),
                        label: const Text('Itinéraire Stop 1', style: TextStyle(fontSize: 11)),
                        onPressed: () => _openDirections(split.pharmacyA.latitude, split.pharmacyA.longitude, split.pharmacyA.name),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.timer, size: 14),
                        label: const Text('Bloquer Stop 1', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.pharmacyGreen,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _reserveFullBasket(
                          pharmacyId: split.pharmacyA.id,
                          pharmacyName: split.pharmacyA.name,
                          drugIdsToReserve: split.pharmacyADrugIds,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
