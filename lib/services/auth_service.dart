import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static const String _userKey = 'current_user';
  static const String _tokenKey = 'auth_token';
  static const String _isLoggedInKey = 'is_logged_in';

  final ApiService _apiService = ApiService();

  // Sign in user
  Future<User> signIn(String username, String password) async {
    try {
      // TODO: Replace with actual API endpoint
      final response = await _apiService.post('/auth/signin', {
        'username': username,
        'password': password,
      });

      final user = User.fromJson(response['user']);
      final token = response['token'] as String;

      // Save user and token
      await _saveUser(user);
      await _saveToken(token);
      await _setLoggedIn(true);
      ApiService.setAuthToken(token);

      return user;
    } catch (e) {
      // For development: return mock user if API fails
      if (e.toString().contains('Network error')) {
        // Mock authentication for development
        final mockUser = User(
          id: '1',
          username: username,
          email: '$username@example.com',
          phoneNumber: '0531 652 1234',
          createdAt: DateTime.now(),
        );
        await _saveUser(mockUser);
        await _setLoggedIn(true);
        return mockUser;
      }
      rethrow;
    }
  }

  // Sign up user
  Future<User> signUp({
    required String username,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    try {
      // TODO: Replace with actual API endpoint
      final response = await _apiService.post('/auth/signup', {
        'username': username,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
      });

      final user = User.fromJson(response['user']);
      final token = response['token'] as String;

      // Save user and token
      await _saveUser(user);
      await _saveToken(token);
      await _setLoggedIn(true);
      ApiService.setAuthToken(token);

      return user;
    } catch (e) {
      // For development: return mock user if API fails
      if (e.toString().contains('Network error')) {
        final mockUser = User(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          username: username,
          email: email,
          phoneNumber: phoneNumber,
          createdAt: DateTime.now(),
        );
        await _saveUser(mockUser);
        await _setLoggedIn(true);
        return mockUser;
      }
      rethrow;
    }
  }

  // Sign out user
  Future<void> signOut() async {
    try {
      // TODO: Call API to invalidate token
      // await _apiService.post('/auth/signout', {});
    } catch (e) {
      // Ignore errors during signout
    }

    await _clearUser();
    await _clearToken();
    await _setLoggedIn(false);
    ApiService.setAuthToken(null);
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    
    if (userJson != null) {
      return User.fromJson(json.decode(userJson));
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
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // TODO: Replace with actual API endpoint
      final response = await _apiService.put('/user/profile', {
        if (username != null) 'username': username,
        if (email != null) 'email': email,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
      });

      final updatedUser = User.fromJson(response['user']);
      await _saveUser(updatedUser);
      return updatedUser;
    } catch (e) {
      // For development: update locally if API fails
      if (e.toString().contains('Network error')) {
        final currentUser = await getCurrentUser();
        if (currentUser != null) {
          final updatedUser = currentUser.copyWith(
            username: username,
            email: email,
            phoneNumber: phoneNumber,
            updatedAt: DateTime.now(),
          );
          await _saveUser(updatedUser);
          return updatedUser;
        }
      }
      rethrow;
    }
  }

  // Change password
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      // TODO: Replace with actual API endpoint
      await _apiService.post('/user/change-password', {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Forgot password
  Future<void> forgotPassword(String email) async {
    try {
      // TODO: Replace with actual API endpoint
      await _apiService.post('/auth/forgot-password', {
        'email': email,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Private helper methods
  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    ApiService.setAuthToken(token);
  }

  Future<void> _setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, value);
  }

  Future<void> _clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}

