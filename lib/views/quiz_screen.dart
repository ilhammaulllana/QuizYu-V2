import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quiz_notifier.dart';

class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key});

  // ============================================================
  // EXIT CONFIRMATION
  // ============================================================
  void _showExitConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF8906)),
            SizedBox(width: 12),
            Text(
              'Keluar Kuis?',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari sesi kuis ini? '
          'Semua progres pengerjaan saat ini akan hilang.',
          style: TextStyle(color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(quizProvider.notifier).resetQuiz();
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizState = ref.watch(quizProvider);
    final theme = Theme.of(context);

    final session = quizState.value;

    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentQuestion = session.currentQuestion;

    if (currentQuestion == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final int questionIdx = session.currentIndex;
    final int totalQuestions = session.totalQuestions;

    final double progress = totalQuestions > 0
        ? (questionIdx + 1) / totalQuestions
        : 0;

    final bool isAnswered = session.selectedAnswers.containsKey(questionIdx);

    final selectedAnswerIndex = session.selectedAnswers[questionIdx];

    // ============================================================
    // RESPONSIVE BREAKPOINT
    // ============================================================
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;

        final bool isMobile = screenWidth < 600;
        final bool isTablet = screenWidth >= 600 && screenWidth < 1024;
        final bool isDesktop = screenWidth >= 1024;

        // Lebar maksimal area quiz di desktop.
        final double contentMaxWidth = isDesktop
            ? 900
            : isTablet
            ? 760
            : double.infinity;

        final double horizontalPadding = isMobile
            ? 16
            : isTablet
            ? 24
            : 32;

        final double verticalPadding = isMobile ? 16 : 24;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),

          // ======================================================
          // APP BAR
          // ======================================================
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(isMobile ? 70 : 78),
            child: Container(
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 16 : 32,
                            ),
                            child: Row(
                              children: [
                                // Tombol keluar
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 40,
                                  ),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Color(0xFF0F172A),
                                  ),
                                  onPressed: () =>
                                      _showExitConfirmation(context, ref),
                                ),

                                SizedBox(width: isMobile ? 8 : 12),

                                // Info quiz
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        session.topic,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: isMobile ? 13 : 14,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF7F5AF0),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Soal ${questionIdx + 1} dari $totalQuestions',
                                        style: TextStyle(
                                          fontSize: isMobile ? 11 : 12,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Progress bar mengikuti lebar content
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 32,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 5,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),

          // ======================================================
          // BODY
          // ======================================================
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentMaxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ======================================
                          // QUESTION CARD
                          // ======================================
                          Container(
                            padding: EdgeInsets.all(isMobile ? 18 : 24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                isMobile ? 16 : 20,
                              ),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              currentQuestion.question,
                              style: TextStyle(
                                fontSize: isMobile ? 17 : 19,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                                height: 1.5,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),

                          SizedBox(height: isMobile ? 14 : 18),

                          // ======================================
                          // HINT
                          // ======================================
                          HintAccordion(hintText: currentQuestion.hint),

                          SizedBox(height: isMobile ? 20 : 28),

                          // ======================================
                          // ANSWER OPTIONS
                          // ======================================
                          ...List.generate(currentQuestion.options.length, (
                            index,
                          ) {
                            final optionText = currentQuestion.options[index];

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: isMobile ? 10 : 12,
                              ),
                              child: _buildOptionCard(
                                context: context,
                                ref: ref,
                                index: index,
                                optionText: optionText,
                                correctIndex:
                                    currentQuestion.correctAnswerIndex,
                                isAnswered: isAnswered,
                                isSelected: selectedAnswerIndex == index,
                                isMobile: isMobile,
                              ),
                            );
                          }),

                          // ======================================
                          // EXPLANATION
                          // ======================================
                          if (isAnswered) ...[
                            SizedBox(height: isMobile ? 8 : 12),
                            AnimatedOpacity(
                              opacity: 1.0,
                              duration: const Duration(milliseconds: 350),
                              child: Container(
                                padding: EdgeInsets.all(isMobile ? 16 : 20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFBBF7D0),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.lightbulb_outline_rounded,
                                          color: theme.colorScheme.secondary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Penjelasan Gemini',
                                          style: TextStyle(
                                            fontSize: isMobile ? 14 : 15,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      currentQuestion.explanation,
                                      style: TextStyle(
                                        fontSize: isMobile ? 13 : 14,
                                        color: const Color(0xFF1E293B),
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          // Extra space before bottom bar.
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ==================================================
              // BOTTOM CONTROL BAR
              // ==================================================
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: isMobile ? 12 : 16,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentMaxWidth),
                      child: SizedBox(
                        width: double.infinity,
                        child: _buildBottomButton(
                          context: context,
                          ref: ref,
                          isAnswered: isAnswered,
                          questionIdx: questionIdx,
                          totalQuestions: totalQuestions,
                          isMobile: isMobile,
                          theme: theme,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // BOTTOM BUTTON
  // ============================================================
  Widget _buildBottomButton({
    required BuildContext context,
    required WidgetRef ref,
    required bool isAnswered,
    required int questionIdx,
    required int totalQuestions,
    required bool isMobile,
    required ThemeData theme,
  }) {
    if (isAnswered) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        onPressed: () {
          ref.read(quizProvider.notifier).nextQuestion();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              questionIdx == totalQuestions - 1
                  ? 'Lihat Hasil'
                  : 'Soal Berikutnya',
              style: TextStyle(
                fontSize: isMobile ? 15 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              questionIdx == totalQuestions - 1
                  ? Icons.analytics_rounded
                  : Icons.arrow_forward_rounded,
              size: 18,
            ),
          ],
        ),
      );
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: () {
        ref.read(quizProvider.notifier).skipQuestion();
        ref.read(quizProvider.notifier).nextQuestion();
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Lewati Soal',
            style: TextStyle(
              fontSize: isMobile ? 15 : 16,
              color: const Color(0xFF475569),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.skip_next_rounded,
            color: Color(0xFF475569),
            size: 18,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ANSWER OPTION CARD
  // ============================================================
  Widget _buildOptionCard({
    required BuildContext context,
    required WidgetRef ref,
    required int index,
    required String optionText,
    required int correctIndex,
    required bool isAnswered,
    required bool isSelected,
    required bool isMobile,
  }) {
    final theme = Theme.of(context);

    final letter = String.fromCharCode(65 + index);

    Color cardBgColor = Colors.white;
    Color borderColor = const Color(0xFFE2E8F0);
    Color letterBgColor = const Color(0xFFF1F5F9);
    Color letterTextColor = const Color(0xFF64748B);

    Widget suffixIcon = const SizedBox.shrink();

    // ==========================================================
    // ANSWER STATE
    // ==========================================================
    if (isAnswered) {
      if (index == correctIndex) {
        cardBgColor = const Color(0xFFECFDF5);
        borderColor = const Color(0xFF10B981);
        letterBgColor = const Color(0xFF10B981);
        letterTextColor = Colors.white;

        suffixIcon = const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF10B981),
        );
      } else if (isSelected) {
        cardBgColor = const Color(0xFFFEF2F2);
        borderColor = const Color(0xFFEF4444);
        letterBgColor = const Color(0xFFEF4444);
        letterTextColor = Colors.white;

        suffixIcon = const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444));
      }
    } else if (isSelected) {
      borderColor = theme.primaryColor;
    }

    // ==========================================================
    // OPTION CARD
    // ==========================================================
    return GestureDetector(
      onTap: isAnswered
          ? null
          : () {
              ref.read(quizProvider.notifier).answerQuestion(index);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 18,
          vertical: isMobile ? 13 : 15,
        ),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ==================================================
            // LETTER
            // ==================================================
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isMobile ? 32 : 36,
              height: isMobile ? 32 : 36,
              decoration: BoxDecoration(
                color: letterBgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: letterTextColor,
                    fontSize: isMobile ? 13 : 14,
                  ),
                ),
              ),
            ),

            SizedBox(width: isMobile ? 12 : 16),

            // ==================================================
            // OPTION TEXT
            // ==================================================
            Expanded(
              child: Text(
                optionText,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isAnswered && index != correctIndex && !isSelected
                      ? const Color(0xFF94A1B2)
                      : const Color(0xFF1E293B),
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // ==================================================
            // STATUS ICON
            // ==================================================
            suffixIcon,
          ],
        ),
      ),
    );
  }
}

// ===============================================================
// HINT ACCORDION
// ===============================================================
class HintAccordion extends StatefulWidget {
  final String hintText;

  const HintAccordion({super.key, required this.hintText});

  @override
  State<HintAccordion> createState() => _HintAccordionState();
}

class _HintAccordionState extends State<HintAccordion>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isExpanded
              ? theme.primaryColor.withValues(alpha: 0.4)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // ====================================================
            // HINT HEADER
            // ====================================================
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      size: 18,
                      color: _isExpanded
                          ? theme.primaryColor
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Tampilkan Petunjuk',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: _isExpanded
                            ? theme.primaryColor
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ====================================================
            // HINT CONTENT
            // ====================================================
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.hintText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }
}
