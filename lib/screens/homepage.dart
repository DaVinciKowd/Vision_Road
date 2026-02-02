import 'dart:io';
import 'package:flutter/material.dart';
import 'user_profile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _profileImage;
  final TextEditingController _searchController = TextEditingController();
  bool _showResults = false;

  // Sample keywords for search
  final List<String> _keywords = [
    'star',
    'tollway',
    'batangas',
    'autosweep',
  ];

  @override
  void initState() {
    super.initState();

    // 🔥 Listen to text changes
    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase().trim();

      setState(() {
        if (query.isEmpty) {
          _showResults = false;
        } else {
          _showResults =
              _keywords.any((word) => query.contains(word));
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

  // Get results filtered by search query
  List<String> _getResults() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return [];
    return [
      'STAR Tollway Batangas',
      'STAR Tollway (AutoSweep)',
      'STAR Tollway Start',
    ].where((item) => item.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus(); // 👈 CLOSE KEYBOARD
        },
        child: Stack(
          children: [

            // MAP PLACEHOLDER
            Container(
              color: Colors.grey.shade300,
              child: const Center(
                child: Text('Google Maps will be here'),
              ),
            ),

            // HEADER
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

            // SEARCH BAR (default position)
            if (!_showResults)
              Positioned(
                left: 17,
                right: 17,
                bottom: bottomPadding + 16,
                child: _buildSearchBar(),
              ),

            // LOCATION BUTTON
            Positioned(
              right: 17,
              bottom: bottomPadding + 79,
              child: _circleButton('assets/location.png', 36),
            ),

            // DRIVE BUTTON
            Positioned(
              right: 17,
              bottom: bottomPadding + 154,
              child: _circleButton('assets/drive.png', 28),
            ),

            // RESULTS POPUP BANNER
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

                      // SEARCH BAR IN BANNER
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 34,
                        child: _buildSearchBar(inBanner: true),
                      ),

                      const SizedBox(height: 20),

                      // RESULTS
                      ..._getResults().map(
                        (item) => GestureDetector(
                          onTap: () {
                            _searchController.text = item;
                            setState(() => _showResults = false);
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

  // SEARCH BAR
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

  // RESULT ITEM
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

  // CIRCLE BUTTON
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
