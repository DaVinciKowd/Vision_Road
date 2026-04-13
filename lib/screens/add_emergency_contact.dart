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

  // ✅ NEW: Save to Firestore
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

            // BACK ICON (UNCHANGED)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 60,
                width: double.infinity,
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

            // FORM (UNCHANGED)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Form(
                key: formKey,
                child: Column(
                  children: [

                    // NAME
                    TextFormField(
                      controller: nameController,
                      focusNode: nameFocus,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(phoneFocus);
                      },

                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r"[a-zA-Z\s\.]"),
                        ),
                      ],

                      decoration: _inputDecoration("Name", Icons.person),

                      validator: (value) {
                        if (!isSubmitted) return null;

                        final name = value?.trim() ?? "";

                        if (name.isEmpty) {
                          return "Enter name";
                        }

                        if (!RegExp(r"^[a-zA-Z\s\.]+$").hasMatch(name)) {
                          return "Name can only contain letters and dot";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    // PHONE
                    TextFormField(
                      controller: phoneController,
                      focusNode: phoneFocus,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(emailFocus);
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      decoration: _inputDecoration("Phone Number", Icons.phone),

                      validator: (value) {
                        if (!isSubmitted) return null;

                        final phone = value?.replaceAll(" ", "") ?? "";

                        if (phone.isEmpty) {
                          return "Phone number is required";
                        }

                        if (phone.length != 11) {
                          return "Must be 11 digits";
                        }

                        if (!phone.startsWith("09")) {
                          return "Must start with 09";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    // EMAIL
                    TextFormField(
                      controller: emailController,
                      focusNode: emailFocus,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.emailAddress,
                      onFieldSubmitted: (_) {
                        emailFocus.unfocus();
                      },
                      onChanged: (value) {
                        final lower = value.trim().toLowerCase();

                        if (value != lower) {
                          emailController.value = TextEditingValue(
                            text: lower,
                            selection: TextSelection.collapsed(
                              offset: lower.length,
                            ),
                          );
                        }

                        if (isSubmitted) {
                          formKey.currentState!.validate();
                        }
                      },
                      decoration: _inputDecoration("Email Address", Icons.email),

                      validator: (value) {
                        if (!isSubmitted) return null;

                        final email = value?.trim().toLowerCase() ?? "";

                        if (email.isEmpty) {
                          return "Email is required";
                        }

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

            // SAVE BUTTON (UPDATED WITH FIRESTORE)
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
                      });

                      if (formKey.currentState!.validate()) {
                        final newContact = EmergencyContact(
                          name: nameController.text,
                          phone: phoneController.text,
                          email: emailController.text.toLowerCase(),
                        );

                        try {
                          await _saveToFirestore(newContact);

                          if (!context.mounted) return;
                          Navigator.pop(context, newContact);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: $e")),
                          );
                        }
                      }
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

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.grey, size: 19),
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),
    );
  }
}