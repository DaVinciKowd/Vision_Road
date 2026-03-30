import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart'; 
import 'user_profile.dart';
import 'drive_route.dart';

class HomePage extends StatefulWidget {
  final bool pickingCurrentLocation;

  const HomePage({
    super.key,
    this.pickingCurrentLocation = false,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _profileImage;
  final TextEditingController _searchController = TextEditingController();
  bool _showResults = false;
  String? _selectedDestination;
  
  // NEW: Store the LatLng of the last selected place to pass to the next page
  LatLng? _lastSelectedLatLng;

  late GoogleMapController mapController;
  LatLng _userPosition = const LatLng(13.7565, 121.0583); 
  
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  final List<String> _keywords = ['star', 'tollway', 'batangas', 'autosweep'];
  final List<Map<String, dynamic>> _stateHistory = [];

  final String myApiKey = "AIzaSyBZSCo5G33DqWNFSYD-6Ggu7YMlsi99xiY";

  @override
  void initState() {
    super.initState();
    _determinePosition(); 
    
    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase().trim();
      setState(() {
        if (query.isEmpty) {
          _showResults = false;
        } else {
          _showResults = _keywords.any((word) => query.contains(word));
        }
      });
    });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _userPosition = LatLng(position.latitude, position.longitude);
    });

    mapController.animateCamera(CameraUpdate.newLatLngZoom(_userPosition, 14));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setDestination(LatLng position, String label) async {
    setState(() {
      _selectedDestination = label;
      _lastSelectedLatLng = position; // Save the coordinates here!
      _searchController.text = label;
      _markers = {
        Marker(
          markerId: const MarkerId('destination'),
          position: position,
          infoWindow: InfoWindow(title: label),
        ),
      };
    });

    PolylinePoints polylinePoints = PolylinePoints(apiKey: myApiKey);
    
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(_userPosition.latitude, _userPosition.longitude),
        destination: PointLatLng(position.latitude, position.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      List<LatLng> roadPoints = result.points
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: roadPoints, 
            color: const Color(0xFF21709D),
            width: 5,
            jointType: JointType.round,
          ),
        };
      });
    }

    mapController.animateCamera(CameraUpdate.newLatLngZoom(position, 14));
  }

  // Rest of your helper functions (getGreeting, _onSearchSubmitted, etc.) remain the same...
  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 18) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  void _onSearchSubmitted(String value) {
    final query = value.toLowerCase().trim();
    setState(() {
      _showResults = query.isNotEmpty && _keywords.any((word) => query.contains(word));
    });
  }

  List<String> _getResults() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return [];
    return [
      'STAR Tollway Batangas',
      'STAR Tollway (AutoSweep)',
      'STAR Tollway Start',
    ].where((item) => item.toLowerCase().contains(query)).toList();
  }

  void _saveCurrentState() {
    _stateHistory.add({
      'showResults': _showResults,
      'selectedDestination': _selectedDestination,
      'searchText': _searchController.text,
      'lastLatLng': _lastSelectedLatLng, // Save LatLng in history too
    });
  }

  void _restorePreviousState({int steps = 1}) {
    if (_stateHistory.length >= steps) {
      Map<String, dynamic>? state;
      for (int i = 0; i < steps; i++) {
        state = _stateHistory.removeLast();
      }
      setState(() {
        _showResults = state?['showResults'] ?? false;
        _selectedDestination = state?['selectedDestination'];
        _searchController.text = state?['searchText'] ?? '';
        _lastSelectedLatLng = state?['lastLatLng'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: _userPosition, zoom: 14.0),
              onMapCreated: (GoogleMapController controller) => mapController = controller,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _markers,
              polylines: _polylines,
              zoomControlsEnabled: false,
              onTap: (LatLng latLng) => _setDestination(latLng, "Selected Location"),
            ),

            // Header UI (Background image with greeting)
            SizedBox(
              width: double.infinity,
              height: 187,
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Colors.white.withOpacity(0.5)],
                    stops: const [0.85, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: Container (
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                  decoration: const BoxDecoration(
                    image: DecorationImage(image: AssetImage('assets/header_bg.png'), fit: BoxFit.cover),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(getGreeting(), style: const TextStyle(fontSize: 36, fontFamily: 'Inter', fontWeight: FontWeight.bold, color: Colors.white)),
                      const Text('User!', style: TextStyle(fontSize: 36, fontFamily:'Inter', fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),

            if (!_showResults)
              Positioned(
                left: 17, right: 17, bottom: bottomPadding + 16,
                child: _buildSearchBar(),
              ),

            // FAB: My Location
            Positioned(
              right: 17, bottom: bottomPadding + 79,
              child: GestureDetector(
                onTap: () => mapController.animateCamera(CameraUpdate.newLatLng(_userPosition)),
                child: _circleButton('assets/location.png', 36),
              ),
            ),

            // --- UPDATED FAB: DRIVE NAVIGATION ---
            Positioned(
              right: 17, bottom: bottomPadding + 154,
              child: GestureDetector(
                onTap: (_selectedDestination == null || _lastSelectedLatLng == null)
                    ? null
                    : () async {
                        _saveCurrentState();
                        final stepsBack = await Navigator.push<int>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DriveRoutePage(
                              destination: _selectedDestination!,
                              destinationCoords: _lastSelectedLatLng!, // Passing the actual LatLng
                              currentLocation: "Current Location",
                            ),
                          ),
                        );
                        if (stepsBack != null) {
                          _restorePreviousState(steps: stepsBack);
                        }
                      },
                child: _circleButton('assets/drive.png', 28),
              ),
            ),

            // Search Results Banner
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              left: 16, right: 16,
              bottom: _showResults ? 16 : -500,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(38),
                    boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 4))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 34,
                        child: _buildSearchBar(inBanner: true),
                      ),
                      const SizedBox(height: 20),
                      ..._getResults().map(
                        (item) => GestureDetector(
                          onTap: () {
                            if (widget.pickingCurrentLocation) {
                              Navigator.pop(context, item);
                            } else {
                              _saveCurrentState();
                              // Define coordinates for specific keyword results
                              LatLng target = (item.contains("Start"))
                                  ? const LatLng(13.8010, 121.1000)
                                  : const LatLng(13.7800, 121.0700);
                              _setDestination(target, item);
                              setState(() => _showResults = false);
                            }
                          },
                          child: _buildResultItem(item),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build methods (_buildSearchBar, _buildResultItem, _circleButton) remain unchanged...
  Widget _buildSearchBar({bool inBanner = false}) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(38),
        boxShadow: inBanner ? null : const [BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Image.asset('assets/maps-pin.png', width: 28, height: 28),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onSubmitted: _onSearchSubmitted,
              decoration: const InputDecoration(hintText: 'Search here', border: InputBorder.none),
            ),
          ),
          if (!inBanner)
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserProfile()),
                );
                if (result is File) {
                  setState(() => _profileImage = result);
                }
              },
              child: ClipOval(
                child: _profileImage != null
                    ? Image.file(_profileImage!, width: 32, height: 32)
                    : Image.asset('assets/profile.png', width: 32, height: 32),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        children: [
          Image.asset('assets/maps-pin.png', width: 22, height: 31),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16, fontFamily: 'Inter')),
        ],
      ),
    );
  }

  Widget _circleButton(String asset, double size) {
    return Container(
      width: 55,
      height: 55,
      decoration: const BoxDecoration(
        color: Color(0xFF21709D),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 3))],
      ),
      child: Center(
        child: Image.asset(asset, width: size, height: size),
      ),
    );
  }
}