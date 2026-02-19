import 'location.dart';

enum HazardType {
  pothole,
  crack,
  debris,
  water,
  oil,
  other,
}

enum HazardSeverity {
  low,
  medium,
  high,
  critical,
}

class RoadHazard {
  final String id;
  final HazardType type;
  final HazardSeverity severity;
  final Location location;
  final String? description;
  final String? imagePath;
  final String? detectedBy; // User ID who detected it
  final DateTime detectedAt;
  final DateTime? reportedAt;
  final bool isVerified;
  final bool isResolved;

  RoadHazard({
    required this.id,
    required this.type,
    required this.severity,
    required this.location,
    this.description,
    this.imagePath,
    this.detectedBy,
    DateTime? detectedAt,
    this.reportedAt,
    this.isVerified = false,
    this.isResolved = false,
  }) : detectedAt = detectedAt ?? DateTime.now();

  // Convert RoadHazard to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'severity': severity.name,
      'location': location.toJson(),
      'description': description,
      'imagePath': imagePath,
      'detectedBy': detectedBy,
      'detectedAt': detectedAt.toIso8601String(),
      'reportedAt': reportedAt?.toIso8601String(),
      'isVerified': isVerified,
      'isResolved': isResolved,
    };
  }

  // Create RoadHazard from JSON
  factory RoadHazard.fromJson(Map<String, dynamic> json) {
    return RoadHazard(
      id: json['id'] ?? '',
      type: HazardType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => HazardType.other,
      ),
      severity: HazardSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => HazardSeverity.medium,
      ),
      location: Location.fromJson(json['location'] ?? {}),
      description: json['description'],
      imagePath: json['imagePath'],
      detectedBy: json['detectedBy'],
      detectedAt: json['detectedAt'] != null
          ? DateTime.parse(json['detectedAt'])
          : DateTime.now(),
      reportedAt: json['reportedAt'] != null
          ? DateTime.parse(json['reportedAt'])
          : null,
      isVerified: json['isVerified'] ?? false,
      isResolved: json['isResolved'] ?? false,
    );
  }

  // Create a copy with updated fields
  RoadHazard copyWith({
    String? id,
    HazardType? type,
    HazardSeverity? severity,
    Location? location,
    String? description,
    String? imagePath,
    String? detectedBy,
    DateTime? detectedAt,
    DateTime? reportedAt,
    bool? isVerified,
    bool? isResolved,
  }) {
    return RoadHazard(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      location: location ?? this.location,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      detectedBy: detectedBy ?? this.detectedBy,
      detectedAt: detectedAt ?? this.detectedAt,
      reportedAt: reportedAt ?? this.reportedAt,
      isVerified: isVerified ?? this.isVerified,
      isResolved: isResolved ?? this.isResolved,
    );
  }

  // Get display name for hazard type
  String get typeDisplayName {
    switch (type) {
      case HazardType.pothole:
        return 'Pothole';
      case HazardType.crack:
        return 'Crack';
      case HazardType.debris:
        return 'Debris';
      case HazardType.water:
        return 'Water';
      case HazardType.oil:
        return 'Oil Spill';
      case HazardType.other:
        return 'Other';
    }
  }

  // Get display name for severity
  String get severityDisplayName {
    switch (severity) {
      case HazardSeverity.low:
        return 'Low';
      case HazardSeverity.medium:
        return 'Medium';
      case HazardSeverity.high:
        return 'High';
      case HazardSeverity.critical:
        return 'Critical';
    }
  }
}

