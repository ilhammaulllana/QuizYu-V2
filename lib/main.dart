import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'views/main_navigation_wrapper.dart';

void main() {
  runApp(const ProviderScope(child: QuizyuApp()));
}

class QuizyuApp extends StatelessWidget {
  const QuizyuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'quizyu - AI Smart Quiz',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: AppTheme.lightTheme,
      home: const MainNavigationWrapper(),
    );
  }
}
