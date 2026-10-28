import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/theme.dart';
import '../../core/services/mock_data_service.dart';
import 'drug_detail_screen.dart';

class BarcodeScannerModal extends StatefulWidget {
  const BarcodeScannerModal({super.key});

  @override
  State<BarcodeScannerModal> createState() => _BarcodeScannerModalState();
}

class _BarcodeScannerModalState extends State<BarcodeScannerModal> {
  final MobileScannerController _controller = MobileScannerController();
  final MockDataService _mockData = MockDataService();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        _handleScannedCode(code);
        break;
      }
    }
  }

  void _handleScannedCode(String rawCode) {
    setState(() {
      _isProcessing = true;
    });

    final drug = _mockData.findDrugByBarcode(rawCode);

    if (drug != null) {
      // Found the drug in catalog
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DrugDetailScreen(drug: drug),
        ),
      );
    } else {
      // Code not recognized
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.qr_code_scanner, color: Colors.orange),
              SizedBox(width: 8),
              Text('Code Scanné'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Code : $rawCode',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ce code-barres n\'est pas encore associé directement dans le répertoire national PCT.',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('Scanner à nouveau'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.pharmacyGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Recherche Manuelle'),
            ),
          ],
        ),
      ).then((_) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      });
    }
  }

  // Quick-test emulator simulation helper
  void _simulateScan(String sampleBarcode) {
    _handleScannedCode(sampleBarcode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scanner Boîte de Médicament'),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'Flash',
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            tooltip: 'Changer de caméra',
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Mobile Camera View
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // 2. Reticle Overlay
          Center(
            child: Container(
              width: 280,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.pharmacyGreen, width: 2.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'EAN-13 / Datamatrix',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Instruction Banner at Top
          Positioned(
            top: 20,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white24),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.center_focus_strong, color: AppTheme.pharmacyGreen, size: 18),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Pointez l\'appareil vers le code-barres de la boîte',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Test Simulation Chips at Bottom (for emulators / desktop)
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Column(
              children: [
                const Text(
                  'Tester rapidement sans caméra :',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    ActionChip(
                      backgroundColor: Colors.white12,
                      label: const Text('Doliprane 1000', style: TextStyle(color: Colors.white, fontSize: 11)),
                      onPressed: () => _simulateScan('3400935824921'),
                    ),
                    ActionChip(
                      backgroundColor: Colors.white12,
                      label: const Text('Glucophage (Rupture)', style: TextStyle(color: Colors.white, fontSize: 11)),
                      onPressed: () => _simulateScan('3400936123456'),
                    ),
                    ActionChip(
                      backgroundColor: Colors.white12,
                      label: const Text('Metformine Saiph', style: TextStyle(color: Colors.white, fontSize: 11)),
                      onPressed: () => _simulateScan('6191234567890'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
