import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/quiz_notifier.dart';
import '../../providers/settings_notifier.dart';

class QuizSettingsSheet extends ConsumerStatefulWidget {
  const QuizSettingsSheet({super.key});

  @override
  ConsumerState<QuizSettingsSheet> createState() => _QuizSettingsSheetState();
}

class _QuizSettingsSheetState extends ConsumerState<QuizSettingsSheet> {
  late String _focusArea;
  late int _questionCount;
  late String _difficulty;
  bool _isCustom = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _focusArea = settings.focusArea;
    _questionCount = settings.questionCount;
    _difficulty = settings.difficulty;
    _isCustom = _questionCount != 5 && _questionCount != 10 && _questionCount != 20;
  }

  void _submit() {
    // 1. Perbarui settings provider
    ref.read(settingsProvider.notifier).setFocusArea(_focusArea);
    ref.read(settingsProvider.notifier).setQuestionCount(_questionCount);
    ref.read(settingsProvider.notifier).setDifficulty(_difficulty);

    // 2. Ambil pengaturan yang telah diperbarui
    final updatedSettings = ref.read(settingsProvider);

    // 3. Picu pembuatan kuis lanjutan
    ref.read(quizProvider.notifier).startCustomQuiz(updatedSettings);

    // 4. Tutup lembar bawah (bottom sheet)
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white, // Lembar putih bersih
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Indikator pegangan seret
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Pengaturan Kuis Lanjutan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Bagian 1: Fokus Soal
            const Text(
              '🎯 Fokus Soal',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildSelectorTile(
                    label: 'Semua Topik',
                    subtitle: 'Set soal baru acak',
                    isSelected: _focusArea == 'Semua topik',
                    onTap: () => setState(() => _focusArea = 'Semua topik'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSelectorTile(
                    label: 'Peluang Perbaikan',
                    subtitle: 'Ulangi soal yang salah',
                    isSelected: _focusArea == 'Peluang perbaikan',
                    onTap: () => setState(() => _focusArea = 'Peluang perbaikan'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bagian 2: Jumlah Soal
            const Text(
              '🔢 Jumlah Soal',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
            Row(
              children: [
                ...[5, 10, 20].map((count) {
                  final isSelected = !_isCustom && _questionCount == count;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _questionCount = count;
                            _isCustom = false;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected ? theme.primaryColor : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? theme.primaryColor : const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: theme.primaryColor.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isCustom = true;
                          if (_questionCount == 5 || _questionCount == 10 || _questionCount == 20) {
                            _questionCount = 15; // Setel nilai kustom bawaan menjadi 15
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 48,
                        decoration: BoxDecoration(
                          color: _isCustom ? theme.primaryColor : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isCustom ? theme.primaryColor : const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                          boxShadow: _isCustom
                              ? [
                                  BoxShadow(
                                    color: theme.primaryColor.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Custom',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _isCustom ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_isCustom) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: theme.primaryColor,
                        inactiveTrackColor: const Color(0xFFEBF5FF),
                        thumbColor: theme.primaryColor,
                        overlayColor: theme.primaryColor.withValues(alpha: 0.12),
                        valueIndicatorColor: theme.primaryColor,
                        valueIndicatorTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Slider(
                        value: _questionCount.clamp(3, 30).toDouble(),
                        min: 3,
                        max: 30,
                        divisions: 27,
                        label: '$_questionCount Soal',
                        onChanged: (val) {
                          setState(() {
                            _questionCount = val.round();
                          });
                        },
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.primaryColor, width: 1.5),
                    ),
                    child: Text(
                      '$_questionCount',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),

            // Bagian 3: Tingkat Kesulitan
            const Text(
              '⚡ Tingkat Kesulitan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: ['Mudah', 'Sedang', 'Sulit'].map((level) {
                final isSelected = _difficulty == level;
                Color levelColor = theme.primaryColor;
                if (level == 'Mudah') levelColor = theme.colorScheme.secondary;
                if (level == 'Sulit') levelColor = theme.colorScheme.error;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: GestureDetector(
                      onTap: () => setState(() => _difficulty = level),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? levelColor : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? levelColor : const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: levelColor.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            level,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 36),

            // Tombol Kirim / Mulai
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7F5AF0), Color(0xFF9061F9)],
                ),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _submit,
                child: const Text(
                  'Mulai Kuis Lanjutan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorTile({
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.primaryColor : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? theme.primaryColor : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? theme.primaryColor.withValues(alpha: 0.8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
