import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String _url = 'https://rvhfercptdysbfkcwevo.supabase.co';
  static const String _anonKey =
      'sb_publishable__vUgXL3gOPI-F1JLryDJNg_EUJNiKkH';

  static SupabaseService? _instance;
  late final SupabaseClient client;

  SupabaseService._() {
    client = Supabase.instance.client;
  }

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _url,
      publishableKey: _anonKey,
    );
  }

  User? get currentUser => client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<AuthResponse> signUp(String email, String password, {Map<String, dynamic>? data}) async {
    return await client.auth.signUp(email: email, password: password, data: data);
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }
}
