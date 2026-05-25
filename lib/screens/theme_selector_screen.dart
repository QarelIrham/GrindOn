import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/audio_service.dart';

// ── Layar Pemilih Tema (Theme Selector Screen) ────────────────────
// Memungkinkan pengguna untuk mengganti tema keseluruhan aplikasi.
// Perubahan tema akan langsung diterapkan karena menggunakan Provider.
class ThemeSelectorScreen extends StatelessWidget {
  const ThemeSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Choose Theme',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AudioService.playClick();
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Text(
            '🎨 Customize Your Adventure',
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Choose a theme that matches your style',
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Theme Cards
          ...AppTheme.allThemes.map((themeType) {
            final isSelected = themeType == themeService.currentThemeType;
            return _ThemeCard(
              themeType: themeType,
              isSelected: isSelected,
              onTap: () async {
                AudioService.playClick();
                await themeService.setTheme(themeType);
              },
            );
          }),

          SizedBox(height: 24),

          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.cardBorder,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 32,
                ),
                SizedBox(height: 12),
                Text(
                  'Theme Tip',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your theme preference is saved automatically and will be applied across the entire app!',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final AppThemeType themeType;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.themeType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get theme preview colors
    final previewColors = _getPreviewColors(themeType);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 3 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Theme Preview
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: previewColors,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: themeType == AppThemeType.comicMonochrome
                      ? Border.all(color: AppColors.textPrimary, width: 3)
                      : null,
                ),
                child: Center(
                  child: Text(
                    AppTheme.getEmoji(themeType),
                    style: TextStyle(fontSize: 32),
                  ),
                ),
              ),
              SizedBox(width: 16),

              // Theme Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTheme.getName(themeType),
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      AppTheme.getDescription(themeType),
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Selected Indicator
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getPreviewColors(AppThemeType theme) {
    switch (theme) {
      case AppThemeType.darkMode:
        return [const Color(0xFF7C3AED), const Color(0xFFEC4899)];
      case AppThemeType.lightMode:
        return [const Color(0xFF7C3AED), const Color(0xFFEC4899)];
      case AppThemeType.anime:
        return [const Color(0xFFFFB3D9), const Color(0xFFB3E5FC)];
      case AppThemeType.comicMonochrome:
        return [AppColors.textPrimary, const Color(0xFF666666)];
    }
  }
}

