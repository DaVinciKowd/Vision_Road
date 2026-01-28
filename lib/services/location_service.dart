import 'package:geolocator/geolocator.dart';
import '../models/location.dart';

class LocationService {
  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check location permissions
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  // Request location permissions
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  // Get current location
  Future<Location> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check permissions
      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return Location(
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
    } catch (e) {
      throw Exception('Failed to get location: $e');
    }
  }

  // Get location stream (for continuous tracking)
  Stream<Location> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).map((position) => Location(
          latitude: position.latitude,
          longitude: position.longitude,
          altitude: position.altitude,
          accuracy: position.accuracy,
          timestamp: position.timestamp,
        ));
  }

  // Calculate distance between two locations
  double calculateDistance(Location loc1, Location loc2) {
    return loc1.distanceTo(loc2);
  }

  // Check if location is on STAR Tollway (approximate bounds)
  // TODO: Replace with actual STAR Tollway coordinates
  bool isOnStarTollway(Location location) {
    // Approximate STAR Tollway bounds
    // These are placeholder coordinates - replace with actual bounds
    const double minLat = 13.5;
    const double maxLat = 14.5;
    const double minLon = 120.5;
    const double maxLon = 121.5;

    return location.latitude >= minLat &&
        location.latitude <= maxLat &&
        location.longitude >= minLon &&
        location.longitude <= maxLon;
  }
}

