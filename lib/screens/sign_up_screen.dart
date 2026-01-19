import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _obscurePassword = true;

  Widget _buildTextField({
    required String hint,
    bool isPassword = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0x30ABADAE),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: TextField(
        obscureText: isPassword ? _obscurePassword : false,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          color: Color(0xFF0C2737),
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0x4D0C2737),
            fontSize: 15,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return _buildTextField(
      hint: 'Password',
      isPassword: true,
      suffixIcon: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                _obscurePassword
                    ? 'assets/view-icon.png'
                    : 'assets/hide-icon.png',
                width: 26,
                height: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                /// Logo + App Name
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/app_logo.png',
                        width: 200,
                        height: 200,
                      ),
                      const SizedBox(height: 10),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 34,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w900,
                          ),
                          children: [
                            TextSpan(
                              text: 'Vision ',
                              style: TextStyle(color: Color(0xFFFF0000)),
                            ),
                            TextSpan(
                              text: 'Road',
                              style: TextStyle(color: Color(0xFF21709D)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// Sign Up title
                const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 36,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Create an account to continue',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 15),

                /// Username
                _buildTextField(hint: 'Username'),

                const SizedBox(height: 15),

                /// Email
                _buildTextField(
                  hint: 'Email Address',
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 15),

                /// Phone (numbers only, max 11 digits)
                _buildTextField(
                  hint: 'Phone Number',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                ),

                const SizedBox(height: 15),

                /// Password (custom icon like Sign In page)
                _buildPasswordField(),

                const SizedBox(height: 25),

                /// Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 49,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Add sign up logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF21709D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                /// Already have an account? Sign In
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Color(0xFF21709D),
                          fontSize: 15,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
