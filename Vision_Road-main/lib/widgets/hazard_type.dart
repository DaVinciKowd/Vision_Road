import 'package:flutter/material.dart';

class HazardTypeBanner extends StatelessWidget {
  const HazardTypeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double bannerWidth = screenWidth * 0.92;

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [

          // BANNER CONTAINER
          Container(
            width: bannerWidth,
            height: 182,
            margin: const EdgeInsets.only(top: 44), // half of icon height
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xEEEEEEEE),
              borderRadius: BorderRadius.circular(38),
              boxShadow: const [
                BoxShadow(
                  offset: Offset(0, 4),
                  blurRadius: 4,
                  color: Color(0x40000000),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                const SizedBox(height: 25),

                // HAZARD TYPE
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Hazard Type: ',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF21709D),
                      ),
                    ),
                    Text(
                      'Pothole',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF21709D),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // COORDINATES (VERTICALLY CENTERED LABEL)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    // LABEL
                    const Text(
                      'Coordinates: ',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF21709D),
                      ),
                    ),

                    // VALUES (STACKED)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          '13.8044842,',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF21709D),
                          ),
                        ),
                        Text(
                          '121.1055947',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF21709D),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // OVERLAPPING ICON
          Positioned(
            top: -37,
            child: Image.asset(
              'assets/hazard_type.png',
              width: 180,
              height: 180,
            ),
          ),
        ],
      ),
    );
  }
}