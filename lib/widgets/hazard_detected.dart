import 'package:flutter/material.dart';

class HazardDetectedBanner extends StatelessWidget {
  const HazardDetectedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // Screen width
    double screenWidth = MediaQuery.of(context).size.width;
    double bannerWidth = screenWidth * 0.92; // 92% of screen width

    return Center(
      child: Container(
        width: bannerWidth,
        height: 185,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xEEEEEEEE), // 91% opacity
          borderRadius: BorderRadius.circular(38),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 4),
              blurRadius: 4,
              color: Color(0x40000000), // 25% opacity black
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // TOP ROW: ICON + NOTICE TEXT
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/notice.png',
                  width: 69,
                  height: 60,
                ),
                // Use Transform.translate to nudge the text closer
                Transform.translate(
                  offset: const Offset(-7, 0), // adjust this value as needed
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center, // text still center-aligned
                    children: const [
                      Text(
                        'NOTICE: Road Hazard',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 25.7,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF21709D),
                        ),
                      ),
                      Text(
                        'Detected!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 25.7,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF21709D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // BOTTOM ROW: PIN + LOCATION TEXT
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/red-pin.png',
                  width: 22,
                  height: 29,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Pothole Detected at 50m',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w600, // Semi-bold
                    color: Color(0xFF21709D),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
