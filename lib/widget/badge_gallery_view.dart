import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_schema.dart';
import '../widget/badge_card.dart';
import '../theme/app_theme.dart';


// ── Tampilan Galeri Pencapaian (Badge Gallery View) ───────────────
// Menampilkan seluruh lencana (badges) yang ada di aplikasi beserta status (terbuka/terkunci).
// Mengecek apakah user memenuhi syarat untuk membuka badge tertentu.
class BadgeGalleryView extends StatelessWidget {
  final int level;
  final int totalTasksDone;
  final int coin;
  final int streak;
  final Map<String, int> categoryXp;
  final Color accentColor;

  const BadgeGalleryView({
    super.key,
    required this.level,
    required this.totalTasksDone,
    required this.coin,
    required this.streak,
    required this.categoryXp,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Galeri Pencapaian', style: GoogleFonts.nunito(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('${BadgeSystem.allBadges.where((b) => _isBadgeUnlocked(b)).length} / ${BadgeSystem.allBadges.length}', style: GoogleFonts.nunito(color: accentColor, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: BadgeSystem.allBadges.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.8),
          itemBuilder: (context, index) {
            final badge = BadgeSystem.allBadges[index];
            return BadgeCard(badge: badge, isUnlocked: _isBadgeUnlocked(badge), progress: _getBadgeProgress(badge));
          },
        ),
      ],
    );
  }

  bool _isBadgeUnlocked(AppBadge badge) {
    if (badge.category == 'level') {
      return level >= badge.threshold;
    }
    if (badge.category == 'totalTasksDone') {
      return totalTasksDone >= badge.threshold;
    }
    if (badge.category == 'gold') {
      return coin >= badge.threshold;
    }
    if (badge.category == 'streak') {
      return streak >= badge.threshold;
    }
    if (badge.category == 'all_100') {
      return categoryXp.values.every((xp) => xp >= 100);
    }
    return (categoryXp[badge.category] ?? 0) >= badge.threshold;
  }

  double _getBadgeProgress(AppBadge badge) {
    int current = 0;
    if (badge.category == 'level') {
      current = level;
    } else if (badge.category == 'totalTasksDone') {
      current = totalTasksDone;
    } else if (badge.category == 'gold') {
      current = coin;
    } else if (badge.category == 'streak') {
      current = streak;
    } else if (badge.category == 'all_100') {
      double totalProg = 0;
      for (var xp in categoryXp.values) {
        totalProg += (xp / badge.threshold).clamp(0.0, 1.0);
      }
      return totalProg / 5.0;
    } else {
      current = categoryXp[badge.category] ?? 0;
    }
    return (current / badge.threshold).clamp(0.0, 1.0);
  }
}
