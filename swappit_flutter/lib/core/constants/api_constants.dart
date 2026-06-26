import 'package:flutter/foundation.dart';

class ApiConstants {
  // Change to your deployed URL in production
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5000';
      case TargetPlatform.iOS:
        return 'http://localhost:5000';
      default:
        return 'http://localhost:5000';
    }
  }

  // Auth
  static const String signup = '/auth/signup';
  static const String login = '/auth/login';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String googleSignIn = '/auth/google';

  // Profile
  static const String profile = '/profile';
  static const String profilePhoto = '/profile/photo';
  static const String profileSkills = '/profile/skills';

  // Skills
  static const String skills = '/skills';
  static const String skillsSearch = '/skills/search';
  static const String skillsUsers = '/skills/users';

  // Home
  static const String dashboard = '/home/dashboard';

  // Trade
  static const String tradeRequest = '/trade/request';
  static const String trades = '/trade';

  // Chats
  static const String chats = '/chats';
  static const String messages = '/chats/messages';

  // Notifications
  static const String notifications = '/notifications';
}
