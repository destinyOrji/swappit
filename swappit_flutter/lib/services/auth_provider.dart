import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final _api = ApiService();

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // ─── Token helpers (SharedPreferences — works on web + mobile) ───
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await _api.saveToken(token);
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await _api.clearToken();
  }

  // ─── Check auth on app start ──────────────────────────
  Future<void> checkAuthStatus() async {
    final token = await _getToken();
    if (token != null && token.isNotEmpty) {
      await _api.saveToken(token);
      try {
        final res = await _api.getProfile();
        _user = UserModel.fromJson(res['user']);
        _status = AuthStatus.authenticated;
      } catch (_) {
        await _clearToken();
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
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
      _clearError();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Network error. Is the backend running?';
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
      await _saveToken(res['token']);
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
      await _saveToken(res['token']);
      _user = UserModel.fromJson(res['user']);
      _status = AuthStatus.authenticated;
      _clearError();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Network error. Is the backend running?';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Google Sign-In ───────────────────────────────────
  // NOTE: Google Sign-In on web requires a real OAuth Client ID
  // configured in web/index.html. Set GOOGLE_CLIENT_ID env var
  // or add: <meta name="google-signin-client_id" content="YOUR_ID">
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    _error = 'Google Sign-In requires a Google OAuth Client ID.\n'
        'Add your Client ID to web/index.html to enable this.';
    notifyListeners();
    return null;
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
    await _clearToken();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _clearError() => _error = null;

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
