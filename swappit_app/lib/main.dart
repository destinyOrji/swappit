import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'services/auth_provider.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding/onboarding_flow.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..checkAuthStatus(),
      child: const SwappitApp(),
    ),
  );
}

class SwappitApp extends StatelessWidget {
  const SwappitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swappit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routes: {
        '/': (_) => const _AuthGate(),
        '/home': (_) => const MainShell(),
        '/onboarding': (_) => const OnboardingFlow(),
      },
      initialRoute: '/',
    );
  }
}

/// Watches auth state and routes accordingly
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.unknown:
        // Loading splash
        return const Scaffold(
          backgroundColor: AppColors.primary,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swap_horiz_rounded, size: 72, color: Colors.white),
                SizedBox(height: 16),
                Text('Swappit',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ],
            ),
          ),
        );

      case AuthStatus.authenticated:
        if (auth.user?.isProfileComplete == true) {
          return const MainShell();
        }
        return const OnboardingFlow();

      case AuthStatus.unauthenticated:
        return const WelcomeScreen();
    }
  }
}
