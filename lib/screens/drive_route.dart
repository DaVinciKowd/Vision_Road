import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'homepage.dart';
import 'navigation_camera_page.dart';

class DriveRoutePage extends StatefulWidget {
  final String destination;
  final LatLng destinationCoords; 
  final String? currentLocation;

  const DriveRoutePage({
    super.key,
    required this.destination,
    required this.destinationCoords,
    this.currentLocation,
  });

  @override
  State<DriveRoutePage> createState() => _DriveRoutePageState();
}

class _DriveRoutePageState extends State<DriveRoutePage> {
  String currentLocationName = 'Current Location';
  
  late GoogleMapController mapController;
  LatLng _userPosition = const LatLng(13.7565, 121.0583); 
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  String _distance = "Calculating...";

  // Use your same API key
  final String myApiKey = "AIzaSyBZSCo5G33DqWNFSYD-6Ggu7YMlsi99xiY";

  @override
  void initState() {
    super.initState();
    if (widget.currentLocation != null) {
      currentLocationName = widget.currentLocation!;
    }
    _initRouteDisplay();
  }

  Future<void> _initRouteDisplay() async {
    // 1. Get Current User Location
    Position position = await Geolocator.getCurrentPosition();
    _userPosition = LatLng(position.latitude, position.longitude);

    // 2. Setup Markers
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('origin'),
          position: _userPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: "Starting Point"),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: widget.destinationCoords,
          infoWindow: InfoWindow(title: widget.destination),
        ),
      };
    });

    // 3. Fetch the Route
    _fetchPolylinePoints();
  }

  void _fetchPolylinePoints() async {
    PolylinePoints polylinePoints = PolylinePoints(apiKey: myApiKey);
    
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(_userPosition.latitude, _userPosition.longitude),
        destination: PointLatLng(widget.destinationCoords.latitude, widget.destinationCoords.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      List<LatLng> roadPoints = result.points
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      // --- MANUAL DISTANCE CALCULATION ---
      // We loop through the polyline points and sum the distance between them
      double totalMeters = 0;
      for (int i = 0; i < roadPoints.length - 1; i++) {
        totalMeters += Geolocator.distanceBetween(
          roadPoints[i].latitude,
          roadPoints[i].longitude,
          roadPoints[i + 1].latitude,
          roadPoints[i + 1].longitude,
        );
      }

      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: roadPoints,
            color: const Color(0xFF21709D),
            width: 6,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        };
        
        // Convert to Kilometers and format
        double km = totalMeters / 1000;
        _distance = "${km.toStringAsFixed(1)} km";
      });

      // Adjust camera to show the entire route
      _zoomToFitRoute();
    } else {
      setState(() {
        _distance = "Route not found";
      });
      debugPrint("Polyline Error: ${result.errorMessage}");
    }
  }

  void _zoomToFitRoute() {
    // LatLngBounds requires the southwest point to be truly south and west of the northeast point
    double minLat = _userPosition.latitude < widget.destinationCoords.latitude ? _userPosition.latitude : widget.destinationCoords.latitude;
    double minLng = _userPosition.longitude < widget.destinationCoords.longitude ? _userPosition.longitude : widget.destinationCoords.longitude;
    double maxLat = _userPosition.latitude > widget.destinationCoords.latitude ? _userPosition.latitude : widget.destinationCoords.latitude;
    double maxLng = _userPosition.longitude > widget.destinationCoords.longitude ? _userPosition.longitude : widget.destinationCoords.longitude;

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // --- GOOGLE MAP ---
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: _userPosition, zoom: 14),
              onMapCreated: (controller) => mapController = controller,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              markers: _markers,
              polylines: _polylines,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),

          // --- TOP SEARCH BARS ---
          Positioned(
            top: 40,
            left: 17,
            right: 17,
            child: Center(
              child: Container(
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
                    // Start Location Row
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Image.asset('assets/maps-pin.png', width: 16, height: 21),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push<String>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomePage(pickingCurrentLocation: true),
                                ),
                              );
                              if (result != null) {
                                setState(() => currentLocationName = result);
                              }
                            },
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.70),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(color: const Color(0xFF21709D), width: 1),
                              ),
                              alignment: Alignment.centerLeft,
                              child: Text(currentLocationName, 
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Destination Row
                    Row(
                      children: [
                        Image.asset('assets/drive-dark.png', width: 23, height: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context, 2),
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.70),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(color: const Color(0xFF21709D), width: 1),
                              ),
                              alignment: Alignment.centerLeft,
                              child: Text(widget.destination, 
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 16),
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

          // --- BOTTOM NAVIGATION PANEL ---
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 130,
              padding: const EdgeInsets.only(bottom: 10),
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
                        const TextSpan(text: 'Distance: ', style: TextStyle(fontWeight: FontWeight.w600)),
                        TextSpan(text: _distance),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NavigationCameraPage(destination: widget.destination),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF21709D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Start Navigating',
                          style: TextStyle(fontSize: 20, fontFamily: 'Inter', color: Colors.white),
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