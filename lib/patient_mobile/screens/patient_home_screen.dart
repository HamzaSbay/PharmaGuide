import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';
import '../../core/models/drug_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/mock_data_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/sync_service.dart';
import 'drug_detail_screen.dart';
import 'drug_interaction_screen.dart';
import 'patient_profile_screen.dart';
import 'pharmacy_results_screen.dart';
import 'active_holds_screen.dart';
import 'tunisia_map_screen.dart';
import 'prescription_ocr_modal.dart';
import 'offline_phonebook_modal.dart';
import 'multi_drug_basket_screen.dart';
import 'emergency_guard_navigator_screen.dart';
import 'barcode_scanner_modal.dart';
import 'family_profiles_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> with SingleTickerProviderStateMixin {
  final MockDataService _mockData = MockDataService();
  final SyncService _syncService = SyncService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  List<DrugModel> _searchResults = [];
  double _radiusKm = 15.0;
  bool _requiresCnam = false;
  bool _onlyGarde = false;
  String _selectedCategory = 'Tous';

  final List<String> _categories = [
    'Tous',
    'Fièvre & Douleur',
    'Cœur & Tension',
    'Jambes & Veines',
    'Yeux & Vision',
    'Estomac & Digestion',
    'Diabète & Métabolisme',
    'Infections & Antibio',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialDrugs();
    _syncService.addListener(_onSyncUpdate);
    _initLocation();
  }

  @override
  void dispose() {
    _syncService.removeListener(_onSyncUpdate);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSyncUpdate() {
    if (mounted) {
      _onSearchChanged(_searchController.text.trim());
    }
  }

  Future<void> _loadInitialDrugs() async {
    final results = await SupabaseService().searchDrugs('');
    if (mounted) {
      setState(() {
        _searchResults = _filterCategory(results);
      });
    }
  }

  Future<void> _initLocation() async {
    await LocationService().getCurrentLocation();
    if (mounted) {
      setState(() {});
    }
  }

  List<DrugModel> _filterCategory(List<DrugModel> drugs) {
    if (_selectedCategory == 'Tous') return drugs;
    return drugs.where((d) => d.category.toLowerCase().contains(_selectedCategory.toLowerCase())).toList();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final results = await SupabaseService().searchDrugs(query);
      if (mounted && query == _searchController.text.trim()) {
        setState(() {
          _searchResults = _filterCategory(results);
        });
      }
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _onSearchChanged(_searchController.text.trim());
  }

  void _navigateToDrugDetail(DrugModel drug) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DrugDetailScreen(drug: drug)),
    );
  }

  void _navigateToResults(DrugModel drug) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PharmacyResultsScreen(
          drug: drug,
          radiusKm: _radiusKm,
          requiresCnam: _requiresCnam,
          onlyGarde: _onlyGarde,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int activeHoldsCount = _mockData.reservations.where((r) => !r.isExpired).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: 'app_logo',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/app_logo.jpg',
                  width: 26,
                  height: 26,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.local_pharmacy, color: AppTheme.pharmacyGreen, size: 22),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'PharmaGuide TN',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          // 5-min Auto Sync Indicator Button
          AnimatedBuilder(
            animation: _syncService,
            builder: (context, _) {
              return Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sync,
                      size: 13,
                      color: _syncService.isSyncing ? AppTheme.pharmacyGreen : Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _syncService.isSyncing ? 'Synchro...' : '5 min',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.bookmark_outline, size: 22),
                tooltip: 'Mes Réservations',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ActiveHoldsScreen()),
                  );
                },
              ),
              if (activeHoldsCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.pharmacyGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$activeHoldsCount',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          // Profile Avatar Button
          IconButton(
            icon: const CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.pharmacyGreen,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
            tooltip: 'Mon Profil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PatientProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.pharmacyGreen,
        onRefresh: () async {
          await SyncService().syncNow();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Hero Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppTheme.deepBlack,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            'Localisateur de Médicaments',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const TunisiaMapScreen()),
                            );
                          },
                          icon: const Icon(Icons.map, size: 14),
                          label: const Text('Carte TN', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.pharmacyGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.pharmacyGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.pharmacyGreen.withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rocket_launch, size: 12, color: AppTheme.pharmacyGreen),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Lancement Pilote: Grand Tunis & Ariana (Couverture >85%) • 24 Gouvernorats',
                              style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EmergencyGuardNavigatorScreen()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.red.shade900,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.nightlight_round, size: 13, color: Colors.amberAccent),
                                  SizedBox(width: 4),
                                  Text('🚨 Garde 24/7', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const FamilyProfilesScreen()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B5E20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.family_restroom, size: 13, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text('👨‍👩‍👧 Profils Famille', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => OfflinePhonebookModal.show(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade900,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.signal_cellular_connected_no_internet_4_bar, size: 12, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text('📶 Annuaire (0 4G)', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const DrugInteractionScreen()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade900,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.compare_arrows, size: 12, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text('🧪 Interactions', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Search Input Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Rechercher (Doliprane, Cœur, Yeux, Jambes)...',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          prefixIcon: const Icon(Icons.search, color: AppTheme.pharmacyGreen),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_searchController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                ),
                              IconButton(
                                icon: const Icon(Icons.qr_code_scanner, color: AppTheme.pharmacyGreen, size: 20),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                tooltip: 'Scanner le Code-Barres Boîte',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const BarcodeScannerModal()),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.camera_alt, color: AppTheme.pharmacyGreen, size: 20),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                tooltip: 'Numériser une Ordonnance (OCR)',
                                onPressed: () => PrescriptionOcrModal.show(context),
                              ),
                              const SizedBox(width: 4),
                            ],
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Hero Action Card: Prescription Basket Optimizer
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MultiDrugBasketScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.shopping_basket, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Trouver toute mon ordonnance',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.bolt, color: Colors.amber, size: 14),
                                    ],
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '1 arrêt garanti à 100% ou combinaison minimale de 2 officines',
                                    style: TextStyle(color: Colors.white70, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Category Filter Bar (Fever, Heart, Eyes, Legs, Stomach, Diabetes)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: AppTheme.pharmacyGreen,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.deepBlack,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.borderGrey),
                        onSelected: (val) => _onCategorySelected(cat),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              // Active Holds Quick Alert Banner
              if (activeHoldsCount > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ActiveHoldsScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.pharmacyGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.pharmacyGreen),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: AppTheme.pharmacyGreen),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Vous avez $activeHoldsCount blocage(s) actif(s) en cours.',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.pharmacyGreen),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.pharmacyGreen),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Filter Controls Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Filtres de Géolocalisation',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.deepBlack),
                            ),
                            Text(
                              '${_radiusKm.toInt()} km max',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.pharmacyGreen),
                            ),
                          ],
                        ),
                        Slider(
                          value: _radiusKm,
                          min: 2.0,
                          max: 50.0,
                          divisions: 24,
                          activeColor: AppTheme.pharmacyGreen,
                          onChanged: (val) => setState(() => _radiusKm = val),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: FilterChip(
                                label: const Text('CNAM Tiers-Payant'),
                                selected: _requiresCnam,
                                selectedColor: AppTheme.pharmacyGreen.withValues(alpha: 0.2),
                                checkmarkColor: AppTheme.pharmacyGreen,
                                onSelected: (val) => setState(() => _requiresCnam = val),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilterChip(
                                label: const Text('Pharmacie de Garde'),
                                selected: _onlyGarde,
                                selectedColor: AppTheme.deepBlack.withValues(alpha: 0.15),
                                checkmarkColor: AppTheme.deepBlack,
                                onSelected: (val) => setState(() => _onlyGarde = val),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Popular PCT Medicines Quick Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCategory == 'Tous'
                          ? 'Catalogue PCT Officiel (Tunisie)'
                          : 'Catégorie: $_selectedCategory',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.deepBlack),
                    ),
                    Text(
                      '${_searchResults.length} méd.',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              _searchResults.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'Aucun médicament trouvé dans "$_selectedCategory"',
                              style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                _mockData.addAvailabilityAlert(
                                  patientPhone: AuthService().currentUser?.phone ?? '+216',
                                  drugId: 'drug-1',
                                  drugName: _searchController.text.trim().isEmpty ? 'Médicament' : _searchController.text.trim(),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('🔔 Alerte activée ! Vous recevrez une notification dès qu\'une pharmacie réapprovisionne ce produit.'),
                                    backgroundColor: AppTheme.pharmacyGreen,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.notifications_active, size: 16),
                              label: const Text('M\'alerter dès disponibilité'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.pharmacyGreen,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final drug = _searchResults[index];
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 150 + (index * 20)),
                          child: ListTile(
                            tileColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppTheme.borderGrey),
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: drug.requiresPrescription
                                    ? AppTheme.accentAmber.withValues(alpha: 0.15)
                                    : AppTheme.pharmacyGreen.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.medication,
                                color: drug.requiresPrescription ? AppTheme.accentAmber : AppTheme.pharmacyGreen,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              drug.brandName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.deepBlack),
                            ),
                            subtitle: Text(
                              '${drug.category} • ${drug.dciName} (${drug.dosage})',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (drug.requiresPrescription)
                                  Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentAmber.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('Rx', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.accentAmber)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.info_outline, size: 18, color: AppTheme.pharmacyGreen),
                                    tooltip: 'Fiche Médicament',
                                    onPressed: () => _navigateToDrugDetail(drug),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.pharmacyGreen),
                                ],
                              ),
                            onTap: () => _navigateToResults(drug),
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 24),

              // Regulatory INPDP Legal Disclaimer Footer Notice
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade100,
                child: const Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.gavel, size: 14, color: AppTheme.textMuted),
                        SizedBox(width: 6),
                        Text(
                          'CONFORMITÉ ET LÉGISLATION SANITAIRE (TUNISIE)',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      '⚖️ PharmaGuide TN est un annuaire d\'information et d\'orientation officinale. Aucun médicament n\'est vendu, payé ou livré en ligne conformément à la législation tunisienne. Purge automatique des ordonnances sous 48h (INPDP).',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
