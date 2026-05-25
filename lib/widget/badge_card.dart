import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_schema.dart';
import '../theme/app_theme.dart';

// ── Kartu Lencana (Badge Card) ──────────────────────────────────
// Widget untuk menampilkan satu lencana (badge) di Galeri Pencapaian.
// Menampilkan ikon, nama lencana, dan progres bar (jika belum terbuka).
class BadgeCard extends StatelessWidget {
  final AppBadge badge;
  final bool isUnlocked;
  final double progress;

  const BadgeCard({
    super.key,
    required this.badge,
    required this.isUnlocked,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = Color(badge.colorHex);
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked ? badgeColor.withValues(alpha: 0.5) : AppColors.cardBorder,
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Badge Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? badgeColor.withValues(alpha: 0.1)
                  : AppColors.textPrimary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Text(
              badge.icon,
              style: TextStyle(
                fontSize: 32,
                color: isUnlocked ? null : Colors.grey.withValues(alpha: 0.5),
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: isUnlocked ? AppColors.textPrimary : AppColors.textPrimary.withValues(alpha: 0.38),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              isUnlocked ? 'Terbuka!' : badge.description,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.nunito(
                color: isUnlocked ? badgeColor : AppColors.textPrimary.withValues(alpha: 0.24),
                fontSize: 10,
              ),
            ),
          ),
          if (!isUnlocked) ...[
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.textPrimary.withValues(alpha: 0.10),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    badgeColor.withValues(alpha: 0.5),
                  ),
                  minHeight: 4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
