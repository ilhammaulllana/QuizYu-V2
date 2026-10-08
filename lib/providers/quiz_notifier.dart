import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz_question.dart';
import '../models/quiz_session.dart';
import '../models/quiz_settings.dart';
import '../services/api_service.dart';
import '../services/mock_data.dart';

class QuizNotifier extends StateNotifier<AsyncValue<QuizSession?>> {
  QuizNotifier() : super(const AsyncValue.data(null));

  /// Starts a new quiz session for the given topic, count, and difficulty.
  Future<void> startQuiz({
    required String topic,
    required int count,
    required String difficulty,
    String modelVersion = 'Standard',
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await ApiService().generateQuiz(
        topic: topic,
        count: count,
        difficulty: difficulty,
        modelVersion: modelVersion,
      );

      if (result['is_valid'] == false) {
        final errorMsg = result['error_message'] ?? 'Gagal membuat kuis.';
        state = AsyncValue.error(errorMsg, StackTrace.current);
        return;
      }

      final List<dynamic> questionsJson = result['questions'] ?? [];
      final questions = questionsJson.asMap().entries.map((entry) {
        final idx = entry.key;
        final json = entry.value;
        return QuizQuestion.fromJson(json, 'q_$idx');
      }).toList();

      final session = QuizSession(
        questions: questions,
        topic: result['topic'] ?? topic,
      );

      state = AsyncValue.data(session);
    } catch (e, stack) {
      // Fallback lokal jika backend tidak dapat dihubungi atau mengalami kendala
      try {
        final mockResult = await MockDataService.generateQuiz(
          topic: topic,
          count: count,
          difficulty: difficulty,
        );
        if (mockResult['is_valid'] == false) {
          state = AsyncValue.error(mockResult['error_message'] ?? 'Topik tidak valid.', stack);
          return;
        }
        final List<dynamic> questionsJson = mockResult['questions'] ?? [];
        final questions = questionsJson.asMap().entries.map((entry) {
          final idx = entry.key;
          final json = entry.value;
          return QuizQuestion.fromJson(json, 'q_mock_$idx');
        }).toList();

        final session = QuizSession(
          questions: questions,
          topic: mockResult['topic'] ?? topic,
        );

        state = AsyncValue.data(session);
        return;
      } catch (_) {}

      state = AsyncValue.error('Terjadi kesalahan sistem: $e', stack);
    }
  }

  /// Records the user's selected answer for the current question.
  void answerQuestion(int optionIndex) {
    final currentSession = state.value;
    if (currentSession == null || currentSession.isCompleted) return;

    final updatedAnswers = Map<int, int>.from(currentSession.selectedAnswers);
    updatedAnswers[currentSession.currentIndex] = optionIndex;

    state = AsyncValue.data(currentSession.copyWith(
      selectedAnswers: updatedAnswers,
    ));
  }

  /// Skips the current question (leaves it unanswered).
  void skipQuestion() {
    final currentSession = state.value;
    if (currentSession == null || currentSession.isCompleted) return;

    // Skipping doesn't add an entry to selectedAnswers, or we could explicitly remove it
    final updatedAnswers = Map<int, int>.from(currentSession.selectedAnswers);
    updatedAnswers.remove(currentSession.currentIndex);

    state = AsyncValue.data(currentSession.copyWith(
      selectedAnswers: updatedAnswers,
    ));
  }

  /// Navigates to the next question or completes the quiz if it was the last question.
  void nextQuestion() {
    final currentSession = state.value;
    if (currentSession == null || currentSession.isCompleted) return;

    if (currentSession.currentIndex < currentSession.totalQuestions - 1) {
      state = AsyncValue.data(currentSession.copyWith(
        currentIndex: currentSession.currentIndex + 1,
      ));
    } else {
      state = AsyncValue.data(currentSession.copyWith(
        isCompleted: true,
      ));
    }
  }

  /// Navigates to the previous question.
  void previousQuestion() {
    final currentSession = state.value;
    if (currentSession == null || currentSession.isCompleted) return;

    if (currentSession.currentIndex > 0) {
      state = AsyncValue.data(currentSession.copyWith(
        currentIndex: currentSession.currentIndex - 1,
      ));
    }
  }

  /// Generates a new quiz session based on user settings (and includes previous mistakes if focused).
  Future<void> startCustomQuiz(QuizSettings settings) async {
    final prevSession = state.value;
    
    // Check if we need to focus on weak topics / improvement
    if (settings.focusArea == 'Peluang perbaikan' && prevSession != null) {
      // Find incorrect questions
      final incorrect = prevSession.questions.where((q) {
        final ans = prevSession.selectedAnswers[prevSession.questions.indexOf(q)];
        return ans != q.correctAnswerIndex;
      }).toList();

      if (incorrect.isNotEmpty) {
        state = const AsyncValue.loading();
        // Simulate loading
        await Future.delayed(const Duration(seconds: 2));

        // Generate questions centered on those failed concepts
        List<QuizQuestion> newQuestions = [];
        
        // Let's re-add the incorrect ones but shuffle them or tweak slightly,
        // and pad with brand new questions on the same topic.
        final topic = prevSession.topic;
        List<dynamic> rawQuestions = [];
        try {
          final res = await ApiService().generateQuiz(
            topic: topic,
            count: settings.questionCount,
            difficulty: settings.difficulty,
            modelVersion: settings.modelVersion,
          );

          if (res['is_valid'] == false) {
            state = AsyncValue.error(res['error_message'] ?? 'Gagal membuat kuis.', StackTrace.current);
            return;
          }
          rawQuestions = res['questions'] ?? [];
        } catch (_) {
          final mockRes = await MockDataService.generateQuiz(
            topic: topic,
            count: settings.questionCount,
            difficulty: settings.difficulty,
          );
          rawQuestions = mockRes['questions'] ?? [];
        }

        final fetchedQuestions = rawQuestions.asMap().entries.map((entry) {
          return QuizQuestion.fromJson(entry.value, 'q_custom_${entry.key}');
        }).toList();

        // Mix incorrect and some new ones
        newQuestions.addAll(incorrect.map((q) => QuizQuestion(
          id: 'q_retry_${q.id}',
          question: '[RETRY] ${q.question}',
          options: q.options,
          correctAnswerIndex: q.correctAnswerIndex,
          hint: q.hint,
          explanation: 'Latihan ulang: ${q.explanation}',
        )));

        // Pad with new ones until we hit the requested count
        for (var q in fetchedQuestions) {
          if (newQuestions.length >= settings.questionCount) break;
          // Avoid duplicate text questions if possible
          if (!newQuestions.any((element) => element.question.contains(q.question))) {
            newQuestions.add(q);
          }
        }

        // Shuffle questions so it feels fresh
        newQuestions.shuffle();

        state = AsyncValue.data(QuizSession(
          questions: newQuestions,
          topic: '$topic (Fokus Perbaikan)',
        ));
        return;
      }
    }

    // Default: Start a fresh normal quiz
    await startQuiz(
      topic: settings.topic.isNotEmpty ? settings.topic : (prevSession?.topic ?? 'Umum'),
      count: settings.questionCount,
      difficulty: settings.difficulty,
      modelVersion: settings.modelVersion,
    );
  }

  /// Resets the quiz session to null (returns to the Zero-State home screen).
  void resetQuiz() {
    state = const AsyncValue.data(null);
  }
}

final quizProvider = StateNotifierProvider<QuizNotifier, AsyncValue<QuizSession?>>((ref) {
  return QuizNotifier();
});
