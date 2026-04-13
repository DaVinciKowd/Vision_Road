import 'package:flutter/material.dart';
import 'add_emergency_contact.dart';

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
  State<EmergencyContactPage> createState() => _EmergencyContactPageState();
}

class _EmergencyContactPageState extends State<EmergencyContactPage> {
  List<EmergencyContact> contacts = [];

  // ✅ Undo state
  OverlayEntry? _undoOverlay;
  EmergencyContact? _deletedContact;
  int? _deletedIndex;

  void _addContact() async {
    final newContact = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEmergencyContactPage(),
      ),
    );

    if (newContact != null && newContact is EmergencyContact) {
      setState(() {
        contacts.add(newContact);
      });
    }
  }

  // ✅ Show custom iOS-style undo bar
  void _showUndoBar(EmergencyContact contact, int index) {
    _undoOverlay?.remove();

    _deletedContact = contact;
    _deletedIndex = index;

    _undoOverlay = OverlayEntry(
      builder: (context) {
        return Positioned(
          bottom: 90,
          left: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 250),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - value) * 40),
                  child: Opacity(opacity: value, child: child),
                );
              },
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

                    // ICON
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF21709D).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete,
                        size: 18,
                        color: Color(0xFF21709D),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // TEXT
                    const Expanded(
                      child: Text(
                        "Contact deleted",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    // UNDO BUTTON
                    GestureDetector(
                      onTap: _undoDelete,
                      child: const Text(
                        "UNDO",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF21709D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_undoOverlay!);

    // auto remove after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      _undoOverlay?.remove();
      _undoOverlay = null;
      _deletedContact = null;
      _deletedIndex = null;
    });
  }

  // ✅ Undo action
  void _undoDelete() {
    if (_deletedContact == null || _deletedIndex == null) return;

    setState(() {
      contacts.insert(_deletedIndex!, _deletedContact!);
    });

    _undoOverlay?.remove();
    _undoOverlay = null;
    _deletedContact = null;
    _deletedIndex = null;
  }

  @override
  Widget build(BuildContext context) {
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

          // CONTACT LIST
          Expanded(
            child: contacts.isEmpty
                ? const Center(
                    child: Text(
                      "No Contacts Yet",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];

                      return Dismissible(
                        key: ValueKey(contact.phone + contact.email),

                        direction: DismissDirection.endToStart,

                        dismissThresholds: const {
                          DismissDirection.endToStart: 0.35,
                        },

                        movementDuration:
                            const Duration(milliseconds: 120),
                        resizeDuration:
                            const Duration(milliseconds: 120),

                        background: Container(),

                        secondaryBackground: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(Icons.delete, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                "Delete",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        onDismissed: (direction) {
                          final removed = contact;

                          setState(() {
                            contacts.removeAt(index);
                          });

                          _showUndoBar(removed, index);
                        },

                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0x4DABADAE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      contact.name.toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF21709D),
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
                  ),
          ),
        ],
      ),

      // ADD BUTTON
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