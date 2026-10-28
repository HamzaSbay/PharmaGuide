import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/theme.dart';
import '../../core/services/csv_mapper_service.dart';
import '../../core/services/mock_data_service.dart';

class CsvMapperScreen extends StatefulWidget {
  final String pharmacyId;

  const CsvMapperScreen({
    super.key,
    required this.pharmacyId,
  });

  @override
  State<CsvMapperScreen> createState() => _CsvMapperScreenState();
}

class _CsvMapperScreenState extends State<CsvMapperScreen> {
  final MockDataService _mockData = MockDataService();
  List<CsvMatchResult> _mappedResults = [];
  bool _isProcessing = false;
  bool _isSynced = false;
  String _currentFileName = '';

  final String _sampleSymphonieCsv = '''Designation_Produit,Code_PCT,Quantite_Stock
Doliprane 1000mg Tab,PCT-10492,40
Augmentin 1g/125mg,PCT-20381,15
Aspegic Sachet 500mg,PCT-10114,28
Gripex Gelule,PCT-10882,10
Spasfon Tab 80mg,PCT-30421,50
Voltaren 50mg,PCT-40112,5''';

  /// Process CSV raw text content
  void _processCsvText(String rawText, {String fileName = 'Fichier POS'}) {
    if (rawText.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _currentFileName = fileName;
    });

    final results = CsvMapperService.parseAndMapCsv(
      csvContent: rawText,
      catalog: _mockData.masterDrugs,
    );

    setState(() {
      _mappedResults = results;
      _isProcessing = false;
      _isSynced = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📊 ${results.length} lignes traitées depuis $fileName!'),
        backgroundColor: AppTheme.pharmacyGreen,
      ),
    );
  }

  /// Pick CSV/TXT file from disk using FilePicker
  Future<void> _pickCsvFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        String content = '';
        if (file.bytes != null) {
          try {
            content = utf8.decode(file.bytes!);
          } catch (_) {
            // Fallback for Windows-1252/Latin-1 encoded CSVs (common in French pharmacy software)
            content = String.fromCharCodes(file.bytes!);
          }
        }
        _processCsvText(content, fileName: file.name);
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      // Fallback to sample demo import
      _processCsvText(_sampleSymphonieCsv, fileName: 'Symphonie_Export_Sample.csv');
    }
  }

  /// Open Modal Dialog to Paste Raw Text / CSV directly
  void _openPasteTextDialog() {
    final controller = TextEditingController(text: _sampleSymphonieCsv);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.paste, color: AppTheme.pharmacyGreen),
            SizedBox(width: 8),
            Text('Coller du Texte / Fichier CSV POS'),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Copiez-collez vos lignes d\'inventaire d\'officine (Symphonie, PharmX ou texte brut):',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                maxLines: 10,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Code_PCT, Designation, Quantite...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
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
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _processCsvText(controller.text, fileName: 'Texte Collé');
            },
            icon: const Icon(Icons.check),
            label: const Text('Analyser & Mapper'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.pharmacyGreen),
          ),
        ],
      ),
    );
  }

  void _applyBulkSync() {
    int count = 0;
    for (var match in _mappedResults) {
      if (match.matchedDrug != null) {
        _mockData.updateStockQuantity(widget.pharmacyId, match.matchedDrug!.id, match.rawQuantity);
        count++;
      }
    }

    setState(() => _isSynced = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Synchro réussie: $count produits mis à jour dans l\'inventaire de l\'officine!'),
        backgroundColor: AppTheme.pharmacyGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Controls Bar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.pharmacyGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.table_chart, color: AppTheme.pharmacyGreen, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mapper d\'Inventaire CSV / Excel (Symphonie, PharmX)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.deepBlack),
                    ),
                    Text(
                      'Importez ou collez vos fichiers de stock officine avec correspondance automatique DCI & Code PCT.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _openPasteTextDialog,
                icon: const Icon(Icons.paste, size: 18),
                label: const Text('Coller du Texte CSV'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.deepBlack,
                  side: const BorderSide(color: AppTheme.deepBlack),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _pickCsvFile,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Parcourir Fichier CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.pharmacyGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Main View Content
          _isProcessing
              ? const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppTheme.pharmacyGreen),
                        SizedBox(height: 16),
                        Text('Analyse du fichier CSV & correspondance PCT...'),
                      ],
                    ),
                  ),
                )
              : _mappedResults.isEmpty
                  ? Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text(
                              'Aucun fichier CSV d\'Inventaire chargé',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.deepBlack),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Cliquez sur "Parcourir Fichier CSV" ou "Coller du Texte CSV" pour charger vos données d\'officine.',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _openPasteTextDialog,
                              icon: const Icon(Icons.edit_note),
                              label: const Text('Tester avec le Texte Exemple'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.pharmacyGreen),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Résultats du Mapping: ${_mappedResults.length} produits ($_currentFileName)',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.deepBlack),
                              ),
                              ElevatedButton.icon(
                                onPressed: _isSynced ? null : _applyBulkSync,
                                icon: Icon(_isSynced ? Icons.check : Icons.sync),
                                label: Text(_isSynced ? 'Stock Synchro Réussie' : 'Appliquer la Synchro Stock'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isSynced ? Colors.grey : AppTheme.pharmacyGreen,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Card(
                              elevation: 2,
                              child: ListView.separated(
                                padding: const EdgeInsets.all(12),
                                itemCount: _mappedResults.length,
                                separatorBuilder: (_, __) => const Divider(),
                                itemBuilder: (context, index) {
                                  final item = _mappedResults[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: item.matchedDrug != null
                                          ? AppTheme.pharmacyGreen.withValues(alpha: 0.15)
                                          : Colors.orange.withValues(alpha: 0.15),
                                      child: Icon(
                                        item.matchedDrug != null ? Icons.check : Icons.warning_amber,
                                        color: item.matchedDrug != null ? AppTheme.pharmacyGreen : Colors.orange,
                                      ),
                                    ),
                                    title: Text(
                                      item.rawDrugName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      item.matchedDrug != null
                                          ? 'Correspondance: ${item.matchedDrug!.brandName} (${item.matchedDrug!.pctCode}) • Score: ${(item.confidenceScore * 100).toInt()}%'
                                          : 'Non mappé: Aucun produit PCT correspondant',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: item.matchedDrug != null ? AppTheme.pharmacyGreen : Colors.orange,
                                      ),
                                    ),
                                    trailing: Text(
                                      'Stock: ${item.rawQuantity}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
        ],
      ),
    );
  }
}
