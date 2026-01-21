import 'package:flutter/material.dart';
import 'edit_profile.dart';

class UserProfile extends StatelessWidget {
  const UserProfile({super.key});

  static const double headerHeight = 200;
  static const double arcHeight = 94.95;
  static const double arcWidth = 189.9;
  static const double userSize = 162;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [

          /// ================= HEADER STACK =================
          SizedBox(
            height: headerHeight + (userSize / 2),
            child: Stack(
              clipBehavior: Clip.none,
              children: [

                // HEADER IMAGE
                Container(
                  width: double.infinity,
                  height: headerHeight,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/user_header.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // BACK BUTTON + TITLE
                Positioned(
                  top: 50,
                  left: 16,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                          'assets/back-white.png',
                          width: 28,
                          height: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'User Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // ARC (INSIDE HEADER, BOTTOM CENTER)
                Positioned(
                  bottom: 81,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Image.asset(
                      'assets/arc.png',
                      width: arcWidth,
                      height: arcHeight,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // ICON-USER (OVERLAPS HEADER FROM BELOW)
                Positioned(
                  bottom: -(userSize / 2) + 81,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Image.asset(
                      'assets/icon-user.png',
                      width: userSize,
                      height: userSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          /// ================= MAIN CONTENT =================
          const Text(
            'Username',
            style: TextStyle(
              fontSize: 36,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w900,
              color: Color(0xFF21709D),
            ),
          ),

          const SizedBox(height: 18),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // align labels to left
              children: [

                // EMAIL LABEL
                const Padding(
                  padding: EdgeInsets.only(left: 4), // adjust left spacing
                  child: Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF21709D),
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // EMAIL FIELD
                Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0x4DABADAE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Useremailadd@gmail.com',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      color: Color(0x4D0C2737),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // PHONE LABEL
                const Padding(
                  padding: EdgeInsets.only(left: 4), // adjust left spacing
                  child: Text(
                    'Phone Number',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF21709D),
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // PHONE FIELD
                Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0x4DABADAE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    '0531 652 1234',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      color: Color(0x4D0C2737),
                    ),
                  ),
                ),

                const SizedBox(height: 78),

                // EDIT PROFILE BUTTON
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfile(), 
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD9D9D9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Inter',
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // LOG OUT BUTTON
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF0000),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Log Out',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Inter',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
