import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'user_profile_service.dart';

class AuthService {
  static const String _userKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';

  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;

  /// Sign in with Firebase using email + password.
  Future<User> signIn(String username, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: username,
      password: password,
    );

    final fbUser = credential.user;
    if (fbUser == null) {
      throw Exception('Failed to sign in user.');
    }

    final user = _fromFirebaseUser(fbUser, fallbackUsername: username);

    await _saveUser(user);
    await _setLoggedIn(true);

    return user;
  }

  // Sign up user
  Future<User> signUp({
    required String username,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final fbUser = credential.user;
    if (fbUser == null) {
      throw Exception('Failed to create user.');
    }

    // Store display name in Firebase for convenience.
    await fbUser.updateDisplayName(username);

    final user = User(
      id: fbUser.uid,
      username: username,
      email: fbUser.email ?? email,
      phoneNumber: phoneNumber,
      createdAt: fbUser.metadata.creationTime,
      updatedAt: fbUser.metadata.lastSignInTime,
    );

    await UserProfileService.upsertUserProfile(
      uid: fbUser.uid,
      username: username,
      email: user.email,
      phoneNumber: phoneNumber,
    );

    await _saveUser(user);
    await _setLoggedIn(true);

    return user;
  }

  // Sign out user
  Future<void> signOut() async {
    await _firebaseAuth.signOut();

    await _clearUser();
    await _setLoggedIn(false);
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    
    if (userJson != null) {
      return User.fromJson(json.decode(userJson) as Map<String, dynamic>);
    }
    return null;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Update user profile
  Future<User> updateProfile({
    String? username,
    String? email,
    String? phoneNumber,
  }) async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) {
      throw Exception('No user logged in');
    }

    if (username != null && username.isNotEmpty) {
      await fbUser.updateDisplayName(username);
    }
    if (email != null && email.isNotEmpty && email != fbUser.email) {
      await fbUser.updateEmail(email);
    }

    final current = await getCurrentUser();
    final updatedUser = (current ?? _fromFirebaseUser(fbUser)).copyWith(
      username: username,
      email: email,
      phoneNumber: phoneNumber,
      updatedAt: DateTime.now(),
    );

    await _saveUser(updatedUser);
    return updatedUser;
  }

  // Change password
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) {
      throw Exception('No user logged in');
    }

    // Firebase requires recent login for sensitive operations.
    // The caller should ensure the user has recently logged in.
    await fbUser.updatePassword(newPassword);
  }

  // Forgot password
  Future<void> forgotPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  // Private helper methods

  User _fromFirebaseUser(
    fb.User fbUser, {
    String? fallbackUsername,
  }) {
    return User(
      id: fbUser.uid,
      username: fbUser.displayName ?? fallbackUsername ?? fbUser.email ?? '',
      email: fbUser.email ?? '',
      phoneNumber: fbUser.phoneNumber ?? '',
      createdAt: fbUser.metadata.creationTime,
      updatedAt: fbUser.metadata.lastSignInTime,
    );
  }

  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
  }

  Future<void> _setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, value);
  }

  Future<void> _clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_isLoggedInKey);
  }
}

