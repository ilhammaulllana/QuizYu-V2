import 'quiz_question.dart';

class QuizSession {
  final List<QuizQuestion> questions;
  final int currentIndex;
  final Map<int, int> selectedAnswers; // pemetaan indeksSoal -> indeksOpsiDipilih
  final bool isCompleted;
  final String topic;

  const QuizSession({
    required this.questions,
    this.currentIndex = 0,
    this.selectedAnswers = const {},
    this.isCompleted = false,
    required this.topic,
  });

  QuizQuestion? get currentQuestion {
    if (questions.isEmpty || currentIndex >= questions.length || currentIndex < 0) {
      return null;
    }
    return questions[currentIndex];
  }

  int get totalQuestions => questions.length;

  int get correctCount {
    int count = 0;
    selectedAnswers.forEach((qIdx, ansIdx) {
      if (qIdx < questions.length && questions[qIdx].correctAnswerIndex == ansIdx) {
        count++;
      }
    });
    return count;
  }

  int get incorrectCount {
    int count = 0;
    selectedAnswers.forEach((qIdx, ansIdx) {
      if (qIdx < questions.length && questions[qIdx].correctAnswerIndex != ansIdx) {
        count++;
      }
    });
    return count;
  }

  int get skippedCount {
    // Jika kuis telah selesai, jumlah dilewati adalah total soal dikurangi soal yang dijawab
    return totalQuestions - selectedAnswers.length;
  }

  double get accuracy {
    if (totalQuestions == 0) return 0.0;
    return (correctCount / totalQuestions) * 100;
  }

  QuizSession copyWith({
    List<QuizQuestion>? questions,
    int? currentIndex,
    Map<int, int>? selectedAnswers,
    bool? isCompleted,
    String? topic,
  }) {
    return QuizSession(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      isCompleted: isCompleted ?? this.isCompleted,
      topic: topic ?? this.topic,
    );
  }
}
