import 'dart:async';
import 'package:flutter/material.dart';
import 'auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Navigate to auth gate (which decides sign-in vs home) after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/app_logo.png', width: 200, height: 200),
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
    );
  }
}
