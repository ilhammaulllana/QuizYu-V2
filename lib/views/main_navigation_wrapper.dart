import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quiz_notifier.dart';
import 'home_screen.dart';
import 'quiz_screen.dart';
import 'dashboard_screen.dart';
import 'loading_screen.dart';

class MainNavigationWrapper extends ConsumerWidget {
  const MainNavigationWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizState = ref.watch(quizProvider);

    // Dengarkan status error secara global di wrapper navigasi agar snackbar & log tidak terlewatkan
    ref.listen<AsyncValue>(quizProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          final rawMsg = error.toString().replaceAll('Exception: ', '');
          final isOffline = rawMsg.contains('[OFFLINE]') ||
              rawMsg.toLowerCase().contains('tidak ada koneksi') ||
              rawMsg.toLowerCase().contains('periksa jaringan') ||
              rawMsg.toLowerCase().contains('jaringan terputus');
          final isQuota = !isOffline && (
              rawMsg.contains('[QUOTA_EXCEEDED]') ||
              rawMsg.toLowerCase().contains('rate limit') ||
              rawMsg.toLowerCase().contains('429') ||
              rawMsg.toLowerCase().contains('kuota')
          );

          final displayMsg = rawMsg
              .replaceAll('[OFFLINE] ', '')
              .replaceAll('[QUOTA_EXCEEDED] ', '')
              .replaceAll('[SYSTEM_ERROR] ', '');

          if (isOffline) {
            debugPrint('🌐 [LOG TIDAK ADA KONEKSI INTERNET] $displayMsg');
          } else if (isQuota) {
            debugPrint('⏳ [LOG BATAS KUOTA AI GEMINI TERLAMPAUI] $displayMsg');
          } else {
            debugPrint('❌ [LOG KESALAHAN SISTEM] $displayMsg');
          }

          final scaffold = ScaffoldMessenger.maybeOf(context);
          if (scaffold != null) {
            scaffold.hideCurrentSnackBar();
            scaffold.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      isOffline
                          ? Icons.wifi_off_rounded
                          : isQuota
                              ? Icons.hourglass_top_rounded
                              : Icons.error_outline_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        displayMsg,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: isOffline
                    ? const Color(0xFFD97706)
                    : isQuota
                        ? const Color(0xFF7F5AF0)
                        : const Color(0xFFE11D48),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {
                    scaffold.hideCurrentSnackBar();
                  },
                ),
              ),
            );
          }
        },
      );
    });

    return quizState.when(
      data: (session) {
        if (session == null) {
          return const HomeScreen();
        }
        if (session.isCompleted) {
          return const DashboardScreen();
        }
        return const QuizScreen();
      },
      loading: () => const GorgeousLoadingScreen(),
      error: (error, stack) {
        return const HomeScreen();
      },
    );
  }
}
