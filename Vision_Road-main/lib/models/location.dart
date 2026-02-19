import 'dart:math' as math;

class Location {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final DateTime timestamp;

  Location({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Convert Location to JSON
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Create Location from JSON
  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      altitude: json['altitude']?.toDouble(),
      accuracy: json['accuracy']?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  // Calculate distance between two locations (in meters) using Haversine formula
  double distanceTo(Location other) {
    const double earthRadius = 6371000; // meters
    final double dLat = _toRadians(other.latitude - latitude);
    final double dLon = _toRadians(other.longitude - longitude);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(latitude)) *
            math.cos(_toRadians(other.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180);
}

