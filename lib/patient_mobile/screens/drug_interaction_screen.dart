import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';
import '../../core/models/drug_model.dart';
import '../../core/services/drug_interaction_service.dart';
import '../../core/services/mock_data_service.dart';

class DrugInteractionScreen extends StatefulWidget {
  const DrugInteractionScreen({super.key});

  @override
  State<DrugInteractionScreen> createState() => _DrugInteractionScreenState();
}

class _DrugInteractionScreenState extends State<DrugInteractionScreen> {
  final MockDataService _mockData = MockDataService();
  final DrugInteractionService _interactionService = DrugInteractionService();

  final List<DrugModel> _selectedDrugs = [];
  List<DrugInteractionResult> _analysisResults = [];

  @override
  void initState() {
    super.initState();
    _interactionService.init();
  }

  void _runAnalysis() {
    final names = _selectedDrugs.map((d) => d.dciName.isNotEmpty ? d.dciName : d.brandName).toList();
    setState(() {
      _analysisResults = _interactionService.checkInteractions(names);
    });
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return Colors.red.shade700;
      case 'HIGH':
        return Colors.orange.shade800;
      case 'MODERATE':
        return Colors.amber.shade800;
      default:
        return AppTheme.pharmacyGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allDrugs = _mockData.masterDrugs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérificateur d\'Interactions'),
        backgroundColor: AppTheme.pharmacyGreen,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sélectionnez 2 médicaments ou plus pour vérifier les contre-indications:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.deepBlack),
            ),
            const SizedBox(height: 12),

            // Drug Picker Dropdown / Autocomplete
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<DrugModel>(
                    hint: const Text('Ajouter un médicament au panier de test...'),
                    isExpanded: true,
                    items: allDrugs.map((drug) {
                      return DropdownMenuItem(
                        value: drug,
                        child: Text('${drug.brandName} (${drug.dciName})'),
                      );
                    }).toList(),
                    onChanged: (drug) {
                      if (drug != null && !_selectedDrugs.contains(drug)) {
                        setState(() {
                          _selectedDrugs.add(drug);
                        });
                        _runAnalysis();
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Selected Drugs Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedDrugs.map((drug) {
                return Chip(
                  avatar: const Icon(Icons.medication, size: 16),
                  label: Text(drug.brandName),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _selectedDrugs.remove(drug);
                    });
                    _runAnalysis();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Results Section
            const Text('Résultats de l\'Analyse Médicamenteuse:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Expanded(
              child: _selectedDrugs.length < 2
                  ? const Center(
                      child: Text(
                        'Ajoutez au moins 2 médicaments pour démarrer l\'analyse des interactions.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : _analysisResults.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 56, color: AppTheme.pharmacyGreen),
                              SizedBox(height: 12),
                              Text(
                                'Aucune interaction majeure détectée entre ces médicaments.',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.pharmacyGreen),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Consultez toujours votre pharmacien en officine.',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _analysisResults.length,
                          itemBuilder: (ctx, idx) {
                            final res = _analysisResults[idx];
                            final color = _getSeverityColor(res.severity);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: color, width: 1.5),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.warning, color: color, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${res.drug1} ↔ ${res.drug2}',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                                          ),
                                        ),
                                        Chip(
                                          label: Text(res.severity, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                          backgroundColor: color,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(res.description, style: const TextStyle(fontSize: 13, color: AppTheme.deepBlack)),
                                    const Divider(height: 16),
                                    Row(
                                      children: [
                                        const Icon(Icons.info_outline, size: 14, color: AppTheme.pharmacyGreen),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Recommandation: ${res.recommendation}',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.pharmacyGreen),
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
      ),
    );
  }
}
