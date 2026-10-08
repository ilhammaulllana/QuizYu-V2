import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quiz_notifier.dart';

class GorgeousLoadingScreen extends ConsumerStatefulWidget {
  final String title;
  final List<String>? customMessages;
  final VoidCallback? onCancel;
  final bool isScaffold;

  const GorgeousLoadingScreen({
    super.key,
    this.title = 'Memproses Kuis AI',
    this.customMessages,
    this.onCancel,
    this.isScaffold = true,
  });

  @override
  ConsumerState<GorgeousLoadingScreen> createState() =>
      _GorgeousLoadingScreenState();
}

class _GorgeousLoadingScreenState extends ConsumerState<GorgeousLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _messageIndex = 0;
  bool _showCancelButton = false;
  late final List<String> _loadingMessages;
  late Timer _timer;
  late Timer _cancelTimer;

  @override
  void initState() {
    super.initState();
    _loadingMessages =
        widget.customMessages ??
        [
          'Membangun koneksi dengan Gemini...',
          'Menganalisis topik Anda...',
          'Merakit System Prompt kuis...',
          'Membuat set pertanyaan interaktif...',
          'Menyusun petunjuk & pembahasan...',
          'Hampir selesai, memformat jawaban...',
        ];

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _timer = Timer.periodic(const Duration(milliseconds: 1800), (timer) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _loadingMessages.length;
        });
      }
    });

    // Show cancel button if loading takes longer than 60 seconds (1 minute)
    _cancelTimer = Timer(const Duration(seconds: 60), () {
      if (mounted) {
        setState(() {
          _showCancelButton = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    _cancelTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Container(
      constraints: const BoxConstraints.expand(),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            Color(0xFFEBF5FF), // Subtle blue in the center
            Colors.white, // Pure white at the edges
          ],
          stops: [0.0, 0.8],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Outer rotating neon glow
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _controller.value * 2.0 * 3.14159,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          theme.primaryColor,
                          theme.colorScheme.secondary,
                          theme.primaryColor.withValues(alpha: 0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            // Glowing main loading text
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF7F5AF0), Color(0xFF9061F9)],
              ).createShader(bounds),
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Animated cycling message
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: animation.drive(
                    Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ),
                  ),
                  child: child,
                ),
              ),
              child: Text(
                _loadingMessages[_messageIndex],
                key: ValueKey<int>(_messageIndex),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B), // Muted slate gray text
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            // Small loading dot indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(
                      alpha: 0.3 + (index * 0.2),
                    ),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
            if (_showCancelButton) ...[
              const SizedBox(height: 48),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    widget.onCancel ??
                    () {
                      ref.read(quizProvider.notifier).resetQuiz();
                    },
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text(
                  'Batal & Kembali ke Beranda',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (!widget.isScaffold) {
      return content;
    }

    return Scaffold(backgroundColor: Colors.white, body: content);
  }
}
