import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/api_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _storage = const FlutterSecureStorage();

  Future<String?> get _token => _storage.read(key: 'auth_token');

  Future<Map<String, String>> get _headers async {
    final token = await _token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path, [Map<String, String>? params]) {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    if (params != null) return uri.replace(queryParameters: params);
    return uri;
  }

  // ─── Auth ─────────────────────────────────────────────
  Future<Map<String, dynamic>> signup(Map<String, dynamic> body) async {
    final res = await http.post(_uri(ApiConstants.signup),
        headers: await _headers, body: jsonEncode(body));
    return _handle(res);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(_uri(ApiConstants.login),
        headers: await _headers,
        body: jsonEncode({'email': email, 'password': password}));
    return _handle(res);
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final res = await http.post(_uri(ApiConstants.verifyOtp),
        headers: await _headers, body: jsonEncode({'email': email, 'otp': otp}));
    return _handle(res);
  }

  Future<Map<String, dynamic>> resendOtp(String email) async {
    final res = await http.post(_uri(ApiConstants.resendOtp),
        headers: await _headers, body: jsonEncode({'email': email}));
    return _handle(res);
  }

  Future<Map<String, dynamic>> googleSignIn(String idToken) async {
    final res = await http.post(_uri(ApiConstants.googleSignIn),
        headers: await _headers, body: jsonEncode({'idToken': idToken}));
    return _handle(res);
  }

  // ─── Profile ──────────────────────────────────────────
  Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(_uri(ApiConstants.profile), headers: await _headers);
    return _handle(res);
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) async {
    final res = await http.put(_uri(ApiConstants.profile),
        headers: await _headers, body: jsonEncode(body));
    return _handle(res);
  }

  Future<Map<String, dynamic>> updateSkills(
      List<int> offered, List<int> wanted) async {
    final res = await http.post(_uri(ApiConstants.profileSkills),
        headers: await _headers,
        body: jsonEncode({'skills_offered': offered, 'skills_wanted': wanted}));
    return _handle(res);
  }

  Future<Map<String, dynamic>> getUserProfile(int userId) async {
    final res = await http.get(_uri('${ApiConstants.profile}/$userId'),
        headers: await _headers);
    return _handle(res);
  }

  // ─── Skills ───────────────────────────────────────────
  Future<Map<String, dynamic>> getAllSkills() async {
    final res = await http.get(_uri(ApiConstants.skills), headers: await _headers);
    return _handle(res);
  }

  Future<Map<String, dynamic>> searchSkills(String q) async {
    final res = await http.get(_uri(ApiConstants.skillsSearch, {'q': q}),
        headers: await _headers);
    return _handle(res);
  }

  Future<Map<String, dynamic>> searchUsers(String q, {int page = 1}) async {
    final res = await http.get(
        _uri(ApiConstants.skillsUsers, {'q': q, 'page': '$page'}),
        headers: await _headers);
    return _handle(res);
  }

  // ─── Home ─────────────────────────────────────────────
  Future<Map<String, dynamic>> getDashboard() async {
    final res = await http.get(_uri(ApiConstants.dashboard), headers: await _headers);
    return _handle(res);
  }

  // ─── Trade ────────────────────────────────────────────
  Future<Map<String, dynamic>> sendTradeRequest(Map<String, dynamic> body) async {
    final res = await http.post(_uri(ApiConstants.tradeRequest),
        headers: await _headers, body: jsonEncode(body));
    return _handle(res);
  }

  Future<Map<String, dynamic>> getMyTrades({String? status}) async {
    final params = status != null ? {'status': status} : null;
    final res = await http.get(_uri(ApiConstants.trades, params), headers: await _headers);
    return _handle(res);
  }

  Future<Map<String, dynamic>> respondToTrade(int tradeId, String action) async {
    final res = await http.put(_uri('${ApiConstants.trades}/$tradeId/respond'),
        headers: await _headers, body: jsonEncode({'action': action}));
    return _handle(res);
  }

  Future<Map<String, dynamic>> rateTrade(
      int tradeId, double stars, String? comment) async {
    final res = await http.post(_uri('${ApiConstants.trades}/$tradeId/rate'),
        headers: await _headers,
        body: jsonEncode({'stars': stars, 'comment': comment}));
    return _handle(res);
  }

  // ─── Chats ────────────────────────────────────────────
  Future<Map<String, dynamic>> getChats() async {
    final res = await http.get(_uri(ApiConstants.chats), headers: await _headers);
    return _handle(res);
  }

  Future<Map<String, dynamic>> getMessages(int otherUserId, {int page = 1}) async {
    final res = await http.get(
        _uri('${ApiConstants.chats}/$otherUserId/messages', {'page': '$page'}),
        headers: await _headers);
    return _handle(res);
  }

  Future<Map<String, dynamic>> sendMessage(Map<String, dynamic> body) async {
    final res = await http.post(_uri(ApiConstants.messages),
        headers: await _headers, body: jsonEncode(body));
    return _handle(res);
  }

  // ─── Notifications ────────────────────────────────────
  Future<Map<String, dynamic>> getNotifications() async {
    final res =
        await http.get(_uri(ApiConstants.notifications), headers: await _headers);
    return _handle(res);
  }

  Future<Map<String, dynamic>> markNotificationsRead() async {
    final res = await http.put(_uri('${ApiConstants.notifications}/read-all'),
        headers: await _headers);
    return _handle(res);
  }

  // ─── Token management ─────────────────────────────────
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
  }

  // ─── Response handler ─────────────────────────────────
  Map<String, dynamic> _handle(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw ApiException(
      message: body['message'] ?? 'Something went wrong',
      statusCode: res.statusCode,
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => message;
}
