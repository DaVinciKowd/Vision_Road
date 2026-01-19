import 'dart:async';
import 'package:flutter/material.dart';
import 'change_password.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());

  final List<FocusNode> _focusNodes =
      List.generate(4, (_) => FocusNode());

  int _secondsRemaining = 0;
  Timer? _timer;
  bool _isButtonEnabled = false;

  void _startResendTimer() {
    setState(() {
      _secondsRemaining = 60;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  void _checkOtpComplete() {
    setState(() {
      _isButtonEnabled = _controllers.every((c) => c.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 60,
      height: 62,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 24,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFFD9D9D9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 3) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
            }
          } else if (index > 0) {
            _focusNodes[index - 1].requestFocus();
          }

          _checkOtpComplete(); // update button state whenever any field changes
        },
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              /// Back Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Image.asset(
                  'assets/back_button.png',
                  width: 26,
                  height: 26,
                ),
              ),

              const SizedBox(height: 30),

              /// Title
              const Text(
                'Verification',
                style: TextStyle(
                  fontSize: 36,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              /// Subtitle
              const Text(
                'A verification code was sent to your email.',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Inter',
                ),
              ),

              const SizedBox(height: 15),

              /// Instruction
              const Text(
                'Please enter the 4-digit code that was sent.',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Inter',
                ),
              ),

              const SizedBox(height: 25),

              /// OTP Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, _buildOtpBox),
              ),

              const SizedBox(height: 20),

              /// Resend Code
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Failed to receive the code? ',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Inter',
                      ),
                    ),
                    InkWell(
                      onTap: _secondsRemaining == 0
                          ? () {
                              // TODO: Resend OTP logic
                              _startResendTimer();
                            }
                          : null,
                      child: Text(
                        _secondsRemaining == 0
                            ? 'Resend code'
                            : 'Resend in $_secondsRemaining s',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          color: _secondsRemaining == 0
                              ? const Color(0xFF21709D)
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              /// Verify Button
              SizedBox(
                width: double.infinity,
                height: 49,
                child: ElevatedButton(
                  onPressed: _isButtonEnabled
                      ? () {
                          final otp = _controllers.map((c) => c.text).join();
                          debugPrint('OTP Entered: $otp');
                          Navigator.push (
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChangePasswordScreen(),
                            ),
                          );
                        }
                      : null, // disabled if not all digits are filled
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isButtonEnabled
                        ? const Color(0xFF21709D)
                        : Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Verify',
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
