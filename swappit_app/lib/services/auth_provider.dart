import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'api_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final _api = ApiService();
  final _storage = const FlutterSecureStorage();
  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // Check token on app start
  Future<void> checkAuthStatus() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      try {
        final res = await _api.getProfile();
        _user = UserModel.fromJson(res['user']);
        _status = AuthStatus.authenticated;
      } catch (_) {
        await _api.clearToken();
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ─── Sign Up ──────────────────────────────────────────
  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    _setLoading(true);
    try {
      await _api.signup({
        'name': name,
        'email': email,
        'password': password,
        if (phone != null) 'phone': phone,
      });
      _clearError();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Verify OTP ───────────────────────────────────────
  Future<bool> verifyOtp(String email, String otp) async {
    _setLoading(true);
    try {
      final res = await _api.verifyOtp(email, otp);
      await _api.saveToken(res['token']);
      _user = UserModel.fromJson(res['user']);
      _status = AuthStatus.authenticated;
      _clearError();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Login ────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final res = await _api.login(email, password);
      await _api.saveToken(res['token']);
      _user = UserModel.fromJson(res['user']);
      _status = AuthStatus.authenticated;
      _clearError();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Google Sign-In ───────────────────────────────────
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    _setLoading(true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) throw Exception('Failed to get Google ID token');

      final res = await _api.googleSignIn(idToken);
      await _api.saveToken(res['token']);
      _user = UserModel.fromJson(res['user']);
      _status = AuthStatus.authenticated;
      _clearError();
      notifyListeners();
      return res;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Update User ──────────────────────────────────────
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final res = await _api.updateProfile(data);
      _user = UserModel.fromJson(res['user']);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Logout ───────────────────────────────────────────
  Future<void> logout() async {
    await _api.clearToken();
    await _googleSignIn.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
