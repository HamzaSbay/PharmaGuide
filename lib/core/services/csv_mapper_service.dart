import 'dart:math';
import 'package:csv/csv.dart';
import '../models/drug_model.dart';
import '../utils/fuzzy_search.dart';

class CsvMatchResult {
  final String rawDrugName;
  final String rawBarcodeOrCode;
  final int rawQuantity;
  final DrugModel? matchedDrug;
  final double confidenceScore;

  CsvMatchResult({
    required this.rawDrugName,
    required this.rawBarcodeOrCode,
    required this.rawQuantity,
    this.matchedDrug,
    required this.confidenceScore,
  });
}

class CsvMapperService {
  /// Parses raw CSV string and matches against PCT master drug catalog
  static List<CsvMatchResult> parseAndMapCsv({
    required String csvContent,
    required List<DrugModel> catalog,
    double minThreshold = 0.60,
  }) {
    List<List<dynamic>> csvData = const CsvToListConverter().convert(csvContent);
    if (csvData.isEmpty) return [];

    List<List<String>> rows = csvData.map((row) => row.map((cell) => cell.toString().trim()).toList()).toList();
    List<String> headers = rows.first;

    int nameCol = -1;
    int codeCol = -1;
    int qtyCol = -1;

    for (int i = 0; i < headers.length; i++) {
      String header = headers[i].toLowerCase();
      if (header.contains('nom') || header.contains('drug') || header.contains('designation') || header.contains('produit')) {
        nameCol = i;
      } else if (header.contains('code') || header.contains('pct') || header.contains('barcode') || header.contains('cip')) {
        codeCol = i;
      } else if (header.contains('qty') || header.contains('qte') || header.contains('stock') || header.contains('quantite')) {
        qtyCol = i;
      }
    }

    if (nameCol == -1) nameCol = 0;
    if (codeCol == -1 && headers.length > 1) codeCol = 1;
    if (qtyCol == -1 && headers.length > 2) qtyCol = 2;

    List<CsvMatchResult> results = [];

    for (int r = 1; r < rows.length; r++) {
      List<String> row = rows[r];
      if (row.isEmpty || row.length <= nameCol) continue;

      String rawName = row[nameCol];
      if (rawName.isEmpty) continue;

      String rawCode = (codeCol != -1 && row.length > codeCol) ? row[codeCol] : '';
      int rawQty = (qtyCol != -1 && row.length > qtyCol) ? (int.tryParse(row[qtyCol]) ?? 0) : 0;

      // Find best match in Master Drug catalog
      DrugModel? bestDrug;
      double highestScore = 0.0;

      for (var drug in catalog) {
        if (drug.pctCode.isNotEmpty && rawCode.isNotEmpty && drug.pctCode.toLowerCase() == rawCode.toLowerCase()) {
          bestDrug = drug;
          highestScore = 1.0;
          break;
        }

        double brandScore = FuzzySearch.similarityScore(rawName, drug.brandName);
        double dciScore = FuzzySearch.similarityScore(rawName, drug.dciName);
        double score = max(brandScore, dciScore);

        if (score > highestScore) {
          highestScore = score;
          bestDrug = drug;
        }
      }

      results.add(CsvMatchResult(
        rawDrugName: rawName,
        rawBarcodeOrCode: rawCode,
        rawQuantity: rawQty,
        matchedDrug: highestScore >= minThreshold ? bestDrug : null,
        confidenceScore: highestScore,
      ));
    }

    return results;
  }
}
