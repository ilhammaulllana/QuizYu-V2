import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz_question.dart';
import '../models/quiz_session.dart';
import '../models/quiz_settings.dart';
import '../services/api_service.dart';


class QuizNotifier extends StateNotifier<AsyncValue<QuizSession?>> {
  QuizNotifier() : super(const AsyncValue.data(null));

  /// Memulai sesi kuis baru berdasarkan topik, jumlah soal, dan tingkat kesulitan yang diberikan.
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
      // Tidak ada fallback lokal — langsung tampilkan pesan error ke pengguna
      final errMsg = e.toString().replaceAll('Exception: ', '');
      state = AsyncValue.error(errMsg, stack);
    }
  }

  /// Menyimpan jawaban yang dipilih pengguna untuk soal saat ini.
  void answerQuestion(int optionIndex) {
    final currentSession = state.value;
    if (currentSession == null || currentSession.isCompleted) return;

    final updatedAnswers = Map<int, int>.from(currentSession.selectedAnswers);
    updatedAnswers[currentSession.currentIndex] = optionIndex;

    state = AsyncValue.data(currentSession.copyWith(
      selectedAnswers: updatedAnswers,
    ));
  }

  /// Melewati soal saat ini (dibiarkan tidak terjawab).
  void skipQuestion() {
    final currentSession = state.value;
    if (currentSession == null || currentSession.isCompleted) return;

    // Melewati soal tidak menambahkan entri ke selectedAnswers, atau dihapus jika ada
    final updatedAnswers = Map<int, int>.from(currentSession.selectedAnswers);
    updatedAnswers.remove(currentSession.currentIndex);

    state = AsyncValue.data(currentSession.copyWith(
      selectedAnswers: updatedAnswers,
    ));
  }

  /// Berpindah ke soal berikutnya atau menyelesaikan kuis jika sudah di soal terakhir.
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

  /// Berpindah kembali ke soal sebelumnya.
  void previousQuestion() {
    final currentSession = state.value;
    if (currentSession == null || currentSession.isCompleted) return;

    if (currentSession.currentIndex > 0) {
      state = AsyncValue.data(currentSession.copyWith(
        currentIndex: currentSession.currentIndex - 1,
      ));
    }
  }

  /// Menghasilkan sesi kuis baru berdasarkan pengaturan pengguna (dan menyertakan kesalahan sebelumnya jika difokuskan).
  Future<void> startCustomQuiz(QuizSettings settings) async {
    final prevSession = state.value;
    
    // Periksa apakah perlu fokus pada topik lemah / perbaikan
    if (settings.focusArea == 'Peluang perbaikan' && prevSession != null) {
      // Temukan soal-soal yang salah dijawab
      final incorrect = prevSession.questions.where((q) {
        final ans = prevSession.selectedAnswers[prevSession.questions.indexOf(q)];
        return ans != q.correctAnswerIndex;
      }).toList();

      if (incorrect.isNotEmpty) {
        state = const AsyncValue.loading();
        // Simulasi jeda loading
        await Future.delayed(const Duration(seconds: 2));

        // Buat soal yang berpusat pada konsep-konsep yang salah
        List<QuizQuestion> newQuestions = [];
        
        // Tambahkan kembali soal yang salah dan padukan dengan soal baru pada topik yang sama
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
        } catch (e) {
            state = AsyncValue.error(
              e.toString().replaceAll('Exception: ', ''),
              StackTrace.current,
            );
            return;
        }

        final fetchedQuestions = rawQuestions.asMap().entries.map((entry) {
          return QuizQuestion.fromJson(entry.value, 'q_custom_${entry.key}');
        }).toList();

        // Gabungkan soal yang salah dan beberapa soal baru
        newQuestions.addAll(incorrect.map((q) => QuizQuestion(
          id: 'q_retry_${q.id}',
          question: '[RETRY] ${q.question}',
          options: q.options,
          correctAnswerIndex: q.correctAnswerIndex,
          hint: q.hint,
          explanation: 'Latihan ulang: ${q.explanation}',
        )));

        // Tambahkan soal baru hingga mencapai jumlah yang diminta
        for (var q in fetchedQuestions) {
          if (newQuestions.length >= settings.questionCount) break;
          // Hindari duplikasi pertanyaan jika memungkinkan
          if (!newQuestions.any((element) => element.question.contains(q.question))) {
            newQuestions.add(q);
          }
        }

        // Acak urutan soal agar terasa baru
        newQuestions.shuffle();

        state = AsyncValue.data(QuizSession(
          questions: newQuestions,
          topic: '$topic (Fokus Perbaikan)',
        ));
        return;
      }
    }

    // Default: Mulai sesi kuis standar baru
    await startQuiz(
      topic: settings.topic.isNotEmpty ? settings.topic : (prevSession?.topic ?? 'Umum'),
      count: settings.questionCount,
      difficulty: settings.difficulty,
      modelVersion: settings.modelVersion,
    );
  }

  /// Mereset sesi kuis menjadi null (kembali ke layar utama / Zero-State).
  void resetQuiz() {
    state = const AsyncValue.data(null);
  }
}

final quizProvider = StateNotifierProvider<QuizNotifier, AsyncValue<QuizSession?>>((ref) {
  return QuizNotifier();
});
