import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';
import '../../core/models/reservation_model.dart';
import '../../core/services/mock_data_service.dart';
import '../../core/services/sync_service.dart';
import '../widgets/reservation_card.dart';
import 'inventory_sync_screen.dart';
import 'csv_mapper_screen.dart';
import 'b2b_network_screen.dart';
import 'garde_calendar_screen.dart';
import '../widgets/dashboard_shortcuts.dart';

class PharmacistDashboard extends StatefulWidget {
  final String? pharmacyId;
  const PharmacistDashboard({super.key, this.pharmacyId});

  @override
  State<PharmacistDashboard> createState() => _PharmacistDashboardState();
}

class _PharmacistDashboardState extends State<PharmacistDashboard> with SingleTickerProviderStateMixin {
  final MockDataService _mockData = MockDataService();
  final SyncService _syncService = SyncService();
  late TabController _tabController;
  late String _currentPharmacyId;
  bool _isStoreOnline = true;

  @override
  void initState() {
    super.initState();
    _currentPharmacyId = widget.pharmacyId ?? 'ph-1';
    _tabController = TabController(length: 5, vsync: this);
    _mockData.addListener(_onDataChanged);
    _syncService.addListener(_onDataChanged);
  }



  @override
  void dispose() {
    _tabController.dispose();
    _mockData.removeListener(_onDataChanged);
    _syncService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  /// Express Counter Checkout Mode (F2 Hotkey / Barcode Scan)
  void _openRapidCounterModal() {
    final searchCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bolt, color: AppTheme.pharmacyGreen),
            SizedBox(width: 8),
            Text('⚡ Mode Comptoir Rapide (Décrémentation -1 Stock)'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Scannez le code-barres USB ou tapez la marque pour décrémenter 1 boîte du stock en 1 seconde:',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Scanner Code-Barres CIP / PCT ou taper Doliprane...',
                  prefixIcon: const Icon(Icons.qr_code_scanner, color: AppTheme.pharmacyGreen),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    final drug = _mockData.findDrugByBarcode(val.trim()) ??
                        _mockData.masterDrugs.cast<dynamic>().firstWhere(
                          (d) => d.brandName.toLowerCase().contains(val.trim().toLowerCase()),
                          orElse: () => null,
                        );
                    if (drug != null) {
                      _mockData.updateStockQuantity(_currentPharmacyId, drug.id, -1);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('⚡ Stock décrémenté (-1) pour ${drug.brandName}!'),
                          backgroundColor: AppTheme.pharmacyGreen,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Aucun médicament trouvé pour "$val"'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    ).then((_) => searchCtrl.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final pharmacy = _mockData.pharmacies.firstWhere(
      (p) => p.id == _currentPharmacyId,
      orElse: () => _mockData.pharmacies.first,
    );
    final myReservations = _mockData.reservations.where((r) => r.pharmacyId == _currentPharmacyId).toList();
    final pendingCount = myReservations.where((r) => r.status == ReservationStatus.pending).length;
    final emergencyBroadcasts = _mockData.emergencyBroadcasts;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.deepBlack,
        title: Row(
          children: [
            const Icon(Icons.storefront, color: AppTheme.pharmacyGreen),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pharmacy.name, style: const TextStyle(fontSize: 17, color: Colors.white)),
                Text(
                  'CNOP: ${pharmacy.cnopId} • ${pharmacy.governorate} • Statut: ${pharmacy.status}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Emergency Store Online / Offline Toggle
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Switch(
                  value: _isStoreOnline,
                  activeTrackColor: AppTheme.pharmacyGreen.withValues(alpha: 0.5),
                  thumbColor: WidgetStateProperty.resolveWith((states) => 
                    states.contains(WidgetState.selected) ? AppTheme.pharmacyGreen : null),
                  inactiveThumbColor: Colors.red,
                  onChanged: (val) {
                    setState(() => _isStoreOnline = val);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(val ? '🟢 Officine Basculée EN LIGNE (Ouverte)' : '🔴 Officine Basculée HORS LIGNE (Fermée)'),
                        backgroundColor: val ? AppTheme.pharmacyGreen : Colors.red,
                      ),
                    );
                  },
                ),
                Text(
                  _isStoreOnline ? 'OUVERT' : 'FERMÉ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _isStoreOnline ? AppTheme.pharmacyGreen : Colors.red,
                  ),
                ),
              ],
            ),
          ),

          // Express Rapid Counter Button (F2)
          ElevatedButton.icon(
            onPressed: _openRapidCounterModal,
            icon: const Icon(Icons.bolt, size: 16),
            label: const Text('Comptoir (F2)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.pharmacyGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(width: 8),

          IconButton(
            icon: Icon(
              Icons.sync,
              color: _syncService.isSyncing ? AppTheme.pharmacyGreen : Colors.white70,
            ),
            tooltip: 'Synchro Auto 5 min (Forcer)',
            onPressed: () => SyncService().syncNow(),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard, color: Colors.white70, size: 20),
            tooltip: 'Raccourcis clavier (Ctrl+?)',
            onPressed: () => ShortcutHelpOverlay.show(context),
          ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.pharmacyGreen,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              child: Row(
                children: [
                  const Text('File Réservations (2h)'),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$pendingCount',
                        style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Gestion & Scan Stock'),
            const Tab(text: 'Mapper CSV (POS Export)'),
            const Tab(text: 'Réseau Inter-Pharmacies B2B'),
            const Tab(text: '📅 Planning Garde CNOP'),
          ],
        ),
      ),
      body: DashboardShortcuts(
        tabController: _tabController,
        onRefresh: () => setState(() {}),
        child: Column(
        children: [
          // Stale Stock Health Score Banner
          Container(
            color: Colors.amber.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.health_and_safety, color: Colors.amber, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    '⚠️ Health Score Inventaire: 14 articles n\'ont pas été re-confirmés depuis 48h. Confirmez votre stock pour maintenir un classement prioritaire.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _mockData.confirmAllInventoryFresh(_currentPharmacyId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Inventaire re-confirmé à 100%! Health Score optimal.'),
                        backgroundColor: AppTheme.pharmacyGreen,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle, size: 14),
                  label: const Text('Tout Confirmer en Stock'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.pharmacyGreen, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),

          // Emergency Broadcast Alerts Banner (if any)
          if (emergencyBroadcasts.isNotEmpty) ...[
            Container(
              color: Colors.red.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.emergency, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '🚨 ALERTE URGENCE SECOURS: Patient cherche "${emergencyBroadcasts.last.drugName}" dans le gouvernorat (${emergencyBroadcasts.last.governorate}).',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Réponse transmise au patient par SMS!'),
                          backgroundColor: AppTheme.pharmacyGreen,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red.shade900),
                    child: const Text('Oui, Disponible en Stock'),
                  ),
                ],
              ),
            ),
          ],

          // Main Tabs View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Reservations Queue
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: myReservations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              const Text(
                                'Aucune réservation reçue',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Les demandes de blocage 2h de vos patients apparaîtront ici en temps réel.',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: myReservations.length,
                          itemBuilder: (context, index) {
                            final res = myReservations[index];
                            return ReservationCard(
                              reservation: res,
                            );
                          },
                        ),
                ),

                // 2. Inventory Management Screen
                InventorySyncScreen(pharmacyId: _currentPharmacyId),

                // 3. POS CSV Import Screen
                CsvMapperScreen(pharmacyId: _currentPharmacyId),

                // 4. B2B Inter-Pharmacy Network Screen
                B2bNetworkScreen(pharmacyId: _currentPharmacyId),

                // 5. Official CNOP Garde Calendar Screen
                GardeCalendarScreen(pharmacyId: _currentPharmacyId),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
