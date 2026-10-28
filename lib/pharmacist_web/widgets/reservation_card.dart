import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';
import '../../core/models/reservation_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/sms_service.dart';

class ReservationCard extends StatelessWidget {
  final ReservationModel reservation;

  const ReservationCard({
    super.key,
    required this.reservation,
  });

  void _showPrescriptionDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.description, color: AppTheme.primaryTeal),
            SizedBox(width: 8),
            Text('Ordonnance Médicale du Patient'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 300,
              width: double.maxFinite,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '🔒 INPDP Loi n° 2004-63: Image visible uniquement par le pharmacien. Supprimée automatiquement après 48h.',
              style: TextStyle(fontSize: 11, color: AppTheme.cnamBlue),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remaining = reservation.remainingTime;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: reservation.status == ReservationStatus.pending
              ? AppTheme.accentAmber
              : AppTheme.borderGrey,
          width: reservation.status == ReservationStatus.pending ? 1.5 : 1.0,
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person, color: AppTheme.primaryTeal, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient: ${reservation.patientPhone}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'Réservation N° ${reservation.id.substring(reservation.id.length - 6)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, size: 14, color: AppTheme.accentAmber),
                      const SizedBox(width: 4),
                      Text(
                        '${remaining.inMinutes} min',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentAmber),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.medication, color: AppTheme.secondaryEmerald, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.drug?.brandName ?? 'Médicament',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'DCI: ${reservation.drug?.dciName ?? ""} (${reservation.drug?.dosage ?? ""})',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                if (reservation.prescriptionImageUrl != null)
                  ElevatedButton.icon(
                    onPressed: () => _showPrescriptionDialog(context, reservation.prescriptionImageUrl!),
                    icon: const Icon(Icons.image, size: 16),
                    label: const Text('Ordonnance'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cnamBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (reservation.status == ReservationStatus.pending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Refuser la réservation ?'),
                            content: const Text('Voulez-vous vraiment refuser cette réservation ?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  SupabaseService().updateReservationStatus(reservation.id, ReservationStatus.declined);
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Refuser', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.close, color: AppTheme.errorRed, size: 18),
                      label: const Text('Refuser', style: TextStyle(color: AppTheme.errorRed)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.errorRed)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.sms, color: AppTheme.pharmacyGreen),
                    tooltip: 'Envoyer SMS au client (Gratuit)',
                    onPressed: () {
                      int hash = reservation.id.hashCode.abs() % 900000 + 100000;
                      SmsService().launchFreeNativeSms(
                        reservation.patientPhone,
                        'PharmaGuide TN: Votre réservation pour ${reservation.drug?.brandName ?? "Médicament"} est CONFIRMÉE (Valable 2h). Code Guichet: PG-$hash',
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        SupabaseService().updateReservationStatus(reservation.id, ReservationStatus.confirmed);
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Accepter (Bloquer 2h)'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.pharmacyGreen, foregroundColor: Colors.white),
                    ),
                  ),
                ],
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.lightBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Statut: ${reservation.status.name}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryTeal),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
