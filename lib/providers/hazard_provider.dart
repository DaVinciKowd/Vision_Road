import 'package:flutter/foundation.dart';
import '../models/road_hazard.dart';
import '../models/location.dart';
import '../services/hazard_service.dart';

class HazardProvider with ChangeNotifier {
  final HazardService _hazardService = HazardService();
  List<RoadHazard> _hazards = [];
  bool _isLoading = false;
  String? _error;

  List<RoadHazard> get hazards => _hazards;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get unresolved hazards
  List<RoadHazard> get unresolvedHazards =>
      _hazards.where((h) => !h.isResolved).toList();

  // Get hazards by type
  List<RoadHazard> getHazardsByType(HazardType type) =>
      _hazards.where((h) => h.type == type).toList();

  // Get hazards by severity
  List<RoadHazard> getHazardsBySeverity(HazardSeverity severity) =>
      _hazards.where((h) => h.severity == severity).toList();

  // Load hazards
  Future<void> loadHazards({
    Location? nearLocation,
    double? radiusInMeters,
    HazardType? type,
    bool? isResolved,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _hazards = await _hazardService.getHazards(
        nearLocation: nearLocation,
        radiusInMeters: radiusInMeters,
        type: type,
        isResolved: isResolved,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Report new hazard
  Future<bool> reportHazard({
    required HazardType type,
    required HazardSeverity severity,
    required Location location,
    String? description,
    String? imagePath,
    String? detectedBy,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final hazard = await _hazardService.reportHazard(
        type: type,
        severity: severity,
        location: location,
        description: description,
        imagePath: imagePath,
        detectedBy: detectedBy,
      );
      _hazards.add(hazard);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update hazard
  Future<bool> updateHazard(RoadHazard hazard) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedHazard = await _hazardService.updateHazard(hazard);
      final index = _hazards.indexWhere((h) => h.id == hazard.id);
      if (index != -1) {
        _hazards[index] = updatedHazard;
      }
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark hazard as resolved
  Future<bool> markAsResolved(String hazardId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final hazard = await _hazardService.markAsResolved(hazardId);
      final index = _hazards.indexWhere((h) => h.id == hazardId);
      if (index != -1) {
        _hazards[index] = hazard;
      }
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

