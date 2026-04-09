import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'user_profile.dart';
import 'drive_route.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../ml/pt_model_detector.dart';

class NavigationCameraPage extends StatefulWidget {
  final String destination;
  final LatLng? destinationPosition;
  final List<LatLng>? routePoints;

  const NavigationCameraPage({
    super.key,
    required this.destination,
    this.destinationPosition,
    this.routePoints,
  });

  @override
  State<NavigationCameraPage> createState() => _NavigationCameraPageState();
}

class _NavigationCameraPageState extends State<NavigationCameraPage> {
  static const String _ptModelAssetPath = 'assets/models/road_hazard_detector.pt';

  /// CAMERA
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;

  /// DETECTION
  final PtModelDetector _detector = PtModelDetector(modelAssetPath: _ptModelAssetPath);
  bool _isProcessingFrame = false;
  DateTime _lastInferenceAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _inferenceInterval = Duration(milliseconds: 400);
  DetectionResult? _latestDetection;
  String _modelStatus = 'Preparing model...';

  /// MAP & NAVIGATION
  GoogleMapController? mapController;
  LatLng _userPosition = const LatLng(13.7565, 121.0583);
  StreamSubscription<Position>? _positionStream;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  // smoothed heading
  double _smoothedHeading =0.0;

  //Custom User Marker
  BitmapDescriptor? _userIcon;

  /// PICTURE IN PICTURE TOGGLE
  bool _mapFullScreen = false;

  /// PIP POSITION
  Offset _pipPosition = const Offset(200, 100);

  final TextEditingController _searchController = TextEditingController();
  File? _profileImage;
  bool _showResults = false;
  final List<String> _keywords = ['star', 'tollway', 'batangas', 'autosweep'];

  @override
  void initState() {
    super.initState();
    _loadUserMarker();
    _searchController.text = widget.destination;

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

    _initializeNavigationData();
    _startLocationTracking(); 
    _initializeCamera();
  }

  ///Load User Icon
  Future<void> _loadUserMarker() async {
    _userIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size (48, 48)),
      'assets/user_location.png'
    );
    if (mounted) setState ((){});
  }

  void _initializeNavigationData() {
    // 1. Setup the Route Path
    if (widget.routePoints != null && widget.routePoints!.isNotEmpty) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('nav_route'),
          points: widget.routePoints!,
          color: const Color(0xFF21709D),
          width: 8, 
          jointType: JointType.round,
          startCap: Cap.roundCap, // Corrected parameter name
          endCap: Cap.roundCap,   // Corrected parameter name
        ),
      );
    }

    // 2. Add Destination Marker
    if (widget.destinationPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('dest_pin'),
          position: widget.destinationPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: widget.destination),
        ),
      );
    }
  }

  /// REAL-TIME SMOOTH TRACKING (REVERTED TO NATIVE INDICATOR)
  void _startLocationTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation, 
        distanceFilter: 2, //only updates every 2 meters to save battery/cpu 
      ),
    ).listen((Position position) {
      LatLng current = LatLng(position.latitude, position.longitude);

      // heading smoothing
      double rawHeading = position.heading;

      //ignore invalid readings
      if (rawHeading ==0) {
        rawHeading = _smoothedHeading;
      }

      //apply smoothing filter
      _smoothedHeading = _smoothedHeading == 0
          ? rawHeading
          : (_smoothedHeading * 0.8 +  rawHeading * 0.2);
      
      if (mounted) {
        // 1. Update the user position and recalculate the polyline
        //use smoothed heading
        //_updateRouteProgress(current, position.heading);
        _updateRouteProgress(current, _smoothedHeading);
                
        // Perspective Camera Animation to follow movement
        mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: current,
              zoom: 18.5, 
              tilt: 60.0,      
              bearing: _smoothedHeading, 
            ),
          ),
        );
      }
    });
  }

  ///New method: trims the polyline so it always starts from your current dot
  void _updateRouteProgress(LatLng currentPosition, double heading){
    if (widget.routePoints == null || widget.routePoints!.isEmpty) return;

    //Use the original points passed from the previous screen
    List<LatLng> fullRoute = widget.routePoints!;
    int closestPointIndex = 0;
    double minDistance = double.infinity;

    // find which point in the route array is currently closest to the car
    for (int i =0; i< fullRoute.length; i++) {
      double distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        fullRoute[i].latitude,
        fullRoute[i].longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestPointIndex = i;
      }  
    }
    // Create a new path: Start exactly at the user's GPS dot, 
    // then continue with the rest of the original points.
    //List<LatLng> updatedPath = [currentPosition];

    // Create a new path: start from the nearest point on the route (NOT the user GPS)
    List<LatLng> updatedPath = [];

    // Only add points that are ahead of our current "closest" index
    if (closestPointIndex < fullRoute.length - 1) {
      updatedPath = fullRoute.sublist(closestPointIndex);
    } else {
      updatedPath = [fullRoute.last];
    }

    setState (() {
      _userPosition = currentPosition;

      _polylines = {
        Polyline(
          polylineId: const PolylineId('nav_route'),
          points: updatedPath,
          color: const Color(0xFF21709D),
          width: 8,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      };

      // remove old user marker
      _markers.removeWhere((m) => m.markerId.value =='user_location');

      // Add Custom User Marker
      _markers.add (
        Marker(
          markerId: const MarkerId('user_location'),
          position: currentPosition,
          icon: _userIcon?? BitmapDescriptor.defaultMarker,
          anchor: const Offset (0.5, 0.5),
          flat:true,
          rotation: heading,
        ),
      );
    });
  }

  // --- CAMERA & ML LOGIC ---
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _modelStatus = 'No camera');
        return;
      }
      _cameraController = CameraController(cameras.first, ResolutionPreset.medium, enableAudio: false);
      _initializeControllerFuture = _cameraController!.initialize();
      await _initializeControllerFuture;
      await _detector.initialize();
      if (_detector.isModelAssetFound) {
        _modelStatus = 'Model ready';
        await _startImageStream();
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _modelStatus = 'Init error');
    }
  }

  Future<void> _startImageStream() async {
    final controller = _cameraController;
    if (controller == null || controller.value.isStreamingImages) return;
    await controller.startImageStream((CameraImage image) {
      if (!mounted || _isProcessingFrame) return;
      final now = DateTime.now();
      if (now.difference(_lastInferenceAt) < _inferenceInterval) return;
      _isProcessingFrame = true;
      _lastInferenceAt = now;
      _runDetection(image).whenComplete(() => _isProcessingFrame = false);
    });
  }

  Future<void> _runDetection(CameraImage image) async {
    final results = await _detector.detect(image);
    if (!mounted || results.isEmpty) return;
    setState(() => _latestDetection = results.first);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _cameraController?.dispose();
    _detector.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- UI BUILDERS ---
  Widget _buildCameraPreview() {
    return FutureBuilder(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final size = MediaQuery.of(context).size;
          final scale = 1 / (_cameraController!.value.aspectRatio * size.aspectRatio);
          return Transform.scale(scale: scale, child: Center(child: CameraPreview(_cameraController!)));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildGoogleMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _userPosition, zoom: 16),
      onMapCreated: (controller) => mapController = controller,
      myLocationEnabled: false, // Restores the original pulsing blue dot
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      tiltGesturesEnabled: true,
      rotateGesturesEnabled: true,
      compassEnabled: true,
      onCameraMove: (position){},
      polylines: _polylines,
      markers: _markers,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            _mapFullScreen 
                ? Stack(
                    children: [_buildGoogleMap(),
                    // optional: add ui overlays here if needed
                    ],
                  )
                : _buildCameraPreview(),
            
            /// HEADER OVERLAY
            Positioned(
              top: 0, left: 0, right: 0,
              child: SizedBox(
                height: 187,
                child: ShaderMask(
                  shaderCallback: (Rect bounds) => const LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.white, Colors.transparent],
                  ).createShader(bounds),
                  blendMode: BlendMode.dstIn,
                  child: Image.asset('assets/header_bg.png', fit: BoxFit.cover),
                ),
              ),
            ),
            
            /// ML HUD
            Positioned(top: 64, left: 16, right: 16, child: _buildDetectionStatusCard()),
            
            /// FOOTER OVERLAY
            if (!_mapFullScreen) // hide the footer when map is in fullscreen
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SizedBox(
                height: 187,
                child: ShaderMask(
                  shaderCallback: (Rect bounds) => const LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [Colors.white, Colors.transparent],
                  ).createShader(bounds),
                  blendMode: BlendMode.dstIn,
                  child: Image.asset('assets/footer.png', fit: BoxFit.cover),
                ),
              ),
            ),
            
            /// CONTROLS
            if (!_showResults)
              Positioned(
                left: 17, right: 17, bottom: bottomPadding + 16,
                child: _buildSearchBar(),
              ),

            Positioned(
              right: 17, bottom: bottomPadding + 79,
              child: GestureDetector (
                onTap: () {
                  if(mapController != null) {
                    mapController!.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: _userPosition,
                          zoom: 18.5,
                        ),
                      ),
                    );
                  }
                },
                child: _circleButton('assets/location.png', 36),
              ),
            ),

            Positioned(
              right: 17, bottom: bottomPadding + 154,
              child: GestureDetector(
                onTap: () {
                  if (_searchController.text.isNotEmpty) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DriveRoutePage(
                          destination: _searchController.text,
                          currentPosition: _userPosition,
                        ),
                      ),
                    );
                  }
                },
                child: _circleButton('assets/drive.png', 28),
              ),
            ),

            /// SEARCH RESULTS PANEL
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              left: 16, right: 16, bottom: _showResults ? 16 : -500,
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
                      _buildSearchBar(inBanner: true),
                      const SizedBox(height: 20),
                      ..._getResults().map((item) => GestureDetector(
                        onTap: () => setState(() { _searchController.text = item; _showResults = false; }),
                        child: _buildResultItem(item),
                      )),
                    ],
                  ),
                ),
              ),
            ),

            /// DRAGGABLE PIP WINDOW
            Positioned(
              top: _pipPosition.dy, left: _pipPosition.dx,
              child: GestureDetector(
                onTap: () => setState(() => _mapFullScreen = !_mapFullScreen),
                onPanUpdate: (details) {
                  setState(() {
                    _pipPosition += details.delta;
                    _pipPosition = Offset(
                      _pipPosition.dx.clamp(0, screenSize.width - 150),
                      _pipPosition.dy.clamp(0, screenSize.height - 200),
                    );
                  });
                },
                child: Container(
                  width: 150, height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: _mapFullScreen ? _buildCameraPreview() : IgnorePointer(ignoring: true, child: _buildGoogleMap()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar({bool inBanner = false}) {
    return Container(
      height: 50, padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(38),
        boxShadow: inBanner ? null : const [BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Image.asset('assets/maps-pin.png', width: 28, height: 28),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: _searchController, decoration: const InputDecoration(hintText: 'Search here', border: InputBorder.none))),
          if (!inBanner)
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfile()));
                if (result is File) setState(() => _profileImage = result);
              },
              child: ClipOval(child: _profileImage != null ? Image.file(_profileImage!, width: 32, height: 32, fit: BoxFit.cover) : Image.asset('assets/profile.png', width: 32, height: 32)),
            ),
        ],
      ),
    );
  }

  List<String> _getResults() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return [];
    return ['STAR Tollway Batangas', 'STAR Tollway (AutoSweep)', 'STAR Tollway Start'].where((item) => item.toLowerCase().contains(query)).toList();
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
      width: 55, height: 55,
      decoration: const BoxDecoration(color: Color(0xFF21709D), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 3))]),
      child: Center(child: Image.asset(asset, width: size, height: size)),
    );
  }

  Widget _buildDetectionStatusCard() {
    final detection = _latestDetection;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xBF000000), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_modelStatus, style: const TextStyle(fontFamily: 'Inter', color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          if (detection != null) ...[
            const SizedBox(height: 6),
            Text('Detected: ${detection.label} (${(detection.confidence * 100).toStringAsFixed(1)}%)', style: const TextStyle(fontFamily: 'Inter', color: Colors.white, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}