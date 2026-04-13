import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
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
  static const String _ptModelAssetPath = 'assets/models/road_hazard_detector.tflite';

  /// CAMERA
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;

  /// DETECTION
  final PtModelDetector _detector = PtModelDetector(modelAssetPath: _ptModelAssetPath);
  bool _isProcessingFrame = false;
  DateTime _lastInferenceAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _inferenceInterval = Duration(milliseconds: 2500);
  DetectionResult? _latestDetection;
  String _modelStatus = 'Preparing model...';
  bool _isDetectionEnabled = false;

  /// MAP & NAVIGATION
  GoogleMapController? mapController;
  LatLng _userPosition = const LatLng(13.7565, 121.0583);
  StreamSubscription<Position>? _positionStream;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  // smoothed heading
  double _smoothedHeading =0.0;
  DateTime _lastNavUiUpdateAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _navUiUpdateInterval = Duration(milliseconds: 300);

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
        accuracy: LocationAccuracy.high,
        distanceFilter: 12,
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

      final now = DateTime.now();
      if (now.difference(_lastNavUiUpdateAt) < _navUiUpdateInterval) {
        return;
      }
      _lastNavUiUpdateAt = now;
      
      if (mounted) {
        if (!_mapFullScreen) {
          _userPosition = current;
          return;
        }

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
        _modelStatus = 'Model ready (tap Enable Detection)';
      } else {
        _modelStatus = 'Model missing/unsupported';
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
      if (!mounted || !_isDetectionEnabled || _isProcessingFrame) return;
      final now = DateTime.now();
      if (now.difference(_lastInferenceAt) < _inferenceInterval) return;
      _isProcessingFrame = true;
      _lastInferenceAt = now;

      // Copy only luminance bytes quickly so the camera callback can return fast.
      final Uint8List yCopy = Uint8List.fromList(image.planes.first.bytes);
      final int width = image.width;
      final int height = image.height;

      Future<void>(() => _runDetectionFrame(yCopy, width, height))
          .whenComplete(() => _isProcessingFrame = false);
    });
  }

  Future<void> _runDetectionFrame(
    Uint8List yPlane,
    int width,
    int height,
  ) async {
    final results = await _detector.detectFromLuma(yPlane, width, height);
    if (!mounted || results.isEmpty) return;

    final next = results.first;
    final prev = _latestDetection;
    if (prev != null &&
        prev.label == next.label &&
        (prev.confidence - next.confidence).abs() < 0.03) {
      return;
    }

    setState(() => _latestDetection = next);
  }

  Future<void> _toggleDetection() async {
    final controller = _cameraController;
    if (controller == null || !_detector.isModelAssetFound) {
      return;
    }

    if (_isDetectionEnabled) {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      if (!mounted) return;
      setState(() {
        _isDetectionEnabled = false;
        _isProcessingFrame = false;
        _modelStatus = 'Model ready (detection paused)';
      });
      return;
    }

    await _startImageStream();
    if (!mounted) return;
    setState(() {
      _isDetectionEnabled = true;
      _modelStatus = 'Detecting hazards';
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
    if (_cameraController?.value.isStreamingImages ?? false) {
      _cameraController?.stopImageStream();
    }
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
          return Transform.scale(
            scale: scale,
            child: Center(
              child: Stack(
                children: [
                  CameraPreview(_cameraController!),
                  Positioned.fill(child: IgnorePointer(child: _buildDetectionOverlay())),
                ],
              ),
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildDetectionOverlay() {
    return CustomPaint(
      painter: _DetectionOverlayPainter(
        detection: _latestDetection,
        modelSize: Size(_detector.inputWidth.toDouble(), _detector.inputHeight.toDouble()),
      ),
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

            Positioned(
              bottom: bottomPadding + 229,
              right: 16,
              child: _buildDetectionToggleButton(),
            ),
            
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
                  if (_mapFullScreen && mapController != null) {
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
                  child: _mapFullScreen
                      ? _buildCameraPreview()
                      : _buildMapPipPlaceholder(),
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

  Widget _buildMapPipPlaceholder() {
    return Container(
      color: const Color(0xFF12384D),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map, color: Colors.white, size: 30),
            SizedBox(height: 8),
            Text(
              'Tap to open map',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildDetectionToggleButton() {
    final isEnabled = _isDetectionEnabled;
    final canUseModel = _detector.isModelAssetFound;

    return Tooltip(
      message: canUseModel
          ? (isEnabled ? 'Pause Detection' : 'Enable Detection')
          : 'Model Unavailable',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canUseModel ? _toggleDetection : null,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: canUseModel
                    ? (isEnabled
                        ? const [Color(0xFFB71C1C), Color(0xFF7F1111)]
                        : const [Color(0xFF2D86B8), Color(0xFF1A5C80)])
                    : const [Color(0xFF6E6E6E), Color(0xFF4F4F4F)],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 4,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    isEnabled ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: canUseModel
                          ? (isEnabled
                              ? const Color(0xFF8BFFB2)
                              : const Color(0xFFFFE08A))
                          : const Color(0xFFFFB3B3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetectionOverlayPainter extends CustomPainter {
  _DetectionOverlayPainter({required this.detection, required this.modelSize});

  final DetectionResult? detection;
  final Size modelSize;

  @override
  void paint(Canvas canvas, Size size) {
    final result = detection;
    if (result == null || result.boundingBox.isEmpty) {
      return;
    }

    final scaleX = size.width / modelSize.width;
    final scaleY = size.height / modelSize.height;
    final box = Rect.fromLTRB(
      result.boundingBox.left * scaleX,
      result.boundingBox.top * scaleY,
      result.boundingBox.right * scaleX,
      result.boundingBox.bottom * scaleY,
    );

    final strokePaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final fillPaint = Paint()
      ..color = const Color(0x33FFD54F)
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(box, const Radius.circular(8));
    canvas.drawRRect(rrect, fillPaint);
    canvas.drawRRect(rrect, strokePaint);

    final label = '${result.label} ${(result.confidence * 100).toStringAsFixed(1)}%';
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: size.width - 12);

    final labelWidth = textPainter.width + 12;
    final labelHeight = textPainter.height + 8;
    final labelTop = box.top - labelHeight - 6 >= 0 ? box.top - labelHeight - 6 : box.top + 6;
    final labelLeft = box.left.clamp(6.0, size.width - labelWidth - 6);
    final labelRect = Rect.fromLTWH(labelLeft, labelTop, labelWidth, labelHeight);

    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(6)),
      Paint()..color = const Color(0xCC000000),
    );
    textPainter.paint(canvas, Offset(labelRect.left + 6, labelRect.top + 4));
  }

  @override
  bool shouldRepaint(covariant _DetectionOverlayPainter oldDelegate) {
    return oldDelegate.detection != detection || oldDelegate.modelSize != modelSize;
  }
}