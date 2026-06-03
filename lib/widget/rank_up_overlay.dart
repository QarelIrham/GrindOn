import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_schema.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../services/locale_service.dart';

class RankUpOverlay extends StatefulWidget {
  final String newRank;
  final String title;

  const RankUpOverlay({
    super.key,
    required this.newRank,
    required this.title,
  });

  static void show(BuildContext context, {required String newRank, required String title}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => RankUpOverlay(newRank: newRank, title: title),
    );
  }

  @override
  State<RankUpOverlay> createState() => _RankUpOverlayState();
}

class _RankUpOverlayState extends State<RankUpOverlay> {
  @override
  void initState() {
    super.initState();
    AudioService.playSuccess();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = Color(RankSystem.rankColorHex(widget.newRank));

    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Background Card
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: rankColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: rankColor.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                Text(
                  context.l.notifRankUpTitle,
                  style: GoogleFonts.nunito(
                    color: AppColors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: rankColor,
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l.notifRankUpBody(widget.newRank),
                  style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.title,
                  style: GoogleFonts.nunito(
                    color: rankColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: rankColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    context.l.notifAwesome,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Floating Rank Icon
          Positioned(
            top: -40,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(color: rankColor, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: rankColor.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.military_tech,
                color: rankColor,
                size: 64,
              ),
            ),
          ),
          
        ],
      ),
    );
  }
}
