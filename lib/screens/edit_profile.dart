import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  static const double headerHeight = 200;
  static const double arcHeight = 94.95;
  static const double arcWidth = 189.9;
  static const double userSize = 162;

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          /// ================= HEADER STACK =================
          SizedBox(
            height: EditProfile.headerHeight + (EditProfile.userSize / 2),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  height: EditProfile.headerHeight,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/user_header.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
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
                Positioned(
                  bottom: 81,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Image.asset(
                      'assets/arc.png',
                      width: EditProfile.arcWidth,
                      height: EditProfile.arcHeight,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -(EditProfile.userSize / 2) + 81,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipOval(
                          child: _profileImage != null
                              ? Image.file(
                                  _profileImage!,
                                  width: EditProfile.userSize,
                                  height: EditProfile.userSize,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  'assets/icon-user.png',
                                  width: EditProfile.userSize,
                                  height: EditProfile.userSize,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        Positioned(
                          bottom: -8,
                          right: -8,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Image.asset(
                              'assets/edit.png',
                              width: 26,
                              height: 25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// ================= SCROLLABLE FORM =================
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 30),
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('New Username'),
                    _inputField('Enter new username',
                        controller: _usernameController, autofocus: true),
                    const SizedBox(height: 10),

                    _label('New Email'),
                    _inputField('Enter new email', controller: _emailController),
                    const SizedBox(height: 10),

                    _label('New Phone Number'),
                    _inputField('Enter new phone number',
                        controller: _phoneController),
                    const SizedBox(height: 40),

                    // SAVE BUTTON
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.75,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () {
                          // Collect all updated data
                          final updatedData = {
                            'image': _profileImage,
                            'username': _usernameController.text,
                            'email': _emailController.text,
                            'phone': _phoneController.text,
                          };

                          // Send back to UserProfile
                          Navigator.pop(context, updatedData);
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          color: Color(0xFF21709D),
        ),
      ),
    );
  }

  Widget _inputField(String hint,
      {TextEditingController? controller, bool autofocus = false}) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.75,
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0x4DABADAE),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0x4D0C2737),
            fontFamily: 'Inter',
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
