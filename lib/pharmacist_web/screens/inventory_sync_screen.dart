import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';
import '../../core/models/inventory_model.dart';
import '../../core/services/mock_data_service.dart';
import '../widgets/quick_stock_toggle.dart';

class InventorySyncScreen extends StatefulWidget {
  final String pharmacyId;

  const InventorySyncScreen({
    super.key,
    required this.pharmacyId,
  });

  @override
  State<InventorySyncScreen> createState() => _InventorySyncScreenState();
}

class _InventorySyncScreenState extends State<InventorySyncScreen> {
  final MockDataService _mockData = MockDataService();
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = '';

  @override
  void initState() {
    super.initState();
    _mockData.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mockData.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  void _openBarcodeScanDialog() {
    final barcodeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner, color: AppTheme.primaryTeal),
            SizedBox(width: 8),
            Text('Scanner / Saisir Code-Barres'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Scannez le code-barres avec votre lecteur USB ou saisissez-le manuellement:',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: barcodeCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Ex: 6111252100153 (EAN-13 / Code PCT)',
                  prefixIcon: const Icon(Icons.qr_code),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onSubmitted: (val) => _processBarcode(ctx, val.trim()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => _processBarcode(ctx, barcodeCtrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.pharmacyGreen),
            child: const Text('Valider'),
          ),
        ],
      ),
    ).then((_) => barcodeCtrl.dispose());
  }

  void _processBarcode(BuildContext dialogCtx, String barcode) {
    if (barcode.isEmpty) return;
    final drug = _mockData.findDrugByBarcode(barcode) ??
        _mockData.masterDrugs.cast<dynamic>().firstWhere(
          (d) => d.pctCode.toLowerCase() == barcode.toLowerCase(),
          orElse: () => null,
        );
    Navigator.pop(dialogCtx);
    if (drug != null) {
      // Show quantity input dialog
      final qtyCtrl = TextEditingController(text: '1');
      showDialog(
        context: context,
        builder: (ctx2) => AlertDialog(
          title: Text('📦 ${drug.brandName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('DCI: ${drug.dciName} (${drug.dosage})'),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantité à ajouter au stock',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) {
                  final qty = int.tryParse(qtyCtrl.text) ?? 0;
                  if (qty > 0) {
                    _mockData.updateStockQuantity(widget.pharmacyId, drug.id, qty);
                    Navigator.pop(ctx2);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('📷 ${drug.brandName} (${drug.pctCode}) — Stock mis à jour: +$qty un.'),
                        backgroundColor: AppTheme.secondaryEmerald,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                final qty = int.tryParse(qtyCtrl.text) ?? 0;
                if (qty > 0) {
                  _mockData.updateStockQuantity(widget.pharmacyId, drug.id, qty);
                  Navigator.pop(ctx2);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('📷 ${drug.brandName} (${drug.pctCode}) — Stock mis à jour: +$qty un.'),
                      backgroundColor: AppTheme.secondaryEmerald,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.pharmacyGreen),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ).then((_) => qtyCtrl.dispose());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Aucun médicament trouvé pour le code "$barcode"'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = _mockData.masterDrugs;
    final inventories = _mockData.inventories.where((i) => i.pharmacyId == widget.pharmacyId).toList();

    final filteredCatalog = catalog.where((d) {
      if (_filterQuery.isEmpty) return true;
      return d.brandName.toLowerCase().contains(_filterQuery.toLowerCase()) ||
          d.dciName.toLowerCase().contains(_filterQuery.toLowerCase()) ||
          d.pctCode.toLowerCase().contains(_filterQuery.toLowerCase());
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _filterQuery = val),
                  decoration: const InputDecoration(
                    labelText: 'Rechercher un médicament ou Code PCT...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              ElevatedButton.icon(
                onPressed: _openBarcodeScanDialog,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan Code-Barres WebCam'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Bascule Rapide de Stock (Top 10-20 Médicaments Forte Demande)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: filteredCatalog.length,
              itemBuilder: (context, index) {
                final drug = filteredCatalog[index];
                var inv = inventories.firstWhere(
                  (i) => i.drugId == drug.id,
                  orElse: () => InventoryModel(id: '', pharmacyId: widget.pharmacyId, drugId: drug.id, quantity: 0, lastUpdatedAt: DateTime.now()),
                );

                return QuickStockToggle(
                  drug: drug,
                  currentQuantity: inv.quantity,
                  pharmacyId: widget.pharmacyId,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
