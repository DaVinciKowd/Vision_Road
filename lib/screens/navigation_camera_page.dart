import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'user_profile.dart';
import 'drive_route.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NavigationCameraPage extends StatefulWidget {
  final String destination;

  const NavigationCameraPage({
    super.key,
    required this.destination,
  });

  @override
  State<NavigationCameraPage> createState() => _NavigationCameraPageState();
}

class _NavigationCameraPageState extends State<NavigationCameraPage> {
  /// CAMERA
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;

  /// MAP
  GoogleMapController? mapController;
  LatLng _userPosition = const LatLng(13.7565, 121.0583);

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

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _cameraController!.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// CAMERA PREVIEW
  Widget _buildCameraPreview() {
    return FutureBuilder(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final size = MediaQuery.of(context).size;

          final scale =
              1 / (_cameraController!.value.aspectRatio * size.aspectRatio);

          return Transform.scale(
            scale: scale,
            child: Center(
              child: CameraPreview(_cameraController!),
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  /// GOOGLE MAP
  Widget _buildGoogleMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _userPosition,
        zoom: 14,
      ),
      onMapCreated: (GoogleMapController controller) {
        mapController = controller;
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
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
            /// MAIN VIEW
            _mapFullScreen ? _buildGoogleMap() : _buildCameraPreview(),

            /// HEADER IMAGE
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 187,
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white,
                        Colors.transparent,
                      ],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(
                    'assets/header_bg.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            ),

            /// FOOTER IMAGE
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 187,
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.white,
                        Colors.transparent,
                      ],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(
                    'assets/footer.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            ),

            /// SEARCH BAR
            if (!_showResults)
              Positioned(
                left: 17,
                right: 17,
                bottom: bottomPadding + 16,
                child: _buildSearchBar(),
              ),

            /// LOCATION BUTTON
            Positioned(
              right: 17,
              bottom: bottomPadding + 79,
              child: _circleButton('assets/location.png', 36),
            ),

            /// DRIVE BUTTON
            Positioned(
              right: 17,
              bottom: bottomPadding + 154,
              child: GestureDetector(
                onTap: () {
                  if (_searchController.text.isNotEmpty) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DriveRoutePage(
                          destination: _searchController.text,
                        ),
                      ),
                    );
                  }
                },
                child: _circleButton('assets/drive.png', 28),
              ),
            ),

            /// SEARCH RESULTS
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              left: 16,
              right: 16,
              bottom: _showResults ? 16 : -500,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(38),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 6,
                        offset: Offset(0, 4),
                      )
                    ],
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
                            setState(() {
                              _searchController.text = item;
                              _showResults = false;
                            });
                          },
                          child: _buildResultItem(item),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            /// PICTURE IN PICTURE (TOP LAYER) - MOVABLE
            Positioned(
              top: _pipPosition.dy,
              left: _pipPosition.dx,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _mapFullScreen = !_mapFullScreen;
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _pipPosition += details.delta;

                    // Clamp PiP inside screen boundaries
                    final pipWidth = 150.0;
                    final pipHeight = 200.0;
                    _pipPosition = Offset(
                      _pipPosition.dx.clamp(0, screenSize.width - pipWidth),
                      _pipPosition.dy.clamp(0, screenSize.height - pipHeight),
                    );
                  });
                },
                child: Container(
                  width: 150,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                      )
                    ],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: _mapFullScreen
                      ? _buildCameraPreview()
                      : IgnorePointer(
                          ignoring: true,
                          child: _buildGoogleMap(),
                        ),
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
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(38),
        boxShadow: inBanner
            ? null
            : const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 4,
                  offset: Offset(0, 4),
                )
              ],
      ),
      child: Row(
        children: [
          Image.asset('assets/maps-pin.png', width: 28, height: 28),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search here',
                border: InputBorder.none,
              ),
            ),
          ),
          if (!inBanner)
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UserProfile(),
                  ),
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

  List<String> _getResults() {
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) return [];

    return [
      'STAR Tollway Batangas',
      'STAR Tollway (AutoSweep)',
      'STAR Tollway Start',
    ].where((item) => item.toLowerCase().contains(query)).toList();
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
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 4,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Center(
        child: Image.asset(asset, width: size, height: size),
      ),
    );
  }
}