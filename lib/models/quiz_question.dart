class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String hint;
  final String explanation;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.hint,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(
    Map<String, dynamic> json,
    String id, {
    bool shuffleOptions = true,
  }) {
    final rawOptions = List<String>.from(json['options'] ?? []);
    final rawCorrectIndex = (json['correct_answer_index'] as num?)?.toInt() ?? 0;

    if (rawOptions.length <= 1 || !shuffleOptions) {
      return QuizQuestion(
        id: id,
        question: json['question'] ?? '',
        options: rawOptions,
        correctAnswerIndex: rawCorrectIndex,
        hint: json['hint'] ?? '',
        explanation: json['explanation'] ?? '',
      );
    }

    final int safeIndex =
        (rawCorrectIndex >= 0 && rawCorrectIndex < rawOptions.length)
            ? rawCorrectIndex
            : 0;
    final String correctOptionText = rawOptions[safeIndex];

    // Acak urutan opsi agar tidak selalu menumpuk di opsi B atau posisi tertentu
    final shuffledOptions = List<String>.from(rawOptions)..shuffle();
    final newCorrectIndex = shuffledOptions.indexOf(correctOptionText);

    return QuizQuestion(
      id: id,
      question: json['question'] ?? '',
      options: shuffledOptions,
      correctAnswerIndex: newCorrectIndex != -1 ? newCorrectIndex : 0,
      hint: json['hint'] ?? '',
      explanation: json['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correct_answer_index': correctAnswerIndex,
      'hint': hint,
      'explanation': explanation,
    };
  }
}
