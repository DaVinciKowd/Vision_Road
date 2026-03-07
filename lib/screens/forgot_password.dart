import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+");
    return emailRegex.hasMatch(email);
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address.');
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }

    setState(() => _errorMessage = null);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.forgotPassword(email);

    if (success) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Password reset sent'),
          content: const Text(
            'A password reset link was sent to your email. Check your inbox and follow the instructions to reset your password.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } else {
      setState(() {
        _errorMessage = authProvider.error ?? 'Failed to send reset email.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

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
                "Fill in your email and we'll send a link\n"
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
                child: TextField(
                  controller: _emailController,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(
                    color: Color(0xFF0C2737),
                    fontSize: 15,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Email Address',
                    hintStyle: TextStyle(
                      color: Color(0x4D0C2737),
                      fontSize: 15,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ],

              const SizedBox(height: 25),

              /// Send Reset Link Button
              SizedBox(
                width: double.infinity,
                height: 49,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _sendResetEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF21709D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Send Reset Link',
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
