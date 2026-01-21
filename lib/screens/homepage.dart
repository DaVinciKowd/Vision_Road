import 'package:flutter/material.dart';
import 'user_profile.dart'; // import UserProfile screen

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning,';
    } else if (hour < 18) {
      return 'Good Afternoon,';
    } else {
      return 'Good Evening,';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // MAP PLACEHOLDER
          Container(
            color: Colors.grey.shade300,
            child: const Center(
              child: Text(
                'Google Maps will be here',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ),

          // IMAGE HEADER
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

          // SEARCH BAR
          Positioned(
            left: 17,
            right: 17,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(38),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x40000000),
                    blurRadius: 4,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [

                  // LEFT MAPS PIN
                  Image.asset(
                    'assets/maps-pin.png',
                    width: 28,
                    height: 28,
                  ),

                  const SizedBox(width: 10),

                  // TEXT FIELD
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search here',
                        hintStyle: TextStyle(
                          color: Color(0x88185375),
                          fontSize: 18,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  // PROFILE ICON NAVIGATES TO USER PROFILE
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserProfile(),
                        ),
                      );
                    },
                    child: Image.asset(
                      'assets/profile.png',
                      width: 32,
                      height: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // RIGHT LOCATION BUTTON ABOVE SEARCH BAR
          Positioned(
            right: 17,
            bottom: MediaQuery.of(context).padding.bottom + 53 + 16 + 10,
            child: GestureDetector(
              onTap: () {
                // handle location tap
              },
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: const Color(0xFF21709D),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x40000000),
                      blurRadius: 4,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/location.png',
                    width: 36,
                    height: 36,
                  ),
                ),
              ),
            ),
          ),

          // DRIVE BUTTON ABOVE LOCATION BUTTON
          Positioned(
            right: 17,
            bottom: MediaQuery.of(context).padding.bottom + 53 + 16 + 10 + 65,
            child: GestureDetector(
              onTap: () {
                // handle drive button tap
              },
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: const Color(0xFF21709D),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x40000000),
                      blurRadius: 4,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/drive.png',
                    width: 28,
                    height: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
