import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/theme.dart';
import '../../core/models/chronic_reminder_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/mock_data_service.dart';

class ChronicRemindersModal extends StatefulWidget {
  const ChronicRemindersModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ChronicRemindersModal(),
    );
  }

  @override
  State<ChronicRemindersModal> createState() => _ChronicRemindersModalState();
}

class _ChronicRemindersModalState extends State<ChronicRemindersModal> {
  final MockDataService _mockData = MockDataService();

  void _reorderNow(ChronicReminderModel reminder) async {
    try {
      final success = await _mockData.createReservation(
        patientId: AuthService().currentUser?.id ?? 'patient-anonymous',
        patientPhone: reminder.patientPhone,
        pharmacyId: reminder.pharmacyId,
        drugId: reminder.drugId,
      );

      if (success && mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text('🎉 Réservation de renouvellement créée avec succès pour ${reminder.drugName} (Bloqué 2h)!'),
            backgroundColor: AppTheme.pharmacyGreen,
          ),
        );
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible de réserver ${reminder.drugName}. Vérifiez la disponibilité en stock.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminders = _mockData.chronicReminders;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
          const Row(
            children: [
              Icon(Icons.autorenew, color: AppTheme.pharmacyGreen, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💊 Rappels de Traitement Chronique',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      'Renouvellement automatique d\'ordonnance 30 jours (Diabète, Tension...)',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          Expanded(
            child: reminders.isEmpty
                ? const Center(
                    child: Text('Aucun traitement chronique enregistré.', style: TextStyle(color: AppTheme.textMuted)),
                  )
                : ListView.builder(
                    itemCount: reminders.length,
                    itemBuilder: (context, index) {
                      final rem = reminders[index];
                      final isDue = rem.isDueSoon;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isDue ? AppTheme.accentAmber : AppTheme.borderGrey,
                            width: isDue ? 1.5 : 1.0,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: (isDue ? AppTheme.accentAmber : AppTheme.primaryTeal).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.medication,
                                      color: isDue ? AppTheme.accentAmber : AppTheme.primaryTeal,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          rem.drugName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        Text(
                                          rem.dciName,
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (isDue ? AppTheme.accentAmber : AppTheme.pharmacyGreen).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isDue
                                          ? '⚠️ RECHARGE DANS ${rem.daysUntilRefill}J'
                                          : 'Recharge dans ${rem.daysUntilRefill}j',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isDue ? AppTheme.accentAmber : AppTheme.pharmacyGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '📍 Pharmacie Habituelle: ${rem.pharmacyName}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                              Text(
                                '📅 Prochain renouvellement: ${DateFormat("dd MMMM yyyy", "fr_FR").format(rem.nextRefillDate)}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _reorderNow(rem),
                                  icon: const Icon(Icons.replay, size: 18),
                                  label: const Text('🔄 Réserver à Nouveau (Bloquer 2h)'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.pharmacyGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
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
