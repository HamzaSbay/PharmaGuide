import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/drug_model.dart';
import '../utils/fuzzy_search.dart';
import 'mock_data_service.dart';

class OcrScanResult {
  final String rawText;
  final List<DrugModel> matchedDrugs;
  final double confidenceScore;
  final bool isSimulated;
  final String? errorMessage;

  OcrScanResult({
    required this.rawText,
    required this.matchedDrugs,
    required this.confidenceScore,
    this.isSimulated = false,
    this.errorMessage,
  });
}

class OcrScannerService {
  static final OcrScannerService _instance = OcrScannerService._internal();
  factory OcrScannerService() => _instance;
  OcrScannerService._internal();

  /// Scans a prescription photo and extracts matching PCT catalog drugs using ML Kit
  Future<OcrScanResult> scanPrescriptionImage(String imagePath) async {
    debugPrint('📷 [OCR] Analyzing prescription image: $imagePath...');

    TextRecognizer? textRecognizer;

    try {
      textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      String rawText = recognizedText.text;
      double totalConfidence = 0.0;
      int blocksWithConfidence = 0;

      for (TextBlock block in recognizedText.blocks) {
        double? conf;
        try {
          conf = ((block as dynamic).confidence as num?)?.toDouble();
        } catch (_) {
          conf = null;
        }

        if (conf != null && conf > 0.0) {
          totalConfidence += conf;
          blocksWithConfidence++;
        }
      }

      double averageConfidence = blocksWithConfidence > 0
          ? (totalConfidence / blocksWithConfidence)
          : 0.85;

      final masterDrugs = MockDataService().masterDrugs;
      final List<DrugModel> matched = [];

      final lines = rawText
          .split('\n')
          .map((l) => l.trim().toLowerCase())
          .where((l) => l.isNotEmpty)
          .toList();

      for (var drug in masterDrugs) {
        final brandLower = drug.brandName.toLowerCase();
        final dciLower = drug.dciName.toLowerCase();
        bool matches = false;

        for (final line in lines) {
          if (line.contains(brandLower) ||
              (dciLower.isNotEmpty && line.contains(dciLower))) {
            matches = true;
            break;
          }

          // Check token-level fuzzy similarity on words with length >= 4
          final words = line.split(RegExp(r'[\s,\.;:\-\+]+'));
          for (final word in words) {
            if (word.length >= 4) {
              if (FuzzySearch.similarityScore(word, brandLower) >= 0.75 ||
                  (dciLower.isNotEmpty &&
                      FuzzySearch.similarityScore(word, dciLower) >= 0.75)) {
                matches = true;
                break;
              }
            }
          }
          if (matches) break;
        }

        if (matches && !matched.any((d) => d.id == drug.id)) {
          matched.add(drug);
        }
      }

      return OcrScanResult(
        rawText: rawText,
        matchedDrugs: matched,
        confidenceScore: averageConfidence,
        isSimulated: false,
      );
    } catch (e) {
      debugPrint('⚠️ [OCR] Real ML Kit failed ($e), falling back to mock: $e');
      return _mockScanFallback(errorMessage: e.toString());
    } finally {
      textRecognizer?.close();
    }
  }

  Future<OcrScanResult> _mockScanFallback({String? errorMessage}) async {
    // Simulate OCR text extraction delay (1.2 seconds)
    await Future.delayed(const Duration(milliseconds: 1200));

    // Simulated OCR extracted raw handwritten text from prescription
    const rawExtractedText = '''
Ordonnance Médicale CNAM
- Doliprane 1000mg comp - 1 cp 3x/jour
- Augmentin 1g sachet - 1 sachet 2x/jour
- Aprovel 150mg - 1 cp le matin
- Glucophage 1000mg - 1 cp au milieu du repas
''';

    final masterDrugs = MockDataService().masterDrugs;
    final List<DrugModel> matched = [];

    for (var drug in masterDrugs) {
      if (rawExtractedText.toLowerCase().contains(drug.brandName.toLowerCase())) {
        if (!matched.any((d) => d.id == drug.id)) {
          matched.add(drug);
        }
      }
    }

    return OcrScanResult(
      rawText: rawExtractedText,
      matchedDrugs: matched,
      confidenceScore: 0.94,
      isSimulated: true,
      errorMessage: errorMessage,
    );
  }
}
