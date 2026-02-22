import 'package:flutter/material.dart';
import 'verification_screen.dart';


class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 30),

              /// Back Button
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                
                child: Image.asset(
                  'assets/back_button.png',
                  width: 26,
                  height: 26,
                ),
                
              ),
    
              const SizedBox(height: 30),

              /// Title
              const Text(
                'Forgot password?',
                style: TextStyle(
                  fontSize: 36,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              /// Description (2 lines)
              const Text(
                "Fill in your email and we'll send a code\n"
                "to reset your password.",
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 25),

              /// Email TextField
              Container(
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0x30ABADAE),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                child: const TextField(
                  textAlignVertical: TextAlignVertical.center,
                  style: TextStyle(
                    color: Color(0xFF0C2737),
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Email Address',
                    hintStyle: TextStyle(
                      color: Color(0x4D0C2737),
                      fontSize: 15,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical:14),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              /// Send Code Button
              SizedBox(
                width: double.infinity,
                height: 49,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VerificationScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF21709D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Send Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
