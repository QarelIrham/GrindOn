import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';


// ── Animasi Perayaan (Celebration Overlay) ────────────────────────
// Muncul ketika user berhasil menyelesaikan tugas penting atau naik level.
// Menampilkan animasi konfeti (menggunakan Lottie) dan ringkasan hadiah.
class CelebrationOverlay extends StatefulWidget {
  final String title;
  final int xp;
  final int coin;

  const CelebrationOverlay({
    super.key,
    required this.title,
    required this.xp,
    required this.coin,
  });

  static void show(BuildContext context, {required String title, required int xp, required int coin}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CelebrationOverlay(title: title, xp: xp, coin: coin),
    );
  }

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _controller.forward();
    
    // Timer dipercepat menjadi 2 detik
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (mounted) Navigator.of(context).pop();
      },
      child: Material(
        color: AppColors.textSecondary,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: const Icon(Icons.celebration, size: 100, color: Colors.amber),
                  );
                },
              ),
              const SizedBox(height: 20),
            Text(
              'QUEST COMPLETE!',
              style: GoogleFonts.nunito(
                color: Color(0xFFF59E0B),
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 8),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _rewardBadge(Icons.star_rounded, Colors.amber, '+${widget.xp} XP'),
                const SizedBox(width: 16),
                _rewardBadge(Icons.monetization_on_rounded, const Color(0xFFF59E0B), '+${widget.coin} GOLD'),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _rewardBadge(IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(text, style: GoogleFonts.nunito(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
