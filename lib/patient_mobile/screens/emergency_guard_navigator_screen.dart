import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/theme.dart';
import '../../core/constants/tunisia_constants.dart';
import '../../core/models/pharmacy_model.dart';
import '../../core/services/mock_data_service.dart';
import 'emergency_broadcast_modal.dart';
import 'offline_phonebook_modal.dart';
import 'pharmacy_detail_screen.dart';

class EmergencyGuardNavigatorScreen extends StatefulWidget {
  const EmergencyGuardNavigatorScreen({super.key});

  @override
  State<EmergencyGuardNavigatorScreen> createState() => _EmergencyGuardNavigatorScreenState();
}

class _EmergencyGuardNavigatorScreenState extends State<EmergencyGuardNavigatorScreen> {
  final MockDataService _mockData = MockDataService();
  String _selectedGovernorate = 'Tous';
  Timer? _countdownTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _mockData.addListener(_onDataChanged);
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _mockData.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  List<PharmacyModel> _getEmergencyPharmacies() {
    return _mockData.pharmacies.where((p) {
      if (p.status != 'APPROVED') return false;
      final isGarde = p.isGarde || _mockData.isPharmacyOnGardeTonight(p.id);
      if (!isGarde) return false;

      if (_selectedGovernorate != 'Tous' &&
          p.governorate.toLowerCase() != _selectedGovernorate.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _makeCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('⚠️ [EMERGENCY] Call launch error: $e');
    }
  }

  Future<void> _openDirections(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('⚠️ [EMERGENCY] Directions launch error: $e');
    }
  }

  String _getShiftRemainingText() {
    // Night shift typically ends at 08:30 AM
    final now = _currentTime;
    DateTime endTarget;
    if (now.hour >= 19 || (now.hour == 19 && now.minute >= 30)) {
      // Tomorrow at 08:30
      endTarget = DateTime(now.year, now.month, now.day + 1, 8, 30);
    } else if (now.hour < 8 || (now.hour == 8 && now.minute < 30)) {
      // Today at 08:30
      endTarget = DateTime(now.year, now.month, now.day, 8, 30);
    } else {
      // Daytime: Sunday / 24h duty or next shift starts at 19:30
      endTarget = DateTime(now.year, now.month, now.day, 19, 30);
    }

    final diff = endTarget.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (now.hour >= 19 || now.hour < 8) {
      return 'Garde de nuit active • Ferme dans ${hours}h ${minutes}m (08:30)';
    } else {
      return 'Service continu / Garde jour • Relève dans ${hours}h ${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pharmacies = _getEmergencyPharmacies();

    return Scaffold(
      backgroundColor: const Color(0xFF121820),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.nightlight_round, color: Colors.amberAccent, size: 20),
            SizedBox(width: 8),
            Text('Urgences & Garde 24/7'),
          ],
        ),
        backgroundColor: const Color(0xFF1E2632),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Annuaire Téléphonique Hors-ligne',
            icon: const Icon(Icons.import_contacts, color: Colors.white70),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const OfflinePhonebookModal(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Live Urgent Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade900, const Color(0xFFB71C1C)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getShiftRemainingText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Filter Bar (Governorate selection)
          Container(
            color: const Color(0xFF1E2632),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppTheme.pharmacyGreen, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Gouvernorat :',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B3648),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedGovernorate,
                        dropdownColor: const Color(0xFF2B3648),
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        items: ['Tous', ...TunisiaConstants.governorates].map((gov) {
                          return DropdownMenuItem<String>(
                            value: gov,
                            child: Text(gov),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedGovernorate = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. SOS Emergency Broadcast Hero Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2632),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.campaign, color: Colors.amber, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Médicament vital introuvable ?',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lancez un appel d\'urgence CNOP à toutes les officines de nuit.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const EmergencyBroadcastModal(),
                      );
                    },
                    child: const Text('Alerte SOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),

          // 4. Emergency Pharmacies List
          Expanded(
            child: pharmacies.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shield_outlined, size: 64, color: Colors.white24),
                        const SizedBox(height: 12),
                        Text(
                          'Aucune pharmacie de garde enregistrée pour $_selectedGovernorate.',
                          style: const TextStyle(color: Colors.white60, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedGovernorate = 'Tous';
                            });
                          },
                          child: const Text('Afficher toutes les régions', style: TextStyle(color: AppTheme.pharmacyGreen)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: pharmacies.length,
                    itemBuilder: (ctx, index) {
                      final p = pharmacies[index];
                      return _buildEmergencyPharmacyCard(p);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyPharmacyCard(PharmacyModel p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1E2632),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppTheme.pharmacyGreen.withValues(alpha: 0.3)),
      ),
      elevation: 2,
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              p.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, color: AppTheme.pharmacyGreen, size: 16),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${p.address} • ${p.municipality}',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.redAccent.shade100),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'GARDE 24/7',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Colors.white12),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.call, size: 16),
                    label: const Text('Appeler Direct', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.pharmacyGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _makeCall(p.phoneLandline),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.directions, size: 16),
                    label: const Text('GPS Itinéraire', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.lightBlueAccent,
                      side: const BorderSide(color: Colors.lightBlueAccent),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _openDirections(p.latitude, p.longitude),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Voir fiche officine',
                  icon: const Icon(Icons.info_outline, color: Colors.white70),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PharmacyDetailScreen(pharmacy: p),
                      ),
                    );
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
