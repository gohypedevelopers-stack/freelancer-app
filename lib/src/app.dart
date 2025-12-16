import 'package:flutter/material.dart';
import 'package:freelancer_flutter/src/core/theme/app_theme.dart';
import 'package:freelancer_flutter/src/features/onboarding/presentation/onboarding_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Freelancer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // Default to dark theme for premium feel
      home: const OnboardingScreen(),
    );
  }
}
