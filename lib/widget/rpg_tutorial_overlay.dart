import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../services/audio_service.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';
import '../widget/theme_card.dart';

/// RPG Tutorial Overlay widget.
///
/// Renders as a full-screen overlay (transparent dimmer + floating dialog)
/// OR as an inline card (when [inline] is true) for use inside bottom sheets.
///
/// [accentColor] defaults to AppColors.primary but can
/// be overridden, e.g. to match a category color inside AddTaskSheet.
class RpgTutorialOverlay extends StatefulWidget {
  final List<String> steps;
  final VoidCallback onCompleted;
  final VoidCallback onSkipped;

  /// When true, renders as a compact inline card (no full-screen dimmer).
  /// Use this inside modals / bottom sheets.
  final bool inline;

  /// Accent color for borders, button, and step indicator.
  /// Defaults to app purple `AppColors.primary`.
  final Color? accentColor;

  const RpgTutorialOverlay({
    super.key,
    required this.steps,
    required this.onCompleted,
    required this.onSkipped,
    this.inline = false,
    this.accentColor,
  });

  @override
  State<RpgTutorialOverlay> createState() => _RpgTutorialOverlayState();
}

class _RpgTutorialOverlayState extends State<RpgTutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _fadeController;

  // ── Theme tokens ───────────────────────────────────────────────────────────
  static const Color _obsidian  = Color(0xFF0D0D1A); // background
  static Color get _cardColor => AppColors.cardBackground; // card
  static Color get _cardBorder=> AppColors.cardBorder; // subtle border
  static const Color _gold      = Color(0xFFD4AF37); // gold (accent text)

  Color get _accent => widget.accentColor ?? AppColors.primary;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  void _nextStep() {
    HapticFeedback.mediumImpact();
    // AudioService.playClick();
    if (_currentStep < widget.steps.length - 1) {
      _fadeController.reverse().then((_) {
        if (mounted) {
          setState(() => _currentStep++);
          _fadeController.forward();
        }
      });
    } else {
      widget.onCompleted();
    }
  }

  void _skipTutorial() {
    HapticFeedback.mediumImpact();
    // AudioService.playClick();
    widget.onSkipped();
  }

  // ── Markdown parser ────────────────────────────────────────────────────────
  /// Parses `**bold**` → gold-coloured bold TextSpan.
  List<TextSpan> _parseMarkdown(String text) {
    final List<TextSpan> spans = [];
    final RegExp regExp = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;
    for (final Match match in regExp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(
          color: _gold,
          fontWeight: FontWeight.bold,
        ),
      ));
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return spans;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();

    if (widget.inline) {
      return FadeTransition(
        opacity: _fadeController,
        child: _buildCard(bottomPad: 0, showDimmer: false),
      );
    }

    return Stack(
      children: [
        // Semi-transparent full-screen dimmer
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _fadeController,
            builder: (context, _) => Container(
              color: _obsidian.withValues(alpha: 0.72 * _fadeController.value),
            ),
          ),
        ),
        // Floating dialog anchored to bottom
        Align(
          alignment: Alignment.bottomCenter,
          child: FadeTransition(
            opacity: _fadeController,
            child: _buildCard(bottomPad: 96, showDimmer: true),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required double bottomPad, required bool showDimmer}) {
    final isLastStep = _currentStep == widget.steps.length - 1;
    final l = context.l;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad > 0 ? bottomPad : 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Main card ───────────────────────────────────────────────────
          // ── Main card menggunakan ThemeCard untuk mendukung tema komik ──
          ThemeCard(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
            backgroundColor: _cardColor,
            borderRadius: BorderRadius.circular(20),
            borderColor: _accent.withValues(alpha: 0.6),
            borderWidth: 1.5,
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.18),
                blurRadius: 16,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step content
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.nunito(
                      color: AppColors.textPrimary.withValues(alpha: 0.93),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.55,
                    ),
                    children: _parseMarkdown(widget.steps[_currentStep]),
                  ),
                ),
                SizedBox(height: 16),
                // Action row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Skip
                    TextButton(
                      onPressed: _skipTutorial,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l.tutorialSkip,
                        style: GoogleFonts.nunito(
                          color: AppColors.textHint,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        // Step indicator dots
                        _buildDots(),
                        const SizedBox(width: 12),
                        // Next / Mengerti
                        _buildNextButton(isLastStep, l),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── Wizard avatar (top-right, floating out of card) ─────────────
          Positioned(
            top: -44,
            right: 16,
            child: _buildAvatar(),
          ),
          // ── Name ribbon (top-left) ─────────────────────────────────────
          Positioned(
            top: -13,
            left: 16,
            child: _buildNameRibbon(),
          ),
        ],
      ),
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────────────

  Widget _buildDots() {
    return Row(
      children: List.generate(widget.steps.length, (i) {
        final bool active = i == _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 5),
          width: active ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? _accent : _cardBorder,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildNextButton(bool isLastStep, dynamic l) {
    return InkWell(
      onTap: _nextStep,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _accent,
              _accent.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          isLastStep ? l.tutorialUnderstood : l.tutorialNext,
          style: GoogleFonts.outfit(
            color: AppColors.textOnPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    // ── Avatar The Creator menggunakan ThemeCard untuk efek sketsa ──
    return ThemeCard(
      isCircle: true,
      borderColor: _accent,
      borderWidth: 2,
      boxShadow: [
        BoxShadow(
          color: _accent.withValues(alpha: 0.4),
          blurRadius: 14,
          spreadRadius: 1,
        ),
      ],
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2D1A4D), Color(0xFF140D26)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text('🎭', style: TextStyle(fontSize: 32)),
          Positioned(
            top: 4,
            right: 4,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: _gold.withValues(alpha: 0.8),
              size: 9,
            ),
          ),
          Positioned(
            bottom: 5,
            left: 5,
            child: Icon(
              Icons.star_rounded,
              color: _accent.withValues(alpha: 0.6),
              size: 8,
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildNameRibbon() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accent,
            _accent.withValues(alpha: 0.7),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 120), // Batasi lebar maksimal
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👁️', style: TextStyle(fontSize: 10)),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                'xqvx The Creator',
                style: GoogleFonts.outfit(
                  color: AppColors.textOnPrimary,
                  fontSize: 9, // Diperkecil sedikit
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0, // Hilangkan spasi huruf agar lebih padat
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


