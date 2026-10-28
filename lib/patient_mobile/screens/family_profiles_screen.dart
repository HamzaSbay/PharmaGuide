import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';
import '../../core/models/family_profile_model.dart';
import '../../core/models/drug_model.dart';
import '../../core/services/mock_data_service.dart';
import 'multi_drug_basket_screen.dart';

class FamilyProfilesScreen extends StatefulWidget {
  const FamilyProfilesScreen({super.key});

  @override
  State<FamilyProfilesScreen> createState() => _FamilyProfilesScreenState();
}

class _FamilyProfilesScreenState extends State<FamilyProfilesScreen> {
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

  void _showAddProfileDialog() {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String selectedRelation = 'Enfant';
    String? selectedCnam = 'Filière publique';
    String? nameError;
    String? ageError;
    String? weightError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1, color: AppTheme.pharmacyGreen),
              SizedBox(width: 8),
              Text('Ajouter un Membre'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nom & Prénom *',
                    hintText: 'Ex: Amine Ben Ali',
                    errorText: nameError,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Lien de parenté :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedRelation,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ['Moi', 'Père', 'Mère', 'Enfant', 'Conjoint', 'Autre'].map((rel) {
                    return DropdownMenuItem(value: rel, child: Text(rel));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedRelation = val);
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Âge (ans)',
                          hintText: 'Ex: 7',
                          errorText: ageError,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Poids (kg)',
                          hintText: 'Ex: 22.5',
                          errorText: weightError,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('Affiliation CNAM :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedCnam,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    'Filière publique',
                    'Filière privée (Médecin de famille)',
                    'Système de remboursement',
                    'Sans couverture CNAM',
                  ].map((cnam) {
                    return DropdownMenuItem(value: cnam, child: Text(cnam, style: const TextStyle(fontSize: 12)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedCnam = val);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: notesCtrl,
                  decoration: InputDecoration(
                    labelText: 'Allergies / Précautions',
                    hintText: 'Ex: Allergie Pénicilline, Asthme',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.pharmacyGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                bool hasError = false;
                final name = nameCtrl.text.trim();
                final ageText = ageCtrl.text.trim();
                final weightText = weightCtrl.text.trim();

                // Validate name
                if (name.length < 2) {
                  setDialogState(() => nameError = 'Veuillez saisir au moins 2 caractères');
                  hasError = true;
                } else {
                  setDialogState(() => nameError = null);
                }

                // Validate age if provided
                int? age;
                if (ageText.isNotEmpty) {
                  age = int.tryParse(ageText);
                  if (age == null || age < 0 || age > 120) {
                    setDialogState(() => ageError = '0 à 120 ans');
                    hasError = true;
                  } else {
                    setDialogState(() => ageError = null);
                  }
                } else {
                  setDialogState(() => ageError = null);
                }

                // Validate weight if provided
                double? weight;
                if (weightText.isNotEmpty) {
                  weight = double.tryParse(weightText.replaceAll(',', '.'));
                  if (weight == null || weight < 1 || weight > 300) {
                    setDialogState(() => weightError = '1 à 300 kg');
                    hasError = true;
                  } else {
                    setDialogState(() => weightError = null);
                  }
                } else {
                  setDialogState(() => weightError = null);
                }

                if (hasError) return;

                final details = <String>[];
                if (age != null) details.add('$age ans');
                if (weight != null) details.add('${weight.toStringAsFixed(1)} kg');
                if (notesCtrl.text.trim().isNotEmpty) details.add(notesCtrl.text.trim());

                _mockData.addFamilyProfile(
                  FamilyProfileModel(
                    id: 'fam-${DateTime.now().millisecondsSinceEpoch}',
                    displayName: name,
                    relation: selectedRelation,
                    cnamAffiliation: selectedCnam,
                    notes: details.isNotEmpty ? details.join(' • ') : null,
                  ),
                );

                Navigator.pop(ctx);
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    ).then((_) {
      nameCtrl.dispose();
      ageCtrl.dispose();
      weightCtrl.dispose();
      notesCtrl.dispose();
    });
  }

  void _showAddMedicationToProfileDialog(FamilyProfileModel profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
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
                  const SizedBox(height: 12),
                  Text(
                    'Traitements Chroniques : ${profile.displayName}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sélectionnez les médicaments à renouveler régulièrement :',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: _mockData.masterDrugs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final drug = _mockData.masterDrugs[index];
                        final isAssigned = profile.chronicMedicationIds.contains(drug.id);

                        return ListTile(
                          title: Text(drug.brandName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${drug.dciName} • ${drug.dosage}'),
                          trailing: Icon(
                            isAssigned ? Icons.check_box : Icons.check_box_outline_blank,
                            color: isAssigned ? AppTheme.pharmacyGreen : Colors.grey,
                          ),
                          onTap: () {
                            _mockData.toggleMedicationInProfile(profile.id, drug.id);
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profiles = _mockData.familyProfiles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profils Famille & Traitements'),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Ajouter un profil',
            icon: const Icon(Icons.person_add),
            onPressed: _showAddProfileDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Informative Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.family_restroom, color: AppTheme.pharmacyGreen, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Anticipation des Renouvellements CNAM',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'PharmaGuide vérifie automatiquement la disponibilité en stock des traitements chroniques de vos proches 5 jours avant épuisement.',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade800, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Family Members Cards
          if (profiles.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('Aucun membre enregistré'),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter le premier membre'),
                      onPressed: _showAddProfileDialog,
                    ),
                  ],
                ),
              ),
            )
          else
            ...profiles.map((profile) => _buildProfileCard(profile)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.pharmacyGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Nouveau Membre'),
        onPressed: _showAddProfileDialog,
      ),
    );
  }

  Widget _buildProfileCard(FamilyProfileModel profile) {
    final assignedDrugs = _mockData.masterDrugs
        .where((d) => profile.chronicMedicationIds.contains(d.id))
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryDark,
                  child: Text(
                    profile.displayName.isNotEmpty ? profile.displayName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            profile.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              profile.relation,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      if (profile.cnamAffiliation != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'CNAM : ${profile.cnamAffiliation}',
                          style: TextStyle(color: Colors.green.shade800, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                      if (profile.notes != null && profile.notes!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 12, color: AppTheme.textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                profile.notes!,
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: () {
                    _showProfileOptions(profile);
                  },
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Chronic Medications section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Traitements Chroniques (${assignedDrugs.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 14),
                  label: const Text('Gérer', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.pharmacyGreen,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () => _showAddMedicationToProfileDialog(profile),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (assignedDrugs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Aucun traitement chronique enregistré pour ce membre.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
              )
            else
              ...assignedDrugs.map((drug) => _buildMedicationRow(drug)),

            // Action: Pre-load Basket for this member
            if (assignedDrugs.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: Text('Trouver tout le traitement de ${profile.relation}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.pharmacyGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MultiDrugBasketScreen(initialDrugs: assignedDrugs),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationRow(DrugModel drug) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.medication_outlined, size: 18, color: AppTheme.pharmacyGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drug.brandName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  '${drug.dciName} • ${drug.dosage}',
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
          if (drug.isNationalRupture)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                'RUPTURE PCT',
                style: TextStyle(color: Colors.red.shade800, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            )
          else
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.black38),
        ],
      ),
    );
  }

  void _showProfileOptions(FamilyProfileModel profile) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Modifier le profil'),
              onTap: () {
                Navigator.pop(ctx);
                _showAddMedicationToProfileDialog(profile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Supprimer ce profil', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    title: const Text('Supprimer ce profil ?'),
                    content: Text('Voulez-vous vraiment supprimer le profil de ${profile.displayName} et tous ses traitements associés ?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          _mockData.removeFamilyProfile(profile.id);
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
  }
}
