import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';
import '../../core/models/drug_model.dart';

class GenericAlternativeModal extends StatelessWidget {
  final DrugModel requestedDrug;
  final List<DrugModel> alternatives;
  final Function(DrugModel) onSelectDrug;

  const GenericAlternativeModal({
    super.key,
    required this.requestedDrug,
    required this.alternatives,
    required this.onSelectDrug,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentAmber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.swap_horiz, color: AppTheme.accentAmber, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Équivalents Génériques Disponibles',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                    Text(
                      'Même molécule active DCI: ${requestedDrug.dciName}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.lightBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderGrey),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: AppTheme.primaryTeal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Le produit "${requestedDrug.brandName}" a une disponibilité limitée. Vous pouvez sélectionner un équivalent contenant le même principe actif (${requestedDrug.dciName}).',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: alternatives.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final alt = alternatives[index];
                return InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    onSelectDrug(alt);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.secondaryEmerald.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(10),
                      color: AppTheme.secondaryEmerald.withValues(alpha: 0.04),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.medication, color: AppTheme.secondaryEmerald, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alt.brandName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkSlate,
                                ),
                              ),
                              Text(
                                '${alt.dciName} - ${alt.dosage} (${alt.form})',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.secondaryEmerald),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
