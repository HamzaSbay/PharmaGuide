import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DrugInteractionResult {
  final String drug1;
  final String drug2;
  final String severity; // CRITICAL, HIGH, MODERATE, LOW
  final String description;
  final String recommendation;

  DrugInteractionResult({
    required this.drug1,
    required this.drug2,
    required this.severity,
    required this.description,
    required this.recommendation,
  });

  factory DrugInteractionResult.fromJson(Map<String, dynamic> json) {
    return DrugInteractionResult(
      drug1: json['drug1'] ?? '',
      drug2: json['drug2'] ?? '',
      severity: json['severity'] ?? 'LOW',
      description: json['description'] ?? '',
      recommendation: json['recommendation'] ?? '',
    );
  }
}

class DrugInteractionService extends ChangeNotifier {
  static final DrugInteractionService _instance = DrugInteractionService._internal();
  factory DrugInteractionService() => _instance;
  DrugInteractionService._internal();

  List<DrugInteractionResult> _knownInteractions = [];
  bool _isLoaded = false;

  Future<void> init() async {
    if (_isLoaded) return;
    try {
      final jsonString = await rootBundle.loadString('assets/data/drug_interactions.json');
      final List<dynamic> list = jsonDecode(jsonString);
      _knownInteractions = list.map((item) => DrugInteractionResult.fromJson(item)).toList();
      _isLoaded = true;
      debugPrint('💊 [INTERACTION] Loaded ${_knownInteractions.length} drug interactions.');
    } catch (e) {
      debugPrint('⚠️ [INTERACTION] Error loading interaction data: $e');
      _knownInteractions = [];
    }
  }

  /// Check for interactions between a list of drug names or DCI names
  List<DrugInteractionResult> checkInteractions(List<String> drugNames) {
    final List<DrugInteractionResult> results = [];
    final cleanNames = drugNames.map((n) => n.trim().toLowerCase()).toList();

    for (final interaction in _knownInteractions) {
      final d1 = interaction.drug1.toLowerCase();
      final d2 = interaction.drug2.toLowerCase();

      bool hasD1 = cleanNames.any((n) => n.contains(d1) || d1.contains(n));
      bool hasD2 = cleanNames.any((n) => n.contains(d2) || d2.contains(n));

      if (hasD1 && hasD2) {
        results.add(interaction);
      }
    }

    return results;
  }
}
