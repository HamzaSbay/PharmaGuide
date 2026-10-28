import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/theme.dart';
import '../../core/services/offline_emergency_service.dart';
import '../../core/services/sms_service.dart';

class OfflinePhonebookModal extends StatefulWidget {
  const OfflinePhonebookModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const OfflinePhonebookModal(),
    );
  }

  @override
  State<OfflinePhonebookModal> createState() => _OfflinePhonebookModalState();
}

class _OfflinePhonebookModalState extends State<OfflinePhonebookModal> {
  String _selectedGovernorate = 'Tunis';

  final List<String> _governorates = [
    'Tous', 'Tunis', 'Ariana', 'Ben Arous', 'Manouba', 'Nabeul', 'Zaghouan',
    'Bizerte', 'Béja', 'Jendouba', 'Le Kef', 'Siliana', 'Sousse', 'Monastir',
    'Mahdia', 'Sfax', 'Kairouan', 'Kasserine', 'Sidi Bouzid', 'Gabès',
    'Medenine', 'Tataouine', 'Gafsa', 'Tozeur', 'Kebili'
  ];

  Future<void> _makeCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final Uri uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible de lancer l\'appel téléphonique')),
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ [PHONE] Call launch error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'appel. Vérifiez les autorisations.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pharmacies = OfflineEmergencyService().getOfflinePharmacies(_selectedGovernorate);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.lightBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.signal_cellular_connected_no_internet_4_bar, color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📶 Annuaire d\'Urgence Hors-Ligne (0 4G)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    Text(
                      'Numéros fixes et adresses enregistrés en local sur votre téléphone',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Governorate Dropdown Selector
          Row(
            children: [
              const Icon(Icons.location_on, color: AppTheme.primaryTeal, size: 20),
              const SizedBox(width: 8),
              const Text('Gouvernorat:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderGrey),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedGovernorate,
                      isExpanded: true,
                      items: _governorates.map((gov) {
                        return DropdownMenuItem(
                          value: gov,
                          child: Text(gov, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedGovernorate = val);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: pharmacies.isEmpty
                ? const Center(child: Text('Aucune officine enregistrée pour ce gouvernorat.', style: TextStyle(color: AppTheme.textMuted)))
                : ListView.builder(
                    itemCount: pharmacies.length,
                    itemBuilder: (context, index) {
                      final p = pharmacies[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.local_pharmacy, color: AppTheme.pharmacyGreen, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      p.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                  if (p.isGarde)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: AppTheme.cnamBlue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                      child: const Text('GARDE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.cnamBlue)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('📍 ${p.address} (${p.governorate})', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        SmsService().launchFreeNativeSms(
                                          p.phoneLandline,
                                          'Bonjour Pharmacie ${p.name}, je vous contacte via PharmaGuide TN pour me renseigner sur la disponibilité d\'un médicament.',
                                        );
                                      },
                                      icon: const Icon(Icons.sms, size: 16),
                                      label: const Text('SMS (Gratuit)'),
                                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _makeCall(p.phoneLandline),
                                      icon: const Icon(Icons.phone, size: 16),
                                      label: Text(p.phoneLandline),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.pharmacyGreen,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
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
                  ),
          ),
        ],
      ),
    );
  }
}
