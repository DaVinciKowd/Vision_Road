import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'homepage.dart';
import 'navigation_camera_page.dart';

class DriveRoutePage extends StatefulWidget {
  final String destination;
  final String? currentLocation;
  final LatLng? destinationPosition;
  final LatLng? currentPosition;

  const DriveRoutePage({
    super.key,
    required this.destination,
    this.currentLocation,
    this.destinationPosition,
    this.currentPosition,
  });

  @override
  State<DriveRoutePage> createState() => _DriveRoutePageState();
}

class _DriveRoutePageState extends State<DriveRoutePage> {
  static const LatLng _defaultUserPosition = LatLng(13.7565, 121.0583);
  static const LatLng _defaultDestinationPosition = LatLng(13.7800, 121.0700);
  
  // Note: Ensure your API key is restricted and valid
  static const String _googleApiKey = "AIzaSyBZSCo5G33DqWNFSYD-6Ggu7YMlsi99xiY";

  String currentLocation = 'Current Location';
  LatLng _userPosition = _defaultUserPosition;
  late LatLng _destinationPosition;

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  String _distanceLabel = 'Calculating...';
  String? _routeError;
  bool _isLoadingRoute = true;

  // Keys to measure UI for padding calculation if needed dynamically
  final GlobalKey _topBannerKey = GlobalKey();
  final GlobalKey _bottomPanelKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.currentLocation != null) {
      currentLocation = widget.currentLocation!;
    }

    _userPosition = widget.currentPosition ?? _defaultUserPosition;
    _destinationPosition =
        widget.destinationPosition ?? _inferDestinationPosition(widget.destination);

    _initializeRoute();
  }

  Future<void> _initializeRoute() async {
    await _determinePosition();
    await _buildRoute();
  }

  Future<void> _determinePosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _userPosition = LatLng(position.latitude, position.longitude);
      });
    } catch (_) {
      // Keep fallback location when GPS is unavailable.
    }
  }

  LatLng _inferDestinationPosition(String destinationLabel) {
    final lower = destinationLabel.toLowerCase();

    if (lower.contains('start')) {
      return const LatLng(13.8010, 121.1000);
    }

    if (lower.contains('star') ||
        lower.contains('tollway') ||
        lower.contains('batangas') ||
        lower.contains('autosweep')) {
      return const LatLng(13.7800, 121.0700);
    }

    return _defaultDestinationPosition;
  }

  Future<void> _buildRoute() async {
    if (!mounted) return;
    setState(() {
      _isLoadingRoute = true;
      _routeError = null;
    });

    final polylinePoints = PolylinePoints(apiKey: _googleApiKey);
    
    try {
      final result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(_userPosition.latitude, _userPosition.longitude),
          destination:
              PointLatLng(_destinationPosition.latitude, _destinationPosition.longitude),
          mode: TravelMode.driving,
        ),
      );

      final routePoints = result.points
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      final pointsForDistance = routePoints.isNotEmpty
          ? routePoints
          : [_userPosition, _destinationPosition];

      final distanceMeters = _computeRouteDistanceMeters(pointsForDistance);

      if (!mounted) return;
      setState(() {
        _markers = {
          Marker(
            markerId: const MarkerId('current_location'),
            position: _userPosition,
            infoWindow: InfoWindow(title: currentLocation),
          ),
          Marker(
            markerId: const MarkerId('destination'),
            position: _destinationPosition,
            infoWindow: InfoWindow(title: widget.destination),
          ),
        };

        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: pointsForDistance,
            color: routePoints.isNotEmpty
                ? const Color(0xFF21709D)
                : Colors.red.withOpacity(0.7),
            width: routePoints.isNotEmpty ? 5 : 3,
          ),
        };

        _distanceLabel = _formatDistance(distanceMeters);
        _routeError = routePoints.isEmpty
            ? (result.errorMessage ?? 'Unable to fetch road route.')
            : null;
        _isLoadingRoute = false;
      });

      _fitMapToRoute(pointsForDistance);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
          _routeError = "Error connecting to map services.";
        });
      }
    }
  }

  double _computeRouteDistanceMeters(List<LatLng> points) {
    if (points.length < 2) {
      return Geolocator.distanceBetween(
        _userPosition.latitude,
        _userPosition.longitude,
        _destinationPosition.latitude,
        _destinationPosition.longitude,
      );
    }

    double total = 0;
    for (int i = 0; i < points.length - 1; i++) {
      total += Geolocator.distanceBetween(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }
    return total;
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  void _fitMapToRoute(List<LatLng> points) {
    if (_mapController == null || points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // Because the GoogleMap widget now has 'padding' set in the build method,
    // this call will automatically center the bounds in the non-padded area.
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine screen offsets to prevent UI overlap on the map
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // MAP SECTION
          Positioned.fill(
            child: GoogleMap(
              // IMPORTANT: Padding ensures the Google logo, zoom buttons, 
              // and camera centers are offset so they aren't hidden by your UI.
              padding: EdgeInsets.only(
                top: 118 + statusBarHeight + 20, // Top Banner + Status Bar + Buffer
                bottom: 119 + bottomPadding + 10, // Bottom Panel + Extra Buffer
              ),
              initialCameraPosition: CameraPosition(
                target: _userPosition,
                zoom: 14,
              ),
              onMapCreated: (controller) {
                _mapController = controller;

                if (!_isLoadingRoute) {
                  final polylineList = _polylines.toList();
                  if (polylineList.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _fitMapToRoute(polylineList.first.points);
                    });
                  }
                }
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: _markers,
              polylines: _polylines,
            ),
          ),

          // TOP OVERLAY (Search/Location Banner)
          Positioned(
            top: 40,
            left: 17,
            right: 17,
            child: Center(
              child: Container(
                key: _topBannerKey,
                width: 383,
                height: 118,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.90),
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Image.asset(
                            'assets/maps-pin.png',
                            width: 16,
                            height: 21,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push<String>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomePage(
                                    pickingCurrentLocation: true,
                                  ),
                                ),
                              );

                              if (result != null) {
                                setState(() {
                                  currentLocation = result;
                                });
                                await _determinePosition();
                                await _buildRoute();
                              }
                            },
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.70),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: const Color(0xFF21709D),
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                currentLocation,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Image.asset(
                          'assets/drive-dark.png',
                          width: 23,
                          height: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context, 2);
                            },
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.70),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: const Color(0xFF21709D),
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                widget.destination,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // BOTTOM OVERLAY (Distance and Action Panel)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              key: _bottomPanelKey,
              height: 119,
              color: Colors.white.withOpacity(0.40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Color(0xFF21709D),
                      ),
                      children: [
                        const TextSpan(
                          text: 'Distance: ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: _isLoadingRoute ? 'Calculating...' : _distanceLabel,
                        ),
                      ],
                    ),
                  ),
                  if (_routeError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _routeError!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Inter',
                          color: Colors.red,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 49,
                      child: ElevatedButton(
                        onPressed: () {
                          final routePoints = _polylines.isNotEmpty
                              ? _polylines.first.points.toList()
                              : <LatLng>[];

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NavigationCameraPage(
                                destination: widget.destination,
                                destinationPosition: _destinationPosition,
                                routePoints: routePoints,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF21709D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Start Navigating',
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: 'Inter',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}