import 'package:flutter/material.dart';
import 'package:freelancer_flutter/src/core/api/api_client.dart';
import 'package:freelancer_flutter/src/features/auth/presentation/auth_selection_screen.dart';
import 'package:freelancer_flutter/src/features/home/presentation/main_screen.dart';
import 'package:freelancer_flutter/src/features/onboarding/presentation/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Artificial delay for splash effect (optional, keep it short)
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    try {
      final hasToken = await _apiClient.hasToken();
      
      if (!mounted) return;

      if (hasToken) {
        // Token exists, navigate to MainScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        // No token, navigate to Onboarding
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    } catch (e) {
      // On error, default to onboarding
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Or use theme color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // You can add your App Logo here
            // Image.asset('assets/images/logo.png', width: 150),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
