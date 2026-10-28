import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/theme.dart';
import '../../core/models/garde_shift_model.dart';
import '../../core/services/mock_data_service.dart';

class GardeCalendarScreen extends StatefulWidget {
  final String pharmacyId;

  const GardeCalendarScreen({
    super.key,
    required this.pharmacyId,
  });

  @override
  State<GardeCalendarScreen> createState() => _GardeCalendarScreenState();
}

class _GardeCalendarScreenState extends State<GardeCalendarScreen> {
  final MockDataService _mockData = MockDataService();
  DateTime _selectedDate = DateTime.now();
  GardeType _selectedShiftType = GardeType.nuit;

  void _addShift() {
    // Prevent declaring shifts in the past
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    if (_selectedDate.isBefore(todayMidnight)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Impossible de déclarer une garde pour une date passée.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final existingIndex = _mockData.gardeShifts.indexWhere(
      (s) => s.pharmacyId == widget.pharmacyId &&
             s.shiftDate.year == _selectedDate.year &&
             s.shiftDate.month == _selectedDate.month &&
             s.shiftDate.day == _selectedDate.day &&
             s.shiftType == _selectedShiftType,
    );

    if (existingIndex != -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Un tour de garde de ce type est déjà déclaré pour cette date !'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final pharmacy = _mockData.pharmacies.firstWhere(
      (p) => p.id == widget.pharmacyId,
      orElse: () => _mockData.pharmacies.first,
    );

    final newShift = GardeShiftModel(
      id: 'shift-${DateTime.now().millisecondsSinceEpoch}',
      pharmacyId: widget.pharmacyId,
      pharmacyName: pharmacy.name,
      governorate: pharmacy.governorate,
      shiftDate: _selectedDate,
      shiftType: _selectedShiftType,
      notes: _selectedShiftType == GardeType.nuit
          ? 'Garde Officielle de Nuit CNOP (19:30 - 08:30)'
          : 'Garde Dimanche & Jour Férié (24h)',
    );

    _mockData.addGardeShift(newShift);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📅 Garde CNOP enregistrée pour le ${DateFormat("dd/MM/yyyy").format(_selectedDate)}'),
        backgroundColor: AppTheme.pharmacyGreen,
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final myShifts = _mockData.gardeShifts.where((s) => s.pharmacyId == widget.pharmacyId).toList();
    final isOnGardeTonight = _mockData.isPharmacyOnGardeTonight(widget.pharmacyId);

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isOnGardeTonight
                      ? [AppTheme.cnamBlue, const Color(0xFF1E3A8A)]
                      : [AppTheme.primaryTeal, const Color(0xFF0F766E)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isOnGardeTonight ? Icons.nights_stay : Icons.calendar_month,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOnGardeTonight
                              ? '🌙 DE GARDE OFFICIELLE CE SOIR (19:30 - 08:30)'
                              : '📅 Planning Officiel des Gardes CNOP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isOnGardeTonight
                              ? 'Votre officine est signalée active en garde nocturne sur la carte des patients.'
                              : 'Gérez vos tours de garde de nuit et jours fériés selon le calendrier du Conseil National de l\'Ordre.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form to Add New Garde Shift
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.add_circle_outline, color: AppTheme.primaryTeal),
                        SizedBox(width: 8),
                        Text(
                          'Déclarer un Tour de Garde Officiel',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Date de Garde:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (picked != null) {
                                    setState(() => _selectedDate = picked);
                                  }
                                },
                                icon: const Icon(Icons.event),
                                label: Text(DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDate)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Type de Garde:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<GardeType>(
                                initialValue: _selectedShiftType,
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                items: const [
                                  DropdownMenuItem(value: GardeType.nuit, child: Text('🌙 Garde de Nuit (19:30 - 08:30)')),
                                  DropdownMenuItem(value: GardeType.dimancheFerie, child: Text('☀️ Dimanche & Jour Férié (24h)')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedShiftType = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _addShift,
                          icon: const Icon(Icons.save),
                          label: const Text('Enregistrer la Garde'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.pharmacyGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Scheduled Shifts List
            const Text(
              '📋 Vos Gardes Enregistrées ce Mois-ci',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.primaryTeal),
            ),
            const SizedBox(height: 12),

            if (myShifts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Column(
                  children: [
                    Icon(Icons.calendar_today, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('Aucune garde CNOP programmée pour votre officine.', style: TextStyle(color: Colors.grey, fontSize: 15)),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: myShifts.length,
                itemBuilder: (context, index) {
                  final shift = myShifts[index];
                  final isToday = shift.shiftDate.year == DateTime.now().year &&
                      shift.shiftDate.month == DateTime.now().month &&
                      shift.shiftDate.day == DateTime.now().day;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isToday ? AppTheme.pharmacyGreen : AppTheme.borderGrey,
                        width: isToday ? 2.0 : 1.0,
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isToday ? AppTheme.pharmacyGreen : AppTheme.cnamBlue).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          shift.shiftType == GardeType.nuit ? Icons.nights_stay : Icons.wb_sunny,
                          color: isToday ? AppTheme.pharmacyGreen : AppTheme.cnamBlue,
                        ),
                      ),
                      title: Text(
                        DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(shift.shiftDate),
                        style: TextStyle(fontWeight: FontWeight.bold, color: isToday ? AppTheme.pharmacyGreen : Colors.black),
                      ),
                      subtitle: Text(shift.notes, style: const TextStyle(fontSize: 13)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isToday)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppTheme.pharmacyGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                              child: const Text('EN COURS CE SOIR', style: TextStyle(color: AppTheme.pharmacyGreen, fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Supprimer ce créneau ?'),
                                  content: const Text('Cette action est irréversible. Confirmez-vous la suppression de ce créneau de garde ?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _mockData.removeGardeShift(shift.id);
                                        setState(() {});
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
