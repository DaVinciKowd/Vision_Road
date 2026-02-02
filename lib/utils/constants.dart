/// Application constants
class AppConstants {
  // API Configuration
  static const String apiBaseUrl = 'https://api.visionroad.com/api/v1';

  // Supabase Configuration (replace with your project values from Supabase dashboard)
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
  
  // STAR Tollway approximate bounds (TODO: Replace with actual coordinates)
  static const double starTollwayMinLat = 13.5;
  static const double starTollwayMaxLat = 14.5;
  static const double starTollwayMinLon = 120.5;
  static const double starTollwayMaxLon = 121.5;
  
  // Hazard detection settings
  static const double defaultHazardRadiusMeters = 5000.0; // 5km radius
  static const double minDetectionConfidence = 0.7; // 70% confidence threshold
  
  // Location settings
  static const double locationUpdateDistance = 10.0; // Update every 10 meters
  static const double locationAccuracy = 10.0; // Desired accuracy in meters
}

