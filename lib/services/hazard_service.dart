import '../models/road_hazard.dart';
import '../models/location.dart';
import 'api_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HazardService {
  static const String _hazardsKey = 'local_hazards';
  final ApiService _apiService = ApiService();

  // Report a new hazard
  Future<RoadHazard> reportHazard({
    required HazardType type,
    required HazardSeverity severity,
    required Location location,
    String? description,
    String? imagePath,
    String? detectedBy,
  }) async {
    try {
      // TODO: Replace with actual API endpoint
      final response = await _apiService.post('/hazards', {
        'type': type.name,
        'severity': severity.name,
        'location': location.toJson(),
        'description': description,
        'imagePath': imagePath,
        'detectedBy': detectedBy,
      });

      final hazard = RoadHazard.fromJson(response['hazard']);
      
      // Also save locally for offline access
      await _saveHazardLocally(hazard);
      
      return hazard;
    } catch (e) {
      // For development: save locally if API fails
      if (e.toString().contains('Network error')) {
        final hazard = RoadHazard(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: type,
          severity: severity,
          location: location,
          description: description,
          imagePath: imagePath,
          detectedBy: detectedBy,
          detectedAt: DateTime.now(),
        );
        await _saveHazardLocally(hazard);
        return hazard;
      }
      rethrow;
    }
  }

  // Get all hazards
  Future<List<RoadHazard>> getHazards({
    Location? nearLocation,
    double? radiusInMeters,
    HazardType? type,
    bool? isResolved,
  }) async {
    try {
      String endpoint = '/hazards?';
      if (nearLocation != null && radiusInMeters != null) {
        endpoint +=
            'lat=${nearLocation.latitude}&lon=${nearLocation.longitude}&radius=$radiusInMeters&';
      }
      if (type != null) {
        endpoint += 'type=${type.name}&';
      }
      if (isResolved != null) {
        endpoint += 'resolved=$isResolved&';
      }

      // TODO: Replace with actual API endpoint
      final response = await _apiService.get(endpoint);
      final List<dynamic> hazardsJson = response['hazards'] ?? [];
      
      return hazardsJson
          .map((json) => RoadHazard.fromJson(json))
          .toList();
    } catch (e) {
      // For development: return local hazards if API fails
      if (e.toString().contains('Network error')) {
        return await getLocalHazards();
      }
      rethrow;
    }
  }

  // Get hazard by ID
  Future<RoadHazard?> getHazardById(String id) async {
    try {
      // TODO: Replace with actual API endpoint
      final response = await _apiService.get('/hazards/$id');
      return RoadHazard.fromJson(response['hazard']);
    } catch (e) {
      // For development: check local storage if API fails
      if (e.toString().contains('Network error')) {
        final localHazards = await getLocalHazards();
        try {
          return localHazards.firstWhere((h) => h.id == id);
        } catch (_) {
          return null;
        }
      }
      rethrow;
    }
  }

  // Update hazard
  Future<RoadHazard> updateHazard(RoadHazard hazard) async {
    try {
      // TODO: Replace with actual API endpoint
      final response = await _apiService.put(
        '/hazards/${hazard.id}',
        hazard.toJson(),
      );
      
      final updatedHazard = RoadHazard.fromJson(response['hazard']);
      await _updateHazardLocally(updatedHazard);
      
      return updatedHazard;
    } catch (e) {
      // For development: update locally if API fails
      if (e.toString().contains('Network error')) {
        await _updateHazardLocally(hazard);
        return hazard;
      }
      rethrow;
    }
  }

  // Mark hazard as resolved
  Future<RoadHazard> markAsResolved(String hazardId) async {
    try {
      final hazard = await getHazardById(hazardId);
      if (hazard == null) {
        throw Exception('Hazard not found');
      }
      
      return await updateHazard(hazard.copyWith(isResolved: true));
    } catch (e) {
      rethrow;
    }
  }

  // Get local hazards (for offline access)
  Future<List<RoadHazard>> getLocalHazards() async {
    final prefs = await SharedPreferences.getInstance();
    final hazardsJson = prefs.getString(_hazardsKey);
    
    if (hazardsJson != null) {
      final List<dynamic> hazardsList = json.decode(hazardsJson);
      return hazardsList
          .map((json) => RoadHazard.fromJson(json))
          .toList();
    }
    
    return [];
  }

  // Save hazard locally
  Future<void> _saveHazardLocally(RoadHazard hazard) async {
    final hazards = await getLocalHazards();
    hazards.add(hazard);
    await _saveHazardsLocally(hazards);
  }

  // Update hazard locally
  Future<void> _updateHazardLocally(RoadHazard hazard) async {
    final hazards = await getLocalHazards();
    final index = hazards.indexWhere((h) => h.id == hazard.id);
    if (index != -1) {
      hazards[index] = hazard;
      await _saveHazardsLocally(hazards);
    }
  }

  // Save all hazards locally
  Future<void> _saveHazardsLocally(List<RoadHazard> hazards) async {
    final prefs = await SharedPreferences.getInstance();
    final hazardsJson = json.encode(
      hazards.map((h) => h.toJson()).toList(),
    );
    await prefs.setString(_hazardsKey, hazardsJson);
  }
}

