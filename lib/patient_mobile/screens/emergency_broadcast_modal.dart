import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/mock_data_service.dart';

class EmergencyBroadcastModal extends StatefulWidget {
  final String initialDrugName;

  const EmergencyBroadcastModal({
    super.key,
    this.initialDrugName = '',
  });

  @override
  State<EmergencyBroadcastModal> createState() => _EmergencyBroadcastModalState();
}

class _EmergencyBroadcastModalState extends State<EmergencyBroadcastModal> {
  final TextEditingController _drugNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(
    text: AuthService().currentUser?.phone ?? '+216 ',
  );
  String _selectedGovernorate = 'Tunis';
  bool _isSubmitting = false;
  bool _isSuccess = false;

  final List<String> _governorates = [
    'Tunis', 'Ariana', 'Ben Arous', 'Manouba', 'Nabeul', 'Zaghouan', 'Bizerte', 'Béja',
    'Jendouba', 'Le Kef', 'Siliana', 'Sousse', 'Monastir', 'Mahdia', 'Sfax', 'Kairouan',
    'Kasserine', 'Sidi Bouzid', 'Gabès', 'Medenine', 'Tataouine', 'Gafsa', 'Tozeur', 'Kebili'
  ];

  @override
  void initState() {
    super.initState();
    _drugNameController.text = widget.initialDrugName;
  }

  @override
  void dispose() {
    _drugNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submitBroadcast() {
    final drugName = _drugNameController.text.trim();
    final phone = _phoneController.text.trim();

    if (drugName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez renseigner le nom du médicament recherché.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final phoneDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phoneDigits.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir un numéro de téléphone valide (8 chiffres).'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      MockDataService().addEmergencyBroadcast(
        drugName: drugName,
        governorate: _selectedGovernorate,
        patientPhone: phone,
      );

      setState(() {
        _isSubmitting = false;
        _isSuccess = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          width: 480,
          child: _isSuccess
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.pharmacyGreen.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cell_tower, color: AppTheme.pharmacyGreen, size: 48),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Demande de Secours Diffusée !',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.deepBlack),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Votre alerte pour "${_drugNameController.text}" a été transmise aux officines de $_selectedGovernorate.\n\nVous recevrez un SMS dès qu\'une pharmacie confirme la disponibilité.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.pharmacyGreen),
                      child: const Text('Fermer'),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.emergency, color: Colors.red, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Diffusion de Secours (Médicament Rare)',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.deepBlack),
                              ),
                              Text(
                                'Alertez toutes les officines du gouvernorat',
                                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 14),

                    const Text('Nom du Médicament / DCI / Traitement Spécialisé:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _drugNameController,
                      decoration: InputDecoration(
                        hintText: 'Ex: Traitement Oncologie / Oncocalcin 100UI',
                        prefixIcon: const Icon(Icons.medication, color: AppTheme.pharmacyGreen),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('Gouvernorat Cible pour la Broadcast:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGovernorate,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.location_city, color: AppTheme.pharmacyGreen),
                      ),
                      items: _governorates.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (val) => setState(() => _selectedGovernorate = val ?? 'Tunis'),
                    ),
                    const SizedBox(height: 14),

                    const Text('Téléphone Mobile pour la Réponse SMS:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.phone_android, color: AppTheme.pharmacyGreen),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitBroadcast,
                          icon: _isSubmitting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send_rounded),
                          label: const Text('Lancer la Broadcast'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
