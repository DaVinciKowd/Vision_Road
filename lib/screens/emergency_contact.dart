import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'add_emergency_contact.dart';
import '../providers/auth_provider.dart';

class EmergencyContact {
  String name;
  String phone;
  String email;

  EmergencyContact({
    required this.name,
    required this.phone,
    required this.email,
  });
}

class EmergencyContactPage extends StatefulWidget {
  const EmergencyContactPage({super.key});

  @override
  State<EmergencyContactPage> createState() =>
      _EmergencyContactPageState();
}

class _EmergencyContactPageState extends State<EmergencyContactPage> {

  OverlayEntry? _undoOverlay;
  EmergencyContact? _deletedContact;
  String? _deletedDocId;

  // ================================
  // ADD CONTACT (NO DOUBLE SAVE)
  // ================================
  void _addContact() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEmergencyContactPage(),
      ),
    );

    // ✅ No setState needed
    // StreamBuilder auto updates UI
  }

  // ================================
  // DELETE + UNDO UI
  // ================================
  void _showUndoBar(EmergencyContact contact, String docId) {
    _undoOverlay?.remove();

    _deletedContact = contact;
    _deletedDocId = docId;

    _undoOverlay = OverlayEntry(
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
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text("Contact deleted"),
                  ),
                  GestureDetector(
                    onTap: _undoDelete,
                    child: const Text(
                      "UNDO",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF21709D),
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

    Overlay.of(context).insert(_undoOverlay!);

    Future.delayed(const Duration(seconds: 5), () {
      _undoOverlay?.remove();
      _undoOverlay = null;
      _deletedContact = null;
      _deletedDocId = null;
    });
  }

  // ================================
  // UNDO DELETE
  // ================================
  Future<void> _undoDelete() async {
    if (_deletedContact == null || _deletedDocId == null) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.currentUser?.id;

    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('emergency_contacts')
        .doc(_deletedDocId!)
        .set({
      'name': _deletedContact!.name,
      'phone': _deletedContact!.phone,
      'email': _deletedContact!.email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _undoOverlay?.remove();
    _undoOverlay = null;
  }

  // ================================
  // UI
  // ================================
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userId = auth.currentUser?.id;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [

          // HEADER
          Container(
            height: 90,
            width: double.infinity,
            color: Colors.white,
            child: Stack(
              children: [
                Positioned(
                  top: 50,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      'assets/back_iconblue.png',
                      width: 20,
                      height: 20,
                    ),
                  ),
                ),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 30),
                    child: Text(
                      'Emergency Contacts',
                      style: TextStyle(
                        fontSize: 24,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: userId == null
                ? const Center(child: Text("User not logged in"))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('emergency_contacts')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),

                    builder: (context, snapshot) {

                      // 🔄 LOADING
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      // ❌ ERROR
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text("Error loading contacts"),
                        );
                      }

                      final docs = snapshot.data!.docs;

                      // 📭 EMPTY
                      if (docs.isEmpty) {
                        return const Center(
                          child: Text(
                            "No Contacts Yet",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }

                      // ✅ LIST
                      return ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data =
                              doc.data() as Map<String, dynamic>;

                          final contact = EmergencyContact(
                            name: data['name'],
                            phone: data['phone'],
                            email: data['email'],
                          );

                          return Dismissible(
                            key: Key(doc.id),
                            direction: DismissDirection.endToStart,

                            background: Container(
                              margin:
                                  const EdgeInsets.only(bottom: 10),
                            ),

                            secondaryBackground: Container(
                              margin:
                                  const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3B30),
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.only(right: 20),
                              child: const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.end,
                                children: [
                                  Icon(Icons.delete,
                                      color: Colors.white),
                                  SizedBox(width: 8),
                                  Text("Delete",
                                      style: TextStyle(
                                          color: Colors.white)),
                                ],
                              ),
                            ),

                            onDismissed: (direction) async {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userId)
                                  .collection(
                                      'emergency_contacts')
                                  .doc(doc.id)
                                  .delete();

                              _showUndoBar(contact, doc.id);
                            },

                            child: Container(
                              margin:
                                  const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0x4DABADAE),
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          contact.name
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                            color: Color(
                                                0xFF21709D),
                                          ),
                                        ),
                                        Text(contact.phone),
                                        Text(contact.email),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 24, top: 10),
        child: SizedBox(
          height: 45,
          child: Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.75,
              child: ElevatedButton(
                onPressed: _addContact,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD9D9D9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "+ Add Contact",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}