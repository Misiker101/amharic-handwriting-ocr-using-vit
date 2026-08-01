import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/home_screen.dart';

class AmharicOcrApp extends StatelessWidget {
  const AmharicOcrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amharic OCR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}