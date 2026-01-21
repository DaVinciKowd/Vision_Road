import 'package:flutter/material.dart';


class EditProfile extends StatelessWidget {
  const EditProfile({super.key});

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
                        'Edit Profile',
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

          const SizedBox(height: 30),

          /// ================= MAIN CONTENT =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                // NEW USERNAME
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(
                    'New Username',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF21709D),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0x4DABADAE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.centerLeft,
                  child: const TextField(
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter new username',
                      hintStyle: TextStyle(
                        color: Color(0x4D0C2737), // 30% opacity
                        fontFamily: 'Inter',
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // NEW EMAIL
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(
                    'New Email',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF21709D),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0x4DABADAE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.centerLeft,
                  child: const TextField(
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter new email',
                      hintStyle: TextStyle(
                        color: Color(0x4D0C2737), // 30% opacity
                        fontFamily: 'Inter',
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // NEW PHONE NUMBER
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(
                    'New Phone Number',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF21709D),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0x4DABADAE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.centerLeft,
                  child: const TextField(
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter new phone number',
                      hintStyle: TextStyle(
                        color: Color(0x4D0C2737), // 30% opacity
                        fontFamily: 'Inter',
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // SAVE BUTTON
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // save action
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD9D9D9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Inter',
                        color: Colors.black,
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
