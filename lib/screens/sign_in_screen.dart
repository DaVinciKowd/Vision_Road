import 'package:flutter/material.dart';
import 'sign_up_screen.dart';
import 'forgot_password.dart';


class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _obscurePassword = true; // controls show/hide password

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0), // left & right padding
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // left align texts
              children: [

                const SizedBox(height: 40),

                // Logo
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

                // "Sign In" text
                const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 36,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 1),

                // "Please sign in to continue"
                const Text(
                  'Please sign in to continue',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily:'Inter',
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF000000),
                  ),
                ),

                const SizedBox(height: 10),

                // Username TextField
                Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0x30ABADAE), // ABADAE with 30% opacity
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  child: const TextField(
                    style: TextStyle(color: Color(0xFF0C2737), fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Username',
                      hintStyle: TextStyle(
                        color: Color(0x4D0C2737), // 30% opacity
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Password TextField
                Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0x30ABADAE), // ABADAE with 30% opacity
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  child: TextField(
                    style: const TextStyle(color: Color(0xFF0C2737), fontSize: 15),
                    obscureText: _obscurePassword,
                    textAlignVertical:TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: const TextStyle(
                        color: Color(0x4D0C2737),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 0.1),

                // Forgot Password text
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFF21709D),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 49,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Add sign in logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF21709D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Sign In',
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

                // "Don't have an account? Sign Up" with clickable Sign Up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignUpScreen()),
                        );
                      },
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          color: Color(0xFF21709D),
                          fontSize: 14,
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
