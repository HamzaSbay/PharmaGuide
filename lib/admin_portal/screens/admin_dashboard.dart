import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/theme.dart';
import '../../core/services/mock_data_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  final MockDataService _mockData = MockDataService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _mockData.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mockData.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pendingPharmacies = _mockData.pharmacies.where((p) => p.status == 'PENDING').toList();
    final approvedPharmacies = _mockData.pharmacies.where((p) => p.status == 'APPROVED').toList();
    final allDrugs = _mockData.masterDrugs;
    final totalHoldsToday = _mockData.reservations.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.deepBlack,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: AppTheme.pharmacyGreen),
            SizedBox(width: 10),
            Text('PharmaGuide TN - Portail Administrateur National'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.pharmacyGreen,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              child: Row(
                children: [
                  const Text('File d\'Approbation CNOP'),
                  if (pendingPharmacies.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(color: AppTheme.pharmacyGreen, shape: BoxShape.circle),
                      child: Text('${pendingPharmacies.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Catalogue PCT Officiel'),
            const Tab(text: 'Blacklist Psychotropes'),
            const Tab(text: 'Planning Garde National'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Executive Real-Time Metrics Bar
          Container(
            color: AppTheme.darkSlate,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            child: Row(
              children: [
                _buildMetricCard(
                  icon: Icons.storefront,
                  title: 'Officines CNOP',
                  value: '${approvedPharmacies.length}',
                  subtitle: '24 Gouvernorats',
                  color: AppTheme.pharmacyGreen,
                ),
                const SizedBox(width: 12),
                _buildMetricCard(
                  icon: Icons.people,
                  title: 'Utilisateurs App & Web',
                  value: '1,480',
                  subtitle: 'Patients Actifs',
                  color: Colors.lightBlueAccent,
                ),
                const SizedBox(width: 12),
                _buildMetricCard(
                  icon: Icons.timer,
                  title: 'Réservations 2H (Aujourd\'hui)',
                  value: '$totalHoldsToday',
                  subtitle: 'Blocages Garantis',
                  color: Colors.amberAccent,
                ),
                const SizedBox(width: 12),
                _buildMetricCard(
                  icon: Icons.inventory_2,
                  title: 'Inventaire Synchro',
                  value: '${_mockData.inventories.length}',
                  subtitle: 'Articles en Ligne',
                  color: Colors.purpleAccent,
                ),
              ],
            ),
          ),

          // Main Tabs View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Verification Queue Tab
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Demandes d\'Inscription en Attente de Vérification (CNOP & Patente)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.deepBlack),
                      ),
                      const SizedBox(height: 12),
                      pendingPharmacies.isEmpty
                          ? const Expanded(
                              child: Center(
                                child: Text('Aucune demande en attente de vérification.', style: TextStyle(color: AppTheme.textMuted)),
                              ),
                            )
                          : Expanded(
                              child: ListView.builder(
                                itemCount: pendingPharmacies.length,
                                itemBuilder: (context, index) {
                                  final p = pendingPharmacies[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: ListTile(
                                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('${p.cnopId} • ${p.address} • Tél: ${p.phoneLandline}'),
                                      trailing: ElevatedButton(
                                        onPressed: () => _mockData.approvePharmacy(p.id),
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.pharmacyGreen),
                                        child: const Text('Approuver & Activer'),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ],
                  ),
                ),

                // 2. PCT Catalogue Tab
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: allDrugs.length,
                    itemBuilder: (context, index) {
                      final drug = allDrugs[index];
                      return Card(
                        child: ListTile(
                          title: Text(drug.brandName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${drug.category} • ${drug.dciName} (${drug.dosage}) • ${drug.pctCode}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: drug.requiresPrescription ? Colors.amber.shade100 : AppTheme.pharmacyGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              drug.requiresPrescription ? 'Rx Obligatoire' : 'Vente Libre',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: drug.requiresPrescription ? Colors.amber.shade900 : AppTheme.pharmacyGreen,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 3. Blacklist Tab
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: allDrugs.length,
                    itemBuilder: (context, index) {
                      final drug = allDrugs[index];
                      return Card(
                        child: ListTile(
                          title: Text(drug.brandName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('DCI: ${drug.dciName} • ${drug.pctCode}'),
                          trailing: Switch(
                            value: drug.isBlacklisted,
                            activeTrackColor: Colors.red.withValues(alpha: 0.5),
                            thumbColor: WidgetStateProperty.resolveWith((states) => 
                              states.contains(WidgetState.selected) ? Colors.red : null),
                            onChanged: (val) => _mockData.toggleDrugBlacklist(drug.id),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 4. Live Planning Garde National Tab
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, color: AppTheme.pharmacyGreen),
                          const SizedBox(width: 8),
                          const Text(
                            'Planning National des Gardes CNOP (24 Gouvernorats)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.deepBlack),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                final result = await FilePicker.platform.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: ['csv', 'xlsx', 'xls'],
                                  withData: true,
                                );
                                if (result != null && result.files.isNotEmpty) {
                                  final fileName = result.files.first.name;
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('✅ Fichier "$fileName" importé! Roster CNOP mis à jour pour les 24 Gouvernorats.'),
                                      backgroundColor: AppTheme.pharmacyGreen,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('❌ Erreur d\'importation: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.upload_file, size: 16),
                            label: const Text('Importer Roster CNOP (Excel / CSV)'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.pharmacyGreen, foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _mockData.gardeShifts.length,
                          itemBuilder: (context, index) {
                            final shift = _mockData.gardeShifts[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppTheme.cnamBlue,
                                  child: Icon(Icons.nights_stay, color: Colors.white, size: 18),
                                ),
                                title: Text(shift.pharmacyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Gouvernorat: ${shift.governorate} • ${shift.notes}'),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.pharmacyGreen.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('CONFIRMÉ CNOP', style: TextStyle(color: AppTheme.pharmacyGreen, fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(subtitle, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
