import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';
import '../../core/models/reservation_model.dart';
import '../../core/services/mock_data_service.dart';

class ActiveHoldsScreen extends StatefulWidget {
  const ActiveHoldsScreen({super.key});

  @override
  State<ActiveHoldsScreen> createState() => _ActiveHoldsScreenState();
}

class _ActiveHoldsScreenState extends State<ActiveHoldsScreen> {
  final MockDataService _mockData = MockDataService();

  @override
  void initState() {
    super.initState();
    _mockData.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _mockData.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.confirmed:
        return AppTheme.pharmacyGreen;
      case ReservationStatus.declined:
        return Colors.red;
      case ReservationStatus.collected:
        return Colors.blue;
      case ReservationStatus.expired:
        return Colors.grey;
      case ReservationStatus.pending:
        return Colors.amber.shade800;
    }
  }

  String _getStatusLabel(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.confirmed:
        return 'ACCEPTÉ (Prêt au guichet)';
      case ReservationStatus.declined:
        return 'REFUSÉ';
      case ReservationStatus.collected:
        return 'RETIRÉ EN OFFICINE';
      case ReservationStatus.expired:
        return 'EXPIRÉ (2h dépassé)';
      case ReservationStatus.pending:
        return 'EN ATTENTE DE CONFIRMATION';
    }
  }

  /// Generate a unique 6-digit counter code based on reservation ID
  String _getCounterCode(String resId) {
    int hash = resId.hashCode.abs() % 900000 + 100000;
    return 'PG-$hash';
  }

  void _confirmCancelReservation(ReservationModel res) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Annuler le blocage ?'),
          ],
        ),
        content: Text(
          'Voulez-vous vraiment annuler votre blocage de 2h pour "${res.drug?.brandName ?? "Médicament"}" ?\n\n'
          'Le médicament sera immédiatement remis à disposition des autres patients à la pharmacie ${res.pharmacy?.name ?? ""}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Non, conserver'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _mockData.updateReservationStatus(res.id, ReservationStatus.declined);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Blocage annulé pour ${res.drug?.brandName ?? "Médicament"}. Stock libéré.'),
                    backgroundColor: AppTheme.deepBlack,
                  ),
                );
              }
            },
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reservations = _mockData.reservations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Réservations & QR Code Guichet'),
        backgroundColor: AppTheme.pharmacyGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.pharmacyGreen,
        onRefresh: () async {
          setState(() {});
        },
        child: reservations.isEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2, size: 72, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucun blocage actif en cours',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.deepBlack),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Recherchez un médicament et cliquez sur "Réserver (2h)" pour obtenir votre QR Code de retrait en officine.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: reservations.length,
                itemBuilder: (context, index) {
                  final res = reservations[index];
                  final remaining = res.remainingTime;
                  final statusColor = _getStatusColor(res.status);
                  final counterCode = _getCounterCode(res.id);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                _getStatusLabel(res.status),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.timer, size: 16, color: AppTheme.pharmacyGreen),
                                const SizedBox(width: 4),
                                Text(
                                  '${remaining.inHours}h ${remaining.inMinutes % 60}m restant',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.pharmacyGreen,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          res.drug?.brandName ?? 'Médicament',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.deepBlack),
                        ),
                        Text(
                          'DCI: ${res.drug?.dciName ?? ""} • Dosage: ${res.drug?.dosage ?? ""}',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        ),
                        const Divider(height: 24),

                        // Counter Proof Box with 6-Digit Code & Visual QR Graphic
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.pharmacyGreen.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.pharmacyGreen.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              // Visual QR Box Code
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.deepBlack),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.qr_code_2, size: 48, color: AppTheme.deepBlack),
                                    Text('SCANNER', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'CODE GUICHET A MONTRER AU PHARMACIEN:',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      counterCode,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.pharmacyGreen,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Présentez ce code ou le QR Code au comptoir pour retirer votre boîte.',
                                      style: TextStyle(fontSize: 11, color: AppTheme.deepBlack),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.storefront, size: 16, color: AppTheme.pharmacyGreen),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                res.pharmacy?.name ?? 'Pharmacie',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.phone_in_talk, size: 14, color: AppTheme.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              'Tél: ${res.pharmacy?.phoneLandline ?? ""}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                        if (res.status == ReservationStatus.pending ||
                            res.status == ReservationStatus.confirmed) ...[
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _confirmCancelReservation(res),
                              icon: const Icon(Icons.cancel_outlined, size: 15, color: AppTheme.errorRed),
                              label: const Text(
                                'Annuler ce blocage',
                                style: TextStyle(
                                  color: AppTheme.errorRed,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }
}
