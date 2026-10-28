import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/quiz_notifier.dart';
import '../providers/study_guide_notifier.dart';
import 'loading_screen.dart';

const Color primaryPurple = Color(0xFF7950F2);
const Color darkPurple = Color(0xFF6741E8);
const Color backgroundColor = Color(0xFFF8F9FF);
const Color darkText = Color(0xFF111827);
const Color mutedText = Color(0xFF64748B);

class StudyGuideScreen extends ConsumerWidget {
  const StudyGuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guideState = ref.watch(studyGuideProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F3FF), Color(0xFFFFFFFF), Color(0xFFF8FAFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'QuizYu',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: primaryPurple,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: primaryPurple,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: primaryPurple.withOpacity(0.25),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                  ],
                ),
              ),

              // MAIN CONTENT
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Column(
                        children: [
                          // GUIDE CONTENT
                          Expanded(
                            child: guideState.when(
                              data: (markdownText) {
                                if (markdownText == null ||
                                    markdownText.isEmpty) {
                                  return _emptyState();
                                }

                                return Column(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFEAE8F4),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF64748B,
                                              ).withOpacity(0.07),
                                              blurRadius: 25,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
                                          child: Markdown(
                                            data: markdownText,
                                            selectable: true,
                                            padding: const EdgeInsets.all(28),
                                            styleSheet: MarkdownStyleSheet(
                                              p: const TextStyle(
                                                fontSize: 14,
                                                height: 1.8,
                                                color: Color(0xFF475569),
                                              ),
                                              h1: const TextStyle(
                                                fontSize: 25,
                                                fontWeight: FontWeight.w800,
                                                color: darkText,
                                                height: 1.5,
                                              ),
                                              h2: const TextStyle(
                                                fontSize: 19,
                                                fontWeight: FontWeight.w800,
                                                color: darkText,
                                                height: 1.6,
                                              ),
                                              h3: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: primaryPurple,
                                                height: 1.6,
                                              ),
                                              strong: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: darkText,
                                              ),
                                              listBullet: const TextStyle(
                                                color: primaryPurple,
                                                fontSize: 15,
                                              ),
                                              blockquoteDecoration:
                                                  BoxDecoration(
                                                    color: const Color(
                                                      0xFFF5F2FF,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: const Border(
                                                      left: BorderSide(
                                                        color: primaryPurple,
                                                        width: 4,
                                                      ),
                                                    ),
                                                  ),
                                              blockquotePadding:
                                                  const EdgeInsets.all(16),
                                              blockquote: const TextStyle(
                                                fontSize: 14,
                                                height: 1.6,
                                                color: Color(0xFF475569),
                                              ),
                                              code: const TextStyle(
                                                color: Color(0xFFDB2777),
                                                backgroundColor: Color(
                                                  0xFFFDF2F8,
                                                ),
                                                fontFamily: 'monospace',
                                                fontSize: 13,
                                              ),
                                              codeblockDecoration:
                                                  BoxDecoration(
                                                    color: const Color(
                                                      0xFFF8FAFC,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFFE2E8F0,
                                                      ),
                                                    ),
                                                  ),
                                              horizontalRuleDecoration:
                                                  const BoxDecoration(
                                                    border: Border(
                                                      top: BorderSide(
                                                        color: Color(
                                                          0xFFEAE8F4,
                                                        ),
                                                        width: 1,
                                                      ),
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // FINISH BUTTON
                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: ElevatedButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryPurple,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.check_circle_outline,
                                              size: 19,
                                            ),
                                            SizedBox(width: 9),
                                            Text(
                                              'Selesai Membaca',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                  ],
                                );
                              },

                              // LOADING
                              loading: () => const GorgeousLoadingScreen(
                                title: 'Menyusun Analisis Performa',
                                customMessages: [
                                  'Menganalisis hasil jawaban Anda...',
                                  'Mengidentifikasi konsep & materi kunci...',
                                  'Menyusun pembahasan & petunjuk...',
                                  'Merakit rekomendasi strategi belajar...',
                                  'Hampir selesai, memformat analisis...',
                                ],
                                isScaffold: false,
                              ),

                              // ERROR
                              error: (error, stack) {
                                final rawMsg = error.toString().replaceAll(
                                  'Exception: ',
                                  '',
                                );

                                final isOffline =
                                    rawMsg.contains('[OFFLINE]') ||
                                    rawMsg.toLowerCase().contains(
                                      'tidak ada koneksi',
                                    ) ||
                                    rawMsg.toLowerCase().contains(
                                      'periksa jaringan',
                                    ) ||
                                    rawMsg.toLowerCase().contains(
                                      'jaringan terputus',
                                    );

                                final isQuota =
                                    !isOffline &&
                                    (rawMsg.contains('[QUOTA_EXCEEDED]') ||
                                        rawMsg.toLowerCase().contains(
                                          'rate limit',
                                        ) ||
                                        rawMsg.toLowerCase().contains('429') ||
                                        rawMsg.toLowerCase().contains('kuota'));

                                final displayMsg = rawMsg
                                    .replaceAll('[OFFLINE] ', '')
                                    .replaceAll('[QUOTA_EXCEEDED] ', '')
                                    .replaceAll('[SYSTEM_ERROR] ', '');

                                final accentColor = isOffline
                                    ? const Color(0xFFD97706)
                                    : isQuota
                                    ? primaryPurple
                                    : Colors.redAccent;

                                final titleText = isOffline
                                    ? 'Koneksi Internet Terputus'
                                    : isQuota
                                    ? 'Kuota Gemini AI Terlampaui'
                                    : 'Gagal Memuat Analisis';

                                final iconData = isOffline
                                    ? Icons.wifi_off_rounded
                                    : isQuota
                                    ? Icons.hourglass_top_rounded
                                    : Icons.error_outline_rounded;

                                return _errorState(
                                  title: titleText,
                                  message: displayMsg,
                                  color: accentColor,
                                  icon: iconData,
                                  onRetry: () {
                                    final session = ref
                                        .read(quizProvider)
                                        .value;

                                    if (session != null) {
                                      ref
                                          .read(studyGuideProvider.notifier)
                                          .generateGuide(session);
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book_rounded, size: 55, color: primaryPurple),
          const SizedBox(height: 15),
          const Text(
            'Belum Ada Panduan Belajar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Panduan belajar belum tersedia untuk sesi ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: mutedText),
          ),
        ],
      ),
    );
  }

  Widget _errorState({
    required String title,
    required String message,
    required Color color,
    required IconData icon,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFEAE8F4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 35, color: color),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: mutedText,
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
