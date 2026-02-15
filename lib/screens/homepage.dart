import 'dart:io';
import 'package:flutter/material.dart';
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

  final List<String> _keywords = [
    'star',
    'tollway',
    'batangas',
    'autosweep',
  ];

  final List<Map<String, dynamic>> _stateHistory = [];

  @override
  void initState() {
    super.initState();

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 18) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  void _onSearchSubmitted(String value) {
    final query = value.toLowerCase().trim();
    setState(() {
      _showResults =
          query.isNotEmpty && _keywords.any((word) => query.contains(word));
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

            Container(
              color: Colors.grey.shade300,
              child: const Center(
                child: Text('Google Maps will be here'),
              ),
            ),

            Container(
              width: double.infinity,
              height: 187,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/header_bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getGreeting(),
                    style: const TextStyle(
                      fontSize: 36,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'User!',
                    style: TextStyle(
                      fontSize: 36,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            if (!_showResults)
              Positioned(
                left: 17,
                right: 17,
                bottom: bottomPadding + 16,
                child: _buildSearchBar(),
              ),

            Positioned(
              right: 17,
              bottom: bottomPadding + 79,
              child: _circleButton('assets/location.png', 36),
            ),

            
            Positioned(
              right: 17,
              bottom: bottomPadding + 154,
              child: GestureDetector(
                onTap: _selectedDestination == null
                    ? null
                    : () async {
                        _saveCurrentState();
                        final stepsBack = await Navigator.push<int>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DriveRoutePage(
                              destination: _selectedDestination!,
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
                      ),
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
                            if (widget.pickingCurrentLocation) {
                              Navigator.pop(context, item);
                            } else {
                              _saveCurrentState();
                              setState(() {
                                _selectedDestination = item;
                                _searchController.text = item;
                                _showResults = false;
                              });
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
                ),
              ],
      ),
      child: Row(
        children: [
          Image.asset('assets/maps-pin.png', width: 28, height: 28),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onSubmitted: _onSearchSubmitted,
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
          Text(
            text,
            style: const TextStyle(fontSize: 16, fontFamily: 'Inter'),
          ),
        ],
      ),
    );
  }

  Widget _circleButton(String asset, double size) {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFF21709D),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 4,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Image.asset(asset, width: size, height: size),
      ),
    );
  }
}
