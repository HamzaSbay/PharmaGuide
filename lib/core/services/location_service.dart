import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService extends ChangeNotifier {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _currentPosition;
  bool _isLoading = false;
  String? _errorMessage;

  // Default Fallback (Tunis Habib Bourguiba)
  static const double defaultLat = 36.8002;
  static const double defaultLng = 10.1860;

  Position? get currentPosition => _currentPosition;
  double get currentLat => _currentPosition?.latitude ?? defaultLat;
  double get currentLng => _currentPosition?.longitude ?? defaultLng;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasRealLocation => _currentPosition != null;

  /// Check permission and fetch live device GPS location with multi-tiered fallback
  Future<Position?> getCurrentLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'Services de géolocalisation désactivés sur le téléphone.';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'Permission de géolocalisation refusée.';
          _isLoading = false;
          notifyListeners();
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'Permission géolocalisation refusée dans les paramètres de l\'appareil.';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // Step 1: Try Last Known Position first (Instant response on Mobile)
      if (!kIsWeb) {
        Position? lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) {
          _currentPosition = lastPos;
          _isLoading = false;
          debugPrint('📍 [GPS] Last Known Location acquired: ${lastPos.latitude}, ${lastPos.longitude}');
          notifyListeners();
        }
      }

      Position? position;

      // Step 2: Fetch current GPS position with medium accuracy (Cellular + WiFi + Satellite)
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 6),
          ),
        );
      } catch (_) {
        // Fallback to low accuracy if satellite fix takes longer
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 4),
          ),
        );
      }

      _currentPosition = position;
      _isLoading = false;
      debugPrint('📍 [GPS] Real Live Location acquired: ${position.latitude}, ${position.longitude}');
      notifyListeners();
      return position;
    } catch (e) {
      debugPrint('📍 [GPS] Location fetch error: $e');
      _errorMessage = 'Impossible de récupérer la position GPS live.';
      _isLoading = false;
      notifyListeners();
      return _currentPosition;
    }
  }

  /// Calculate distance between two lat/lng points in kilometers
  double calculateDistanceKm(double startLat, double startLng, double endLat, double endLng) {
    double distanceInMeters = Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
    return distanceInMeters / 1000.0;
  }
}
