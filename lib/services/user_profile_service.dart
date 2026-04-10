import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles reading/writing user profile data in Firestore.
class UserProfileService {
  UserProfileService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Create or update a user profile document in the `users` collection.
  static Future<void> upsertUserProfile({
    required String uid,
    required String username,
    required String email,
    required String phoneNumber,
    bool setCreatedAt = false,
  }) async {
    final data = <String, dynamic>{
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (setCreatedAt) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await _db.collection('users').doc(uid).set(
      data,
      SetOptions(merge: true),
    );
  }
}

