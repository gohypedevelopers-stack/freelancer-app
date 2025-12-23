import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:freelancer_flutter/src/core/theme/app_theme.dart';
import 'package:freelancer_flutter/src/core/theme/theme_provider.dart';
import 'package:freelancer_flutter/src/features/splash/presentation/splash_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Freelancer',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
