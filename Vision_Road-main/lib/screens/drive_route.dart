import 'package:flutter/material.dart';
import 'homepage.dart';

class DriveRoutePage extends StatefulWidget {
  final String destination;
  final String? currentLocation;

  const DriveRoutePage({
    super.key,
    required this.destination,
    this.currentLocation,
  });

  @override
  State<DriveRoutePage> createState() => _DriveRoutePageState();
}

class _DriveRoutePageState extends State<DriveRoutePage> {
  String currentLocation = 'Current Location';

  @override
  void initState() {
    super.initState();
    if (widget.currentLocation != null) {
      currentLocation = widget.currentLocation!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          Positioned.fill(
            child: Image.asset(
              'assets/map-placeholder.png',
              fit: BoxFit.cover,
            ),
          ),

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

                    /// CURRENT LOCATION (CLICKABLE)
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
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    /// DESTINATION
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

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 119,
              color: Colors.white.withOpacity(0.40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Color(0xFF21709D),
                      ),
                      children: [
                        TextSpan(
                          text: 'Distance: ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: '23km'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 49,
                      child: ElevatedButton(
                        onPressed: () {},
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
