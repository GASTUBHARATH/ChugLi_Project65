import 'package:geolocator/geolocator.dart';

/// Singleton location service used throughout the Zippi app.
///
/// Call [getCurrentLocation] to request permission + fetch GPS.
/// Access [latitude] / [longitude] any time after a successful fetch.
class LocationService {
  LocationService._();

  static final instance = LocationService._();

  Position? _lastPosition;

  Position? get lastPosition => _lastPosition;

  double? get latitude => _lastPosition?.latitude;

  double? get longitude => _lastPosition?.longitude;

  /// Requests location permission and fetches the current GPS position.
  ///
  /// Returns a [LocationResult] with a [LocationStatus] describing the outcome.
  Future<LocationResult> getCurrentLocation() async {
    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return const LocationResult(
          status: LocationStatus.serviceDisabled,
        );
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          status: LocationStatus.deniedForever,
        );
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          return const LocationResult(
            status: LocationStatus.denied,
          );
        }

        if (permission == LocationPermission.deniedForever) {
          return const LocationResult(
            status: LocationStatus.deniedForever,
          );
        }
      }

      // Permission granted — fetch position at high accuracy.
      _lastPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return LocationResult(
        status: LocationStatus.granted,
        position: _lastPosition,
      );
    } catch (e) {
      return LocationResult(
        status: LocationStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Opens the OS app-settings page so the user can grant location.
  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Distance in km between two lat/lon points (Haversine via geolocator).
  double distanceInKm(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000.0;
  }
}

enum LocationStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  error,
}

class LocationResult {
  final LocationStatus status;
  final Position? position;
  final String? error;

  const LocationResult({
    required this.status,
    this.position,
    this.error,
  });

  bool get isGranted => status == LocationStatus.granted;
}
