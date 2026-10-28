import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/theme.dart';
import '../../core/services/ocr_scanner_service.dart';
import 'pharmacy_results_screen.dart';

class PrescriptionOcrModal extends StatefulWidget {
  const PrescriptionOcrModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const PrescriptionOcrModal(),
    );
  }

  @override
  State<PrescriptionOcrModal> createState() => _PrescriptionOcrModalState();
}

class _PrescriptionOcrModalState extends State<PrescriptionOcrModal> {
  final ImagePicker _picker = ImagePicker();
  bool _isScanning = false;
  OcrScanResult? _scanResult;
  XFile? _selectedImage;

  Future<void> _pickAndScanImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source);
      if (image == null) return;

      setState(() {
        _selectedImage = image;
        _isScanning = true;
        _scanResult = null;
      });

      final result = await OcrScannerService().scanPrescriptionImage(image.path);

      if (mounted) {
        setState(() {
          _scanResult = result;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la numérisation: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          const Row(
            children: [
              Icon(Icons.document_scanner, color: AppTheme.pharmacyGreen, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📷 Reconnaissance Optique d\'Ordonnance (OCR)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    Text(
                      'Détection automatique des médicaments manuscrits ou imprimés',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Upload Selection Buttons if no image picked yet
          if (_selectedImage == null) ...[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.pharmacyGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_a_photo, size: 64, color: AppTheme.pharmacyGreen),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Prenez en photo votre ordonnance médicale',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Notre scanner extrait les noms des médicaments et vérifie leur disponibilité instantanément.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickAndScanImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Choisir Photo'),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickAndScanImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Prendre Photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.pharmacyGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // Image Preview & Scan Results
            if (_isScanning) ...[
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppTheme.pharmacyGreen),
                      SizedBox(height: 20),
                      Text(
                        '🔍 Numérisation et analyse OCR en cours...',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Extraction des lignes de médicaments et correspondance PCT',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_scanResult != null) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.pharmacyGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '✅ Précision OCR: ${(_scanResult!.confidenceScore * 100).toInt()}%',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.pharmacyGreen),
                    ),
                  ),
                  if (_scanResult!.isSimulated) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Mode Démo',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => setState(() => _selectedImage = null),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Nouvelle Photo'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Extracted Raw Text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📝 Texte Extrait de l\'Ordonnance:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textMuted)),
                    const SizedBox(height: 4),
                    Text(
                      _scanResult!.rawText.trim(),
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace', height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                '💊 Médicaments Détectés en Stock:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryTeal),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: _scanResult!.matchedDrugs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'Aucun médicament correspondant trouvé',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.deepBlack),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Vérifiez la netteté de l\'image ou saisissez le nom directement dans la barre de recherche.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.search, size: 16),
                              label: const Text('Recherche Manuelle'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.pharmacyGreen,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _scanResult!.matchedDrugs.length,
                        itemBuilder: (context, index) {
                          final drug = _scanResult!.matchedDrugs[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppTheme.primaryTeal,
                                child: Icon(Icons.medication, color: Colors.white, size: 20),
                              ),
                              title: Text(drug.brandName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('DCI: ${drug.dciName} (${drug.dosage})'),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  final navigator = Navigator.of(context);
                                  navigator.pop();
                                  navigator.push(
                                    MaterialPageRoute(
                                      builder: (ctx) => PharmacyResultsScreen(drug: drug),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.pharmacyGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                child: const Text('Rechercher', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
