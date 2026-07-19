import 'package:flutter/foundation.dart';
import 'package:dart_geohash/dart_geohash.dart';
void main() {
  final hasher = GeoHasher();
  // New Delhi is ~ 28.6 lat, 77.2 lon
  debugPrint(hasher.encode(28.6139, 77.2090)); // if lat, lon -> it should start with t
  debugPrint(hasher.encode(77.2090, 28.6139)); // if lon, lat -> it will be different
}
