import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz_session.dart';
import '../services/api_service.dart';


class StudyGuideNotifier extends StateNotifier<AsyncValue<String?>> {
  StudyGuideNotifier() : super(const AsyncValue.data(null));

  /// Membuat panduan belajar berdasarkan jawaban salah pada sesi kuis yang diberikan.
  Future<void> generateGuide(QuizSession session) async {
    state = const AsyncValue.loading();
    try {
      // Temukan soal-soal yang salah dijawab
      final incorrectQuestions = session.questions.where((q) {
        final index = session.questions.indexOf(q);
        final selectedAnswer = session.selectedAnswers[index];
        return selectedAnswer != q.correctAnswerIndex;
      }).toList();

      final incorrectQuestionsJson = incorrectQuestions.map((q) => q.toJson()).toList();

      final markdown = await ApiService().generateStudyGuide(
        topic: session.topic,
        incorrectQuestions: incorrectQuestionsJson,
      );

      state = AsyncValue.data(markdown);
    } catch (e, stack) {
      // Tidak ada fallback lokal — langsung tampilkan pesan error ke pengguna
      final errMsg = e.toString().replaceAll('Exception: ', '');
      state = AsyncValue.error('Gagal membuat panduan belajar: $errMsg', stack);
    }
  }

  /// Mereset status panduan belajar.
  void reset() {
    state = const AsyncValue.data(null);
  }
}

final studyGuideProvider = StateNotifierProvider<StudyGuideNotifier, AsyncValue<String?>>((ref) {
  return StudyGuideNotifier();
});
