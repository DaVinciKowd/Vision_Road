import 'package:flutter/foundation.dart';
import '../models/location.dart';
import '../services/location_service.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  Location? _currentLocation;
  bool _isLoading = false;
  String? _error;
  bool _isTracking = false;

  Location? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isTracking => _isTracking;

  // Get current location
  Future<void> getCurrentLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentLocation = await _locationService.getCurrentLocation();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Start location tracking
  void startTracking() {
    if (_isTracking) return;

    _isTracking = true;
    notifyListeners();

    _locationService.getLocationStream().listen(
      (location) {
        _currentLocation = location;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isTracking = false;
        notifyListeners();
      },
    );
  }

  // Stop location tracking
  void stopTracking() {
    _isTracking = false;
    notifyListeners();
  }

  // Check if on STAR Tollway
  bool isOnStarTollway() {
    if (_currentLocation == null) return false;
    return _locationService.isOnStarTollway(_currentLocation!);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

