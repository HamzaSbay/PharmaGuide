import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/theme.dart';
import '../../core/models/pharmacy_model.dart';
import '../../core/services/location_service.dart';
import '../../core/services/mock_data_service.dart';
import 'pharmacy_detail_screen.dart';

class TunisiaMapScreen extends StatefulWidget {
  const TunisiaMapScreen({super.key});

  @override
  State<TunisiaMapScreen> createState() => _TunisiaMapScreenState();
}

class _TunisiaMapScreenState extends State<TunisiaMapScreen> {
  final MockDataService _mockData = MockDataService();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  String _selectedGovernorate = 'Tous';
  String _searchQuery = '';
  PharmacyModel? _selectedPharmacy;

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Error launching call: $e');
    }
  }

  Future<void> _openDirections(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching directions: $e');
    }
  }

  // Real GPS Center Coordinates for All 24 Governorates of Tunisia
  final Map<String, LatLng> _governorateCoordinates = {
    'Tous': const LatLng(34.0, 9.5), // Center of Tunisia
    'Tunis': const LatLng(36.8002, 10.1860),
    'Ariana': const LatLng(36.8625, 10.1956),
    'Ben Arous': const LatLng(36.7531, 10.2283),
    'Manouba': const LatLng(36.8101, 10.0956),
    'Nabeul': const LatLng(36.4561, 10.7376),
    'Zaghouan': const LatLng(36.4029, 10.1429),
    'Bizerte': const LatLng(37.2746, 9.8739),
    'Béja': const LatLng(36.7256, 9.1817),
    'Jendouba': const LatLng(36.5011, 8.7803),
    'Le Kef': const LatLng(36.1742, 8.7048),
    'Siliana': const LatLng(36.0849, 9.3708),
    'Sousse': const LatLng(35.8256, 10.6411),
    'Monastir': const LatLng(35.7780, 10.8260),
    'Mahdia': const LatLng(35.5047, 11.0622),
    'Sfax': const LatLng(34.7406, 10.7603),
    'Kairouan': const LatLng(35.6781, 10.0963),
    'Kasserine': const LatLng(35.1676, 8.8365),
    'Sidi Bouzid': const LatLng(35.0382, 9.4858),
    'Gabès': const LatLng(33.8815, 10.0982),
    'Medenine': const LatLng(33.3549, 10.5055),
    'Tataouine': const LatLng(32.9297, 10.4518),
    'Gafsa': const LatLng(34.4250, 8.7842),
    'Tozeur': const LatLng(33.9197, 8.1336),
    'Kebili': const LatLng(33.7044, 8.9690),
  };

  final List<String> _governorates = [
    'Tous',
    'Tunis',
    'Ariana',
    'Ben Arous',
    'Manouba',
    'Nabeul',
    'Zaghouan',
    'Bizerte',
    'Béja',
    'Jendouba',
    'Le Kef',
    'Siliana',
    'Sousse',
    'Monastir',
    'Mahdia',
    'Sfax',
    'Kairouan',
    'Kasserine',
    'Sidi Bouzid',
    'Gabès',
    'Medenine',
    'Tataouine',
    'Gafsa',
    'Tozeur',
    'Kebili',
  ];

  void _onGovernorateSelected(String gov) {
    setState(() {
      _selectedGovernorate = gov;
      _selectedPharmacy = null;
    });

    final targetCenter = _governorateCoordinates[gov] ?? const LatLng(34.0, 9.5);
    final double zoom = gov == 'Tous' ? 7.0 : 12.0;
    _mapController.move(targetCenter, zoom);
  }

  @override
  Widget build(BuildContext context) {
    final pharmacies = _mockData.pharmacies.where((p) {
      final matchesGov = _selectedGovernorate == 'Tous' ||
          p.governorate.toLowerCase() == _selectedGovernorate.toLowerCase();
      if (!matchesGov) return false;
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.address.toLowerCase().contains(q) ||
          p.municipality.toLowerCase().contains(q) ||
          p.phoneLandline.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.darkSlate,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.map_outlined, color: AppTheme.pharmacyGreen, size: 20),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Carte des Pharmacies TN (${pharmacies.length})',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, size: 20),
            tooltip: 'Ma Position GPS',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final pos = await LocationService().getCurrentLocation();
              final userLatLng = pos != null
                  ? LatLng(pos.latitude, pos.longitude)
                  : const LatLng(36.8002, 10.1860);

              if (!mounted) return;
              _mapController.move(userLatLng, 14.0);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    pos != null
                        ? '📍 Position GPS trouvée: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}'
                        : '📍 Position par défaut: Tunis Center (36.8002, 10.1860)',
                  ),
                  backgroundColor: AppTheme.pharmacyGreen,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input Bar
          Container(
            color: AppTheme.deepBlack,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Rechercher pharmacie, ville ou adresse...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                prefixIcon: const Icon(Icons.search, color: AppTheme.pharmacyGreen, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.pharmacyGreen),
                ),
              ),
            ),
          ),

          // Governorate Filter Bar with High Contrast Crisp Labels
          Container(
            color: AppTheme.deepBlack,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _governorates.map((gov) {
                  final isSelected = _selectedGovernorate == gov;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      showCheckmark: false,
                      label: Text(gov),
                      selected: isSelected,
                      selectedColor: AppTheme.pharmacyGreen,
                      backgroundColor: Colors.white,
                      elevation: isSelected ? 3 : 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      side: BorderSide(
                        color: isSelected ? AppTheme.pharmacyGreen : AppTheme.borderGrey,
                        width: 1.5,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.deepBlack,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (val) => _onGovernorateSelected(gov),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Live Interactive OpenStreetMap View of Tunisia
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: LatLng(36.8002, 10.1860), // Tunis Center
                    initialZoom: 7.5,
                    minZoom: 5.5,
                    maxZoom: 18.0,
                  ),
                  children: [
                    // Live OpenStreetMap Tile Layer
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.pharmaguide.tn.pharmaguide_tn',
                    ),

                    // Live Interactive Pharmacy Markers Layer
                    MarkerLayer(
                      markers: pharmacies.map((pharmacy) {
                        bool isSelected = _selectedPharmacy?.id == pharmacy.id;
                        bool isGardeTonight = _mockData.isPharmacyOnGardeTonight(pharmacy.id) || pharmacy.isGarde;

                        return Marker(
                          point: LatLng(pharmacy.latitude, pharmacy.longitude),
                          width: isSelected ? 48.0 : 38.0,
                          height: isSelected ? 48.0 : 38.0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPharmacy = pharmacy;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.deepBlack
                                    : (isGardeTonight ? AppTheme.cnamBlue : AppTheme.pharmacyGreen),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isGardeTonight ? AppTheme.cnamBlue : AppTheme.pharmacyGreen).withValues(alpha: 0.6),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Icon(
                                isGardeTonight ? Icons.nights_stay : Icons.local_pharmacy,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                // Bottom Selected Pharmacy Detail Sheet Overlay
                if (_selectedPharmacy != null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.verified, color: AppTheme.pharmacyGreen, size: 18),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _selectedPharmacy!.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppTheme.deepBlack,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _selectedPharmacy = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                            Text(
                              '📍 ${_selectedPharmacy!.address} (${_selectedPharmacy!.governorate})',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.phone_in_talk, size: 13, color: AppTheme.deepBlack),
                                const SizedBox(width: 4),
                                Text(
                                  _selectedPharmacy!.phoneLandline,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.deepBlack),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.access_time_filled, size: 13, color: AppTheme.pharmacyGreen),
                                const SizedBox(width: 4),
                                Text(
                                  _selectedPharmacy!.openingHours,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.pharmacyGreen),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (_selectedPharmacy!.acceptsCnam)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.pharmacyGreen.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('CNAM Conventionnée', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.pharmacyGreen)),
                                  ),
                                if (_selectedPharmacy!.isGarde || _mockData.isPharmacyOnGardeTonight(_selectedPharmacy!.id))
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cnamBlue,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.nights_stay, size: 12, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text('DE GARDE 24/7', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Action buttons: Appeler, Itinéraire, Voir Stock & Médicaments
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _makeCall(_selectedPharmacy!.phoneLandline),
                                    icon: const Icon(Icons.phone, size: 15),
                                    label: const Text('Appeler', style: TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.pharmacyGreen,
                                      side: const BorderSide(color: AppTheme.pharmacyGreen),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _openDirections(_selectedPharmacy!.latitude, _selectedPharmacy!.longitude),
                                    icon: const Icon(Icons.directions, size: 15),
                                    label: const Text('Itinéraire', style: TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.cnamBlue,
                                      side: const BorderSide(color: AppTheme.cnamBlue),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PharmacyDetailScreen(pharmacy: _selectedPharmacy!),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.inventory_2, size: 15),
                                    label: const Text('Stock & Médicaments', style: TextStyle(fontSize: 12, color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.pharmacyGreen,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
