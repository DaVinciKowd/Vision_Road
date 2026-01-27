import 'dart:io';
import 'package:flutter/material.dart';
import 'edit_profile.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  static const double headerHeight = 200;
  static const double arcHeight = 94.95;
  static const double arcWidth = 189.9;
  static const double userSize = 162;

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  // Initial/default user data
  File? _profileImage;
  String _username = 'Username';
  String _email = 'Useremailadd@gmail.com';
  String _phone = '0531 652 1234';

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true, // Important for keyboard scrolling
      body: Column(
        children: [
          /// ================= HEADER STACK =================
          SizedBox(
            height: UserProfile.headerHeight + (UserProfile.userSize / 2),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // HEADER IMAGE
                Container(
                  width: double.infinity,
                  height: UserProfile.headerHeight,
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

                // ARC
                Positioned(
                  bottom: 81,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Image.asset(
                      'assets/arc.png',
                      width: UserProfile.arcWidth,
                      height: UserProfile.arcHeight,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // PROFILE IMAGE
                Positioned(
                  bottom: -(UserProfile.userSize / 2) + 81,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ClipOval(
                      child: _profileImage != null
                          ? Image.file(
                              _profileImage!,
                              width: UserProfile.userSize,
                              height: UserProfile.userSize,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              'assets/icon-user.png',
                              width: UserProfile.userSize,
                              height: UserProfile.userSize,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          /// ================= USERNAME =================
          Text(
            _username,
            style: const TextStyle(
              fontSize: 36,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w900,
              color: Color(0xFF21709D),
            ),
          ),

          const SizedBox(height: 18),

          /// ================= MAIN CONTENT =================
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // EMAIL LABEL
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
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
                  Container(
                    width: MediaQuery.of(context).size.width * 0.75,
                    height: 45,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0x4DABADAE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _email,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Inter',
                        color: Color(0x4D0C2737),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // PHONE LABEL
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
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
                  Container(
                    width: MediaQuery.of(context).size.width * 0.75,
                    height: 45,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0x4DABADAE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _phone,
                      style: const TextStyle(
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
                      onPressed: () async {
                        final updatedData = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfile(),
                          ),
                        );

                        if (updatedData != null &&
                            updatedData is Map<String, dynamic>) {
                          setState(() {
                            _profileImage = updatedData['image'] as File?;
                            _username = updatedData['username'] ?? _username;
                            _email = updatedData['email'] ?? _email;
                            _phone = updatedData['phone'] ?? _phone;
                          });
                        }
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
