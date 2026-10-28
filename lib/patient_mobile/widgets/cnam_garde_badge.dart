import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';

class CnamGardeBadge extends StatelessWidget {
  final bool isCnam;
  final bool isGarde;

  const CnamGardeBadge({
    super.key,
    required this.isCnam,
    required this.isGarde,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (isCnam)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.pharmacyGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.pharmacyGreen.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: 13, color: AppTheme.pharmacyGreen),
                SizedBox(width: 4),
                Text(
                  'CNAM Tiers-Payant',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.pharmacyGreen,
                  ),
                ),
              ],
            ),
          ),
        if (isGarde)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.deepBlack.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.deepBlack.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.nightlight_round, size: 13, color: AppTheme.deepBlack),
                SizedBox(width: 4),
                Text(
                  'Pharmacie de Garde',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.deepBlack,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
