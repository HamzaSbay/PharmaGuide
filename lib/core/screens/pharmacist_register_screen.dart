import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';
import '../../core/services/auth_service.dart';

class PharmacistRegisterScreen extends StatefulWidget {
  const PharmacistRegisterScreen({super.key});

  @override
  State<PharmacistRegisterScreen> createState() => _PharmacistRegisterScreenState();
}

class _PharmacistRegisterScreenState extends State<PharmacistRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cnopController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cnamController = TextEditingController();
  
  String? _selectedGouvernorat;
  String? _selectedMunicipalite;
  bool _acceptsCnam = false;
  bool _isLoading = false;

  final List<String> _gouvernorats = [
    'Tunis', 'Ariana', 'Ben Arous', 'Manouba', 'Nabeul', 'Zaghouan', 'Bizerte',
    'Béja', 'Jendouba', 'Le Kef', 'Siliana', 'Sousse', 'Monastir', 'Mahdia',
    'Sfax', 'Kairouan', 'Kasserine', 'Sidi Bouzid', 'Gabès', 'Medenine',
    'Tataouine', 'Gafsa', 'Tozeur', 'Kebili'
  ];
  final List<String> _municipalites = ['Centre Ville', 'La Marsa', 'Sahloul', 'Sakiet Ezzit'];

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      await AuthService().registerPharmacist(
        _nameController.text,
        _cnopController.text,
        _phoneController.text,
        'preuve_patente.pdf'
      );
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Inscription en attente'),
            content: const Text('Votre inscription a été soumise avec succès. Un administrateur vérifiera vos documents (CNOP, Patente) avant d\'activer votre compte.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              )
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cnopController.dispose();
    _phoneController.dispose();
    _cnamController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Inscription Pharmacien', style: TextStyle(color: AppTheme.darkSlate)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppTheme.darkSlate),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informations de la Pharmacie',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nom de la Pharmacie', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cnopController,
                        decoration: const InputDecoration(labelText: 'Numéro CNOP', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Gouvernorat', border: OutlineInputBorder()),
                        initialValue: _selectedGouvernorat,
                        items: _gouvernorats.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (v) => setState(() => _selectedGouvernorat = v),
                        validator: (v) => v == null ? 'Requis' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Municipalité', border: OutlineInputBorder()),
                        initialValue: _selectedMunicipalite,
                        items: _municipalites.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (v) => setState(() => _selectedMunicipalite = v),
                        validator: (v) => v == null ? 'Requis' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Téléphone Fixe', border: OutlineInputBorder()),
                        keyboardType: TextInputType.phone,
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Convention CNAM',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.pharmacyGreen),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Accepte CNAM Tiers-Payant'),
                        value: _acceptsCnam,
                        onChanged: (v) => setState(() => _acceptsCnam = v),
                        activeThumbColor: AppTheme.pharmacyGreen,
                      ),
                      if (_acceptsCnam) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _cnamController,
                          decoration: const InputDecoration(labelText: 'Numéro CNAM', border: OutlineInputBorder()),
                          validator: (v) => _acceptsCnam && v!.isEmpty ? 'Requis' : null,
                        ),
                      ],
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Votre compte sera activé après vérification de votre numéro CNOP et de votre patente par un administrateur.',
                                style: TextStyle(color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitRegistration,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Soumettre l\'inscription'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
