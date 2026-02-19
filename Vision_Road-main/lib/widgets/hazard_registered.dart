import 'package:flutter/material.dart';

class HazardRegisteredBanner extends StatelessWidget {
  const HazardRegisteredBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // Screen width
    double screenWidth = MediaQuery.of(context).size.width;
    double bannerWidth = screenWidth * 0.92; // 92% of screen width

    return Center(
      child: Container(
        width: bannerWidth,
        height: 135, // specified height
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xE8EEEEEE), // 91% opacity
          borderRadius: BorderRadius.circular(38),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 4),
              blurRadius: 4,
              color: Color(0x40000000), // 25% opacity black
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // GREEN CHECK ICON
            Image.asset(
              'assets/green-check.png',
              width: 80.83,
              height: 77.5,
            ),

            // Space between icon and text (adjust width as needed)
            const SizedBox(width: 14), 

            // Text column
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center, // multi-line text still centered
              children: const [
                Text(
                  'Road Hazard',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF21709D),
                  ),
                ),
                Text(
                  'Registered!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
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
