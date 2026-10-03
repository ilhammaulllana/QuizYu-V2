import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quiz_notifier.dart';
import '../providers/settings_notifier.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitQuery(String query) {
    if (query.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Harap masukkan topik kuis terlebih dahulu!'),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final settings = ref.read(settingsProvider);

    int count = settings.questionCount;

    final numMatch1 = RegExp(
      r'(\d+)\s*(?:soal|pertanyaan|items?|buah)',
      caseSensitive: false,
    ).firstMatch(query);

    final numMatch2 = RegExp(
      r'(?:soal|pertanyaan|items?|buah)\s+.*?\s*(\d+)',
      caseSensitive: false,
    ).firstMatch(query);

    final numMatch3 = RegExp(r'\b(\d+)\b').firstMatch(query);

    final String? foundNum =
        numMatch1?.group(1) ?? numMatch2?.group(1) ?? numMatch3?.group(1);

    if (foundNum != null) {
      final parsed = int.tryParse(foundNum);
      if (parsed != null && parsed >= 1 && parsed <= 30) {
        count = parsed;
      }
    }

    ref.read(quizProvider.notifier).startQuiz(
      topic: query,
      count: count,
      difficulty: settings.difficulty,
      modelVersion: settings.modelVersion,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Breakpoints
    final bool isDesktop = screenWidth >= 1024;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1024;
    final bool isMobile = screenWidth < 600;

    // Responsive values
    final double horizontalPadding = isDesktop ? 0 : (isTablet ? 48.0 : 24.0);
    final double maxContentWidth = isDesktop ? 560.0 : (isTablet ? 560.0 : double.infinity);
    final double titleFontSize = isDesktop ? 40.0 : (isTablet ? 34.0 : 28.0);
    final double subtitleFontSize = isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0);
    final double logoSize = isDesktop ? 48.0 : (isTablet ? 40.0 : 32.0);
    final double logoIconSize = isDesktop ? 28.0 : (isTablet ? 24.0 : 18.0);
    final double logoTextSize = isDesktop ? 28.0 : (isTablet ? 24.0 : 20.0);

    // Listen for error changes in quizState and show snackbar
    ref.listen<AsyncValue>(quizProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          final rawMsg = error.toString().replaceAll('Exception: ', '');

          final isOffline =
              rawMsg.contains('[OFFLINE]') ||
              rawMsg.toLowerCase().contains('tidak ada koneksi') ||
              rawMsg.toLowerCase().contains('periksa jaringan') ||
              rawMsg.toLowerCase().contains('jaringan terputus');

          final isQuota =
              !isOffline &&
              (rawMsg.contains('[QUOTA_EXCEEDED]') ||
                  rawMsg.toLowerCase().contains('rate limit') ||
                  rawMsg.toLowerCase().contains('429') ||
                  rawMsg.toLowerCase().contains('kuota'));

          final displayMsg = rawMsg
              .replaceAll('[OFFLINE] ', '')
              .replaceAll('[QUOTA_EXCEEDED] ', '')
              .replaceAll('[SYSTEM_ERROR] ', '');

          if (isOffline) {
            debugPrint('🌐 [LOG TIDAK ADA KONEKSI INTERNET] $displayMsg');
          } else if (isQuota) {
            debugPrint('⏳ [LOG BATAS KUOTA AI GEMINI TERLAMPAUI] $displayMsg');
          } else {
            debugPrint('❌ [LOG KESALAHAN SISTEM] $displayMsg');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    isOffline
                        ? Icons.wifi_off_rounded
                        : isQuota
                        ? Icons.hourglass_top_rounded
                        : Icons.error_outline_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      displayMsg,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: isOffline
                  ? const Color(0xFFD97706)
                  : isQuota
                  ? const Color(0xFF7F5AF0)
                  : theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              action: SnackBarAction(
                label: 'Coba Lagi',
                textColor: Colors.white,
                onPressed: () => _focusNode.requestFocus(),
              ),
            ),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [Color(0xFFEEF2FF), Colors.white],
            stops: [0.0, 0.7],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      // ===============================================
                      // TOP NAV BAR
                      // ===============================================
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 48.0 : horizontalPadding,
                          vertical: 16.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // ---- LOGO (kiri) ----
                            Row(
                              children: [
                                Container(
                                  width: logoSize,
                                  height: logoSize,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.auto_stories_rounded,
                                    color: Colors.white,
                                    size: logoIconSize,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                                  ).createShader(bounds),
                                  child: Text(
                                    'quizyu',
                                    style: TextStyle(
                                      fontSize: logoTextSize,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // ---- NAV ITEMS (kanan, hanya desktop/tablet) ----
                            if (!isMobile)
                              Row(
                                children: [
                                  _buildNavChip(
                                    icon: Icons.flash_on_rounded,
                                    label: 'Kuis AI',
                                    color: const Color(0xFF7C3AED),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildNavChip(
                                    icon: Icons.bar_chart_rounded,
                                    label: 'Analisis',
                                    color: const Color(0xFF6366F1),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),

                      // ===============================================
                      // HERO CONTENT (Centered, Constrained Width)
                      // ===============================================
                      Padding(
                        padding: EdgeInsets.only(
                          left: isDesktop ? 0 : horizontalPadding,
                          right: isDesktop ? 0 : horizontalPadding,
                          top: isDesktop ? 80 : (isTablet ? 60 : 40),
                          bottom: 32,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxContentWidth),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // ---- BADGE ----
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.psychology_rounded,
                                        size: 14,
                                        color: Color(0xFF7C3AED),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Powered by Google Gemini AI',
                                        style: TextStyle(
                                          fontSize: isMobile ? 11 : 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF7C3AED),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: isDesktop ? 28 : 20),

                                // ---- JUDUL UTAMA ----
                                Text(
                                  'Belajar Apa Hari Ini?',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: -1.0,
                                    height: 1.15,
                                  ),
                                ),

                                SizedBox(height: isDesktop ? 16 : 12),

                                // ---- SUBTITLE ----
                                Text(
                                  'Ketik topik apa saja, Gemini AI akan membuatkan\nkuis interaktif dan panduan belajar khusus untuk kamu.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: subtitleFontSize,
                                    color: const Color(0xFF64748B),
                                    height: 1.6,
                                  ),
                                ),

                                SizedBox(height: isDesktop ? 48 : 36),

                                // ---- SEARCH BAR ----
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    focusNode: _focusNode,
                                    onSubmitted: _submitQuery,
                                    textInputAction: TextInputAction.search,
                                    style: TextStyle(
                                      fontSize: isMobile ? 15 : 16,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Misal: "Tata Surya 10 soal", "Logika Dasar"...',
                                      hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
                                      fillColor: Colors.white,
                                      filled: true,
                                      prefixIcon: const Padding(
                                        padding: EdgeInsets.only(left: 16, right: 8),
                                        child: Icon(
                                          Icons.search_rounded,
                                          color: Color(0xFF7C3AED),
                                          size: 22,
                                        ),
                                      ),
                                      prefixIconConstraints: const BoxConstraints(minWidth: 48),
                                      suffixIcon: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: GestureDetector(
                                          onTap: () => _submitQuery(_searchController.text),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
                                                SizedBox(width: 6),
                                                Text(
                                                  'Buat Kuis',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        borderSide: const BorderSide(color: Color(0xFFE8E8F0), width: 1.5),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // ---- MODEL SWITCHER ----
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FF),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildModelPill(
                                        label: 'Gemini Standard',
                                        isSelected: settings.modelVersion == 'Standard',
                                        icon: Icons.flash_on_rounded,
                                        activeColor: const Color(0xFF6366F1),
                                        onTap: () {
                                          ref.read(settingsProvider.notifier).setModelVersion('Standard');
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      _buildModelPill(
                                        label: 'Gemini Pro',
                                        isSelected: settings.modelVersion == 'Pro',
                                        icon: Icons.stars_rounded,
                                        activeColor: const Color(0xFF7C3AED),
                                        onTap: () {
                                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Row(
                                                children: [
                                                  Icon(Icons.stars_rounded, color: Colors.white),
                                                  SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      'Fitur Gemini Pro belum tersedia saat ini.',
                                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: const Color(0xFF7C3AED),
                                              behavior: SnackBarBehavior.floating,
                                              duration: const Duration(seconds: 3),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              margin: const EdgeInsets.all(16),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: isDesktop ? 64 : 48),

                                // ---- QUICK TOPIC CHIPS ----
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildTopicChip('🧮 Matematika Dasar'),
                                    _buildTopicChip('🌍 Tata Surya'),
                                    _buildTopicChip('💻 Logika Pemrograman'),
                                    _buildTopicChip('📖 Sejarah Indonesia'),
                                    _buildTopicChip('⚗️ Kimia SMA'),
                                    _buildTopicChip('🧬 Biologi Sel'),
                                  ],
                                ),

                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ---- TOPIC CHIP ----
  Widget _buildTopicChip(String label) {
    return GestureDetector(
      onTap: () {
        final cleanLabel = label.replaceAll(RegExp(r'^\S+\s'), '');
        _searchController.text = cleanLabel;
        _submitQuery(cleanLabel);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  // ---- NAV CHIP ----
  Widget _buildNavChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ---- MODEL PILL ----
  Widget _buildModelPill({
    required String label,
    required bool isSelected,
    required IconData icon,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
