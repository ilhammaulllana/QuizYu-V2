class QuizSettings {
  final String topic;
  final String modelVersion; // "Standard" atau "Pro"
  final int questionCount;
  final String difficulty; // "Mudah", "Sedang", "Sulit"
  final String focusArea; // "Semua topik" atau "Peluang perbaikan"

  const QuizSettings({
    this.topic = '',
    this.modelVersion = 'Standard',
    this.questionCount = 10,
    this.difficulty = 'Sedang',
    this.focusArea = 'Semua topik',
  });

  QuizSettings copyWith({
    String? topic,
    String? modelVersion,
    int? questionCount,
    String? difficulty,
    String? focusArea,
  }) {
    return QuizSettings(
      topic: topic ?? this.topic,
      modelVersion: modelVersion ?? this.modelVersion,
      questionCount: questionCount ?? this.questionCount,
      difficulty: difficulty ?? this.difficulty,
      focusArea: focusArea ?? this.focusArea,
    );
  }
}
