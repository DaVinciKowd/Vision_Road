import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'emergency_contact.dart';
import '../providers/auth_provider.dart';

class AddEmergencyContactPage extends StatefulWidget {
  const AddEmergencyContactPage({super.key});

  @override
  State<AddEmergencyContactPage> createState() =>
      _AddEmergencyContactPageState();
}

class _AddEmergencyContactPageState extends State<AddEmergencyContactPage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  final nameFocus = FocusNode();
  final phoneFocus = FocusNode();
  final emailFocus = FocusNode();

  final formKey = GlobalKey<FormState>();
  bool isSubmitted = false;

  OverlayEntry? _messageOverlay;

  // ================================
  // NEW: ERROR FLAGS (ADDED ONLY)
  // ================================
  bool phoneExistsError = false;
  bool emailExistsError = false;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();

    nameFocus.dispose();
    phoneFocus.dispose();
    emailFocus.dispose();

    super.dispose();
  }

  // ================================
  // CUSTOM OVERLAY (UNCHANGED)
  // ================================
  void _showMessage(String message) {
    _messageOverlay?.remove();

    _messageOverlay = OverlayEntry(
      builder: (context) {
        return Positioned(
          bottom: 90,
          left: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF21709D).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Color(0xFF21709D),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_messageOverlay!);

    Future.delayed(const Duration(seconds: 3), () {
      _messageOverlay?.remove();
      _messageOverlay = null;
    });
  }

  // ================================
  // DUPLICATE CHECK (IMPROVED ONLY)
  // ================================
  Future<Map<String, bool>> _checkDuplicates(
      String userId, String phone, String email) async {
    final phoneCheck = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('emergency_contacts')
        .where('phone', isEqualTo: phone)
        .get();

    final emailCheck = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('emergency_contacts')
        .where('email', isEqualTo: email)
        .get();

    return {
      'phoneExists': phoneCheck.docs.isNotEmpty,
      'emailExists': emailCheck.docs.isNotEmpty,
    };
  }

  // ================================
  // SAVE TO FIRESTORE (UNCHANGED)
  // ================================
  Future<void> _saveToFirestore(EmergencyContact contact) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId == null) {
      throw Exception("User not logged in");
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('emergency_contacts')
        .add({
      'name': contact.name,
      'phone': contact.phone,
      'email': contact.email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ================================
  // INPUT DECORATION (MODIFIED ONLY)
  // ================================
  InputDecoration _inputDecoration(
    String hint,
    IconData icon, {
    bool hasError = false,
  }) {
    return InputDecoration(
      prefixIcon: Icon(
        icon,
        color: hasError ? Colors.red : Colors.grey,
        size: 19,
      ),
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(
          color:
              hasError ? Colors.red.withOpacity(0.5) : Colors.transparent,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(
          color: hasError ? Colors.red : const Color(0xFF21709D),
          width: 1.5,
        ),
      ),
    );
  }

  // ================================
  // UI
  // ================================
  @override
  Widget build(BuildContext context) {
    final buttonWidth = MediaQuery.of(context).size.width * 0.75;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF5F5F5),

      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // BACK BUTTON (UNCHANGED)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 60,
                child: Stack(
                  children: [
                    Positioned(
                      top: 18,
                      left: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                          'assets/back_iconblue.png',
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25),
              child: Text(
                "Add\nEmergency Contact",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
            ),

            const SizedBox(height: 8),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25),
              child: Text(
                "Add a person we can contact in case of emergency",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // FORM (UNCHANGED VALIDATION LOGIC)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Form(
                key: formKey,
                child: Column(
                  children: [

                    // NAME (UNCHANGED)
                    TextFormField(
                      controller: nameController,
                      focusNode: nameFocus,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(phoneFocus),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r"[a-zA-Z\s\.]"),
                        ),
                      ],
                      decoration: _inputDecoration("Name", Icons.person),
                      validator: (value) {
                        if (!isSubmitted) return null;

                        final name = value?.trim() ?? "";

                        if (name.isEmpty) return "Enter name";

                        if (!RegExp(r"^[a-zA-Z\s\.]+$").hasMatch(name)) {
                          return "Only letters and dot allowed";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    // PHONE (NOW WITH RED HIGHLIGHT)
                    TextFormField(
                      controller: phoneController,
                      focusNode: phoneFocus,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      decoration: _inputDecoration(
                        "Phone Number",
                        Icons.phone,
                        hasError: phoneExistsError,
                      ),
                      validator: (value) {
                        if (!isSubmitted) return null;

                        final phone = value?.trim() ?? "";

                        if (phone.isEmpty) return "Phone required";
                        if (phone.length != 11) return "Must be 11 digits";
                        if (!phone.startsWith("09")) return "Must start with 09";

                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    // EMAIL (NOW WITH RED HIGHLIGHT)
                    TextFormField(
                      controller: emailController,
                      focusNode: emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onChanged: (value) {
                        final lower = value.toLowerCase();
                        if (value != lower) {
                          emailController.value = TextEditingValue(
                            text: lower,
                            selection: TextSelection.collapsed(
                              offset: lower.length,
                            ),
                          );
                        }
                      },
                      decoration: _inputDecoration(
                        "Email Address",
                        Icons.email,
                        hasError: emailExistsError,
                      ),
                      validator: (value) {
                        if (!isSubmitted) return null;

                        final email = value?.trim().toLowerCase() ?? "";

                        if (email.isEmpty) return "Email required";
                        if (!email.endsWith("@gmail.com")) {
                          return "Must end with @gmail.com";
                        }

                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // SAVE BUTTON (UPDATED ONLY LOGIC)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Center(
                child: SizedBox(
                  width: buttonWidth,
                  height: 43,
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        isSubmitted = true;
                        phoneExistsError = false;
                        emailExistsError = false;
                      });

                      if (!formKey.currentState!.validate()) return;

                      final auth =
                          Provider.of<AuthProvider>(context, listen: false);
                      final userId = auth.currentUser?.id;

                      if (userId == null) {
                        _showMessage("User not logged in");
                        return;
                      }

                      final phone = phoneController.text.trim();
                      final email =
                          emailController.text.trim().toLowerCase();

                      final result =
                          await _checkDuplicates(userId, phone, email);

                      phoneExistsError = result['phoneExists'] ?? false;
                      emailExistsError = result['emailExists'] ?? false;

                      if (phoneExistsError && emailExistsError) {
                        _showMessage("Phone number and email already exist");
                      } else if (phoneExistsError) {
                        _showMessage("Phone number already exists");
                      } else if (emailExistsError) {
                        _showMessage("Email already exists");
                      }

                      if (phoneExistsError || emailExistsError) {
                        setState(() {});
                        return;
                      }

                      final newContact = EmergencyContact(
                        name: nameController.text.trim(),
                        phone: phone,
                        email: email,
                      );

                      await _saveToFirestore(newContact);

                      if (!context.mounted) return;
                      Navigator.pop(context, newContact);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF21709D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "Save Contact",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}