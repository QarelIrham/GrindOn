import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Widget header untuk setiap screen dengan title dan styling konsisten
class ScreenHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onBackPressed;

  const ScreenHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: SizedBox(
        height: 36, // Fixed height to prevent layout shifting between tabs
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (onBackPressed != null)
            IconButton(
              onPressed: onBackPressed,
              icon: Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
              ),
            ),
          Expanded(
            child: Row(
              children: [
                Image.asset(
                  'lib/assets/logo/Logo_GrindOn.png',
                  height: 24,
                  width: 24,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.shield, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: GoogleFonts.cinzel(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
      ),
    );
  }
}
