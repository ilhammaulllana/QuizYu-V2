import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/quiz_notifier.dart';
import '../providers/study_guide_notifier.dart';
import 'widgets/quiz_settings_sheet.dart';
import 'study_guide_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizState = ref.watch(quizProvider);

    final session = quizState.value;

    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final accuracy = session.accuracy;
    final correctCount = session.correctCount;
    final incorrectCount = session.incorrectCount;
    final skippedCount = session.skippedCount;
    final totalQuestions = session.totalQuestions;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // ============================================================
            // RESPONSIVE WIDTH
            // ============================================================

            final screenWidth = constraints.maxWidth;

            final isMobile = screenWidth < 600;
            final isTablet = screenWidth >= 600 && screenWidth < 1000;

            // Maximum width content pada desktop.
            // Jadi konten tidak terlalu melebar ketika dibuka di Chrome.
            final contentMaxWidth = isMobile
                ? double.infinity
                : isTablet
                ? 760.0
                : 920.0;

            final horizontalPadding = isMobile ? 20.0 : 32.0;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: isMobile ? 24 : 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ==================================================
                      // HEADER
                      // ==================================================
                      _buildHeader(session.topic, isMobile: isMobile),

                      SizedBox(height: isMobile ? 28 : 36),

                      // ==================================================
                      // ACCURACY CARD
                      // ==================================================
                      _buildAccuracyCard(
                        context: context,
                        accuracy: accuracy,
                        correctCount: correctCount,
                        totalQuestions: totalQuestions,
                        isMobile: isMobile,
                      ),

                      SizedBox(height: isMobile ? 16 : 20),

                      // ==================================================
                      // STATISTICS
                      // ==================================================
                      _buildStatistics(
                        context: context,
                        correctCount: correctCount,
                        incorrectCount: incorrectCount,
                        skippedCount: skippedCount,
                        isMobile: isMobile,
                      ),

                      SizedBox(height: isMobile ? 32 : 40),

                      // ==================================================
                      // PRIMARY ACTION
                      // ==================================================
                      _buildPrimaryButton(
                        context: context,
                        ref: ref,
                        session: session,
                        isMobile: isMobile,
                      ),

                      const SizedBox(height: 12),

                      // ==================================================
                      // SECONDARY ACTION
                      // ==================================================
                      _buildSecondaryButton(
                        context: context,
                        isMobile: isMobile,
                      ),

                      SizedBox(height: isMobile ? 20 : 28),

                      // ==================================================
                      // BACK TO HOME
                      // ==================================================
                      _buildHomeButton(context: context, ref: ref),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // =========================================================================
  // HEADER
  // =========================================================================

  Widget _buildHeader(String topic, {required bool isMobile}) {
    return Column(
      children: [
        Text(
          'Kuis Selesai!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isMobile ? 26 : 30,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.7,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          topic,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isMobile ? 15 : 16,
            color: const Color(0xFF7F5AF0),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // ACCURACY CARD
  // =========================================================================

  Widget _buildAccuracyCard({
    required BuildContext context,
    required double accuracy,
    required int correctCount,
    required int totalQuestions,
    required bool isMobile,
  }) {
    final theme = Theme.of(context);

    final progressColor = accuracy >= 70
        ? theme.colorScheme.secondary
        : accuracy >= 40
        ? const Color(0xFFFF8906)
        : theme.colorScheme.error;

    final gaugeSize = isMobile ? 140.0 : 155.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 32,
        vertical: isMobile ? 24 : 32,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ================================================================
          // CIRCULAR PROGRESS
          // ================================================================
          SizedBox(
            width: gaugeSize,
            height: gaugeSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: gaugeSize,
                  height: gaugeSize,
                  child: CircularProgressIndicator(
                    value: (accuracy / 100).clamp(0.0, 1.0),
                    strokeWidth: isMobile ? 11 : 13,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${accuracy.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: isMobile ? 30 : 34,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -1,
                      ),
                    ),

                    const SizedBox(height: 2),

                    const Text(
                      'Akurasi',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // ================================================================
          // SCORE
          // ================================================================
          Text(
            'Skor Anda',
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            '$correctCount dari $totalQuestions benar',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 16 : 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // STATISTICS
  // =========================================================================

  Widget _buildStatistics({
    required BuildContext context,
    required int correctCount,
    required int incorrectCount,
    required int skippedCount,
    required bool isMobile,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Benar',
            count: correctCount,
            color: theme.colorScheme.secondary,
            icon: Icons.check_circle_outline_rounded,
            isMobile: isMobile,
          ),
        ),

        SizedBox(width: isMobile ? 8 : 12),

        Expanded(
          child: _buildStatCard(
            title: 'Salah',
            count: incorrectCount,
            color: theme.colorScheme.error,
            icon: Icons.highlight_off_rounded,
            isMobile: isMobile,
          ),
        ),

        SizedBox(width: isMobile ? 8 : 12),

        Expanded(
          child: _buildStatCard(
            title: 'Dilewati',
            count: skippedCount,
            color: const Color(0xFF64748B),
            icon: Icons.next_plan_outlined,
            isMobile: isMobile,
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // STAT CARD
  // =========================================================================

  Widget _buildStatCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 14 : 18,
        horizontal: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isMobile ? 20 : 22),

          const SizedBox(height: 7),

          Text(
            '$count',
            style: TextStyle(
              fontSize: isMobile ? 21 : 23,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isMobile ? 10 : 11,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // PRIMARY BUTTON
  // =========================================================================

  Widget _buildPrimaryButton({
    required BuildContext context,
    required WidgetRef ref,
    required dynamic session,
    required bool isMobile,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF7F5AF0), Color(0xFF9061F9)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7F5AF0).withValues(alpha: 0.20),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          elevation: 0,
          minimumSize: const Size(double.infinity, 58),
          padding: EdgeInsets.symmetric(vertical: isMobile ? 17 : 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () {
          ref.read(studyGuideProvider.notifier).generateGuide(session);

          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const StudyGuideScreen()),
          );
        },
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Analisis Performa Saya',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // SECONDARY BUTTON
  // =========================================================================

  Widget _buildSecondaryButton({
    required BuildContext context,
    required bool isMobile,
  }) {
    final theme = Theme.of(context);

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 58),
        side: BorderSide(
          color: theme.primaryColor.withValues(alpha: 0.35),
          width: 1.3,
        ),
        padding: EdgeInsets.symmetric(vertical: isMobile ? 17 : 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => const QuizSettingsSheet(),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.tune_rounded, size: 20, color: theme.primaryColor),

          const SizedBox(width: 10),

          Text(
            'Tambahkan Pertanyaan',
            style: TextStyle(
              fontSize: 15,
              color: theme.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // HOME BUTTON
  // =========================================================================

  Widget _buildHomeButton({
    required BuildContext context,
    required WidgetRef ref,
  }) {
    return Center(
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF64748B),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        onPressed: () {
          ref.read(quizProvider.notifier).resetQuiz();
        },
        icon: const Icon(Icons.home_rounded, size: 18),
        label: const Text(
          'Kembali ke Beranda',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
