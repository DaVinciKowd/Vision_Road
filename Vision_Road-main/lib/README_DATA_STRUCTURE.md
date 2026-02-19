# Vision Road - Data Structure Documentation

## Overview
This document describes the data infrastructure added to the Vision Road project, including models, services, providers, and the object detection model placeholder.

## Project Structure

```
lib/
├── models/              # Data models
│   ├── user.dart
│   ├── location.dart
│   └── road_hazard.dart
├── services/            # Business logic services
│   ├── api_service.dart
│   ├── auth_service.dart
│   ├── location_service.dart
│   └── hazard_service.dart
├── providers/           # State management (Provider pattern)
│   ├── auth_provider.dart
│   ├── hazard_provider.dart
│   └── location_provider.dart
├── ml/                  # Machine Learning
│   └── object_detection_model.dart  # PLACEHOLDER - Replace with actual model
├── utils/               # Utilities
│   └── constants.dart
└── screens/             # UI screens (updated to use providers)
```

## Data Models

### User Model (`lib/models/user.dart`)
Represents a user account with:
- `id`: Unique user identifier
- `username`: User's username
- `email`: User's email address
- `phoneNumber`: User's phone number
- `createdAt` / `updatedAt`: Timestamps

### Location Model (`lib/models/location.dart`)
Represents a GPS location with:
- `latitude` / `longitude`: Coordinates
- `altitude`: Optional altitude
- `accuracy`: Optional accuracy in meters
- `timestamp`: When location was captured
- `distanceTo()`: Calculate distance to another location

### RoadHazard Model (`lib/models/road_hazard.dart`)
Represents a detected road hazard with:
- `id`: Unique hazard identifier
- `type`: HazardType enum (pothole, crack, debris, water, oil, other)
- `severity`: HazardSeverity enum (low, medium, high, critical)
- `location`: Location where hazard was detected
- `description`: Optional text description
- `imagePath`: Path to detection image
- `detectedBy`: User ID who detected it
- `detectedAt` / `reportedAt`: Timestamps
- `isVerified` / `isResolved`: Status flags

## Services

### ApiService (`lib/services/api_service.dart`)
Generic HTTP client for API communication:
- `get()`: GET requests
- `post()`: POST requests
- `put()`: PUT requests
- `delete()`: DELETE requests
- `uploadFile()`: File uploads

**TODO**: Update `baseUrl` with your actual API endpoint.

### AuthService (`lib/services/auth_service.dart`)
Handles authentication and user management:
- `signIn()`: User login
- `signUp()`: User registration
- `signOut()`: User logout
- `getCurrentUser()`: Get logged-in user
- `updateProfile()`: Update user profile
- `changePassword()`: Change password
- `forgotPassword()`: Password recovery

**Note**: Currently includes mock authentication for development when API is unavailable.

### LocationService (`lib/services/location_service.dart`)
Handles GPS location services:
- `getCurrentLocation()`: Get current GPS position
- `getLocationStream()`: Stream of location updates
- `isOnStarTollway()`: Check if location is on STAR Tollway

### HazardService (`lib/services/hazard_service.dart`)
Manages road hazard data:
- `reportHazard()`: Report a new hazard
- `getHazards()`: Get hazards with filters (location, type, resolved status)
- `getHazardById()`: Get specific hazard
- `updateHazard()`: Update hazard information
- `markAsResolved()`: Mark hazard as resolved
- `getLocalHazards()`: Get locally stored hazards (offline support)

## State Management (Providers)

### AuthProvider (`lib/providers/auth_provider.dart`)
Manages authentication state:
- `currentUser`: Currently logged-in user
- `isLoading`: Loading state
- `error`: Error messages
- `signIn()`, `signUp()`, `signOut()`: Authentication methods
- `updateProfile()`: Profile updates

### HazardProvider (`lib/providers/hazard_provider.dart`)
Manages road hazard state:
- `hazards`: List of all hazards
- `unresolvedHazards`: Filtered unresolved hazards
- `loadHazards()`: Load hazards with filters
- `reportHazard()`: Report new hazard
- `updateHazard()`: Update existing hazard
- `markAsResolved()`: Mark as resolved

### LocationProvider (`lib/providers/location_provider.dart`)
Manages location state:
- `currentLocation`: Current GPS location
- `isTracking`: Whether location tracking is active
- `getCurrentLocation()`: Get current location
- `startTracking()` / `stopTracking()`: Control location stream

## Object Detection Model (PLACEHOLDER)

### ObjectDetectionModel (`lib/ml/object_detection_model.dart`)

**⚠️ IMPORTANT: This is a PLACEHOLDER implementation. Replace with your actual ML model.**

The placeholder includes:
- `initialize()`: Load model (currently mocked)
- `detectHazards()`: Detect hazards in image file
- `detectHazardsFromBytes()`: Real-time detection from camera stream
- Mock detection for development

### To Integrate Your Model:

1. **Choose your ML framework:**
   - TensorFlow Lite: Use `tflite_flutter` package
   - PyTorch Mobile: Use `pytorch_lite` package
   - Custom model: Implement your own inference

2. **Update `initialize()` method:**
   ```dart
   Future<void> initialize() async {
     // Load your model file
     final modelPath = await _getModelPath();
     _interpreter = Interpreter.fromAsset(modelPath);
     _isInitialized = true;
   }
   ```

3. **Update `detectHazards()` method:**
   - Preprocess image (resize, normalize)
   - Run model inference
   - Parse outputs (bounding boxes, classes, confidence)
   - Convert to `DetectedHazard` objects

4. **Add model file to assets:**
   - Place model file in `assets/models/`
   - Update `pubspec.yaml` to include model file

5. **Update `_getModelPath()` method:**
   ```dart
   Future<String> _getModelPath() async {
     return 'assets/models/your_model.tflite';
   }
   ```

## Dependencies Added

The following packages were added to `pubspec.yaml`:
- `provider: ^6.1.1` - State management
- `shared_preferences: ^2.2.2` - Local storage
- `http: ^1.2.0` - HTTP client
- `google_maps_flutter: ^2.5.0` - Maps integration
- `location: ^5.0.3` - Location services
- `geolocator: ^10.1.0` - GPS positioning
- `image: ^4.1.3` - Image processing

## Usage Example

### Using Providers in Screens:

```dart
// Get current user
Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    final user = authProvider.currentUser;
    return Text(user?.username ?? 'Not logged in');
  },
)

// Report a hazard
final hazardProvider = Provider.of<HazardProvider>(context);
await hazardProvider.reportHazard(
  type: HazardType.pothole,
  severity: HazardSeverity.medium,
  location: currentLocation,
);
```

### Using Object Detection:

```dart
final detectionModel = ObjectDetectionModel();
await detectionModel.initialize();

final detectedHazards = await detectionModel.detectHazards(
  imageFile: imageFile,
  currentLocation: location,
);
```

## Next Steps

1. **Backend API**: Set up your backend API and update `ApiService.baseUrl`
2. **ML Model**: Replace placeholder with actual object detection model
3. **Maps Integration**: Integrate Google Maps in `homepage.dart`
4. **Camera Integration**: Add camera functionality for real-time detection
5. **Testing**: Add unit and integration tests

## Notes

- All services include fallback to local storage/mock data when API is unavailable (for development)
- Location services require proper permissions (handled in LocationService)
- The object detection model placeholder returns mock data - replace before production use

