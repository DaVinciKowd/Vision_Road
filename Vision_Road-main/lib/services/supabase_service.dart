import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';

/// Service for Supabase API: auth, database, and storage.
/// Initialize Supabase in main() via [SupabaseService.initialize] before using.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// Initialize Supabase. Call once in main() before runApp().
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  /// Access the Supabase client directly when needed.
  static SupabaseClient get client => _client;

  // --- Auth ---

  static GoTrueClient get auth => _client.auth;

  static User? get currentUser => _client.auth.currentUser;

  static Session? get currentSession => _client.auth.currentSession;

  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign in with email and password.
  static Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) =>
      _client.auth.signInWithPassword(email: email, password: password);

  /// Sign up with email and password.
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? redirectTo,
    Map<String, dynamic>? data,
  }) =>
      _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: redirectTo,
        data: data,
      );

  /// Sign out.
  static Future<void> signOut() => _client.auth.signOut();

  /// Reset password for email.
  static Future<void> resetPasswordForEmail(String email, {String? redirectTo}) =>
      _client.auth.resetPasswordForEmail(email, redirectTo: redirectTo);

  /// Update user (e.g. password).
  static Future<UserResponse> updateUser(UserAttributes attributes) =>
      _client.auth.updateUser(attributes);

  // --- Database (Realtime-capable table access) ---

  /// Select from a table. Returns list of maps.
  static Future<List<Map<String, dynamic>>> from(String table) async {
    final response = await _client.from(table).select();
    return List<Map<String, dynamic>>.from(
      (response as List).map((e) => e as Map<String, dynamic>),
    );
  }

  /// Select with filters. Chain .eq(), .filter() etc. on the builder.
  static dynamic fromTable(String table) => _client.from(table).select();

  /// Insert one or more rows. Set [upsert] true to upsert (update on conflict).
  static Future<List<Map<String, dynamic>>> insert(
    String table,
    Map<String, dynamic> data, {
    bool upsert = false,
  }) async {
    final response = upsert
        ? await _client.from(table).upsert(data).select()
        : await _client.from(table).insert(data).select();
    return List<Map<String, dynamic>>.from(
      (response as List).map((e) => e as Map<String, dynamic>),
    );
  }

  /// Update rows (optionally with .eq() filter).
  static Future<List<Map<String, dynamic>>> update(
    String table,
    Map<String, dynamic> data, {
    String? column,
    dynamic value,
  }) async {
    var query = _client.from(table).update(data);
    if (column != null && value != null) {
      query = query.eq(column, value);
    }
    final response = await query.select();
    return List<Map<String, dynamic>>.from(
      (response as List).map((e) => e as Map<String, dynamic>),
    );
  }

  /// Delete rows (optionally with .eq() filter).
  static Future<void> delete(
    String table, {
    String? column,
    dynamic value,
  }) async {
    var query = _client.from(table).delete();
    if (column != null && value != null) {
      query = query.eq(column, value);
    }
    await query;
  }

  /// RPC (call a Postgres function).
  static Future<List<Map<String, dynamic>>> rpc(
    String functionName, {
    Map<String, dynamic> params = const {},
  }) async {
    final response = await _client.rpc(functionName, params: params);
    if (response == null) return [];
    return List<Map<String, dynamic>>.from(
      (response as List).map((e) => e as Map<String, dynamic>),
    );
  }

  // --- Storage ---

  static SupabaseStorageClient get storage => _client.storage;

  /// Upload a file to a bucket.
  static Future<String> upload(
    String bucket,
    String path,
    dynamic file, {
    FileOptions? fileOptions,
  }) async {
    await _client.storage.from(bucket).upload(
      path,
      file,
      fileOptions: fileOptions ?? FileOptions(),
    );
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  /// Get public URL for a file.
  static String getPublicUrl(String bucket, String path) =>
      _client.storage.from(bucket).getPublicUrl(path);

  /// Download file bytes.
  static Future<List<int>> download(String bucket, String path) =>
      _client.storage.from(bucket).download(path);

  /// Remove file(s) from a bucket.
  static Future<void> remove(String bucket, List<String> paths) =>
      _client.storage.from(bucket).remove(paths);
}
