import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import '../theme/rpg_theme.dart';
import '../widget/avatar_preview.dart';
import '../services/audio_service.dart';
import '../services/locale_service.dart';

class CelebrationOverlay extends StatefulWidget {
  final String title;
  final String category;
  final int xp;
  final int coin;
  final String userName;
  final int level;
  final Map<String, String> equippedItems;

  const CelebrationOverlay({
    super.key,
    required this.title,
    required this.category,
    required this.xp,
    required this.coin,
    required this.userName,
    required this.level,
    required this.equippedItems,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String category,
    required int xp,
    required int coin,
    required String userName,
    required int level,
    required Map<String, String> equippedItems,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CelebrationOverlay(
        title: title,
        category: category,
        xp: xp,
        coin: coin,
        userName: userName,
        level: level,
        equippedItems: equippedItems,
      ),
    );
  }

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> {
  final ScreenshotController _screenshotCtrl = ScreenshotController();

  @override
  void initState() {
    super.initState();
    AudioService.playSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final baseColor = RPGColors.catColors[widget.category] ?? const Color(0xFF7C3AED);
    final catLabel = l.catName(widget.category);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Screenshot(
            controller: _screenshotCtrl,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withValues(alpha: 0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.cardBackground,
                    Color.lerp(AppColors.cardBackground, baseColor, 0.15)!,
                  ],
                ),
                border: Border.all(

                  color: baseColor.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  // Background Pattern / Watermark (Sleek curve or icon)
                  Positioned(
                    right: -40,
                    top: -40,
                    child: Icon(
                      Icons.star_rounded,
                      size: 200,
                      color: baseColor.withValues(alpha: 0.05),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: -20,
                    child: Icon(
                      RPGIcons.catIcons[widget.category] ?? Icons.fitness_center,
                      size: 150,
                      color: baseColor.withValues(alpha: 0.03),
                    ),
                  ),
                  
                  // Main Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header "QUEST COMPLETE"
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: baseColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: baseColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            l.proofQuestComplete.toUpperCase(),
                            style: GoogleFonts.outfit(
                              color: baseColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Glowing Icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: baseColor.withValues(alpha: 0.1),
                            boxShadow: [
                              BoxShadow(
                                color: baseColor.withValues(alpha: 0.4),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                            border: Border.all(color: baseColor.withValues(alpha: 0.5), width: 2),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.workspace_premium_rounded,
                              color: AppColors.textPrimary,
                              size: 44,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Title
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Category Label
                        Text(
                          catLabel.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: AppColors.textPrimary.withValues(alpha: 0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 36),
                        
                        // Stats Row (Strava-like big numbers)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem('XP GAINED', '+${widget.xp}', const Color(0xFFF59E0B)),
                            Container(width: 1, height: 40, color: AppColors.textPrimary.withValues(alpha: 0.1)),
                            _buildStatItem('GOLD', '+${widget.coin}', const Color(0xFFFFD700)),
                          ],
                        ),
                        const SizedBox(height: 36),
                        
                        // User Profile Footer
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: baseColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: baseColor.withValues(alpha: 0.3), width: 1.5),
                                ),
                                child: Center(
                                  child: AvatarPreview(equippedItems: widget.equippedItems, size: 44),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.userName.toUpperCase(),
                                    style: GoogleFonts.outfit(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: baseColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'LEVEL ${widget.level}',
                                      style: GoogleFonts.outfit(
                                        color: baseColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary.withValues(alpha: 0.10),
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    l.btnClose,
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final image = await _screenshotCtrl.capture();
                    if (image != null) {
                      final dir = await getTemporaryDirectory();
                      final file = await File('${dir.path}/grindon_achievement.png').create();
                      await file.writeAsBytes(image);
                      await Share.shareXFiles(
                        [XFile(file.path)],
                        text: '${l.proofShareText}${widget.title}${l.proofShareHashtags}',
                      );
                    }
                  },
                  icon: const Icon(Icons.share_rounded, size: 20),
                  label: Text(
                    'Bagikan',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: baseColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: baseColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
