import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/locale_service.dart';

// ═══════════════════════════════════════════════════════════
//  THEME TYPE ENUM
// ═══════════════════════════════════════════════════════════

// Enum AppThemeType: Mendaftarkan 4 tipe tema yang tersedia di aplikasi ini.
enum AppThemeType {
  darkMode,
  lightMode,
  anime,
  comicMonochrome,
}

// ═══════════════════════════════════════════════════════════
//  APP COLORS (Dynamic - Changes with Theme)
// ═══════════════════════════════════════════════════════════

// Kelas AppColors: Pusat Komando Warna (State Global) untuk seluruh aplikasi.
// Layar lain HANYA BOLEH memanggil warna dari sini (misal: AppColors.primary),
// agar saat tema diganti, warnanya ikut berubah otomatis tanpa perlu tutup aplikasi.
class AppColors {
  // ─── Background Colors ───────────────────────────────────
  static AppThemeType currentTheme = AppThemeType.darkMode;

  static Color background = const Color(0xFF0F0F1E);
  static Color cardBackground = const Color(0xFF1A1A2E);
  static Color surface = const Color(0xFF1A1A2E);
  static Color cardBorder = const Color(0xFF2D2D44);
  static double borderWidth = 1.0;

  // ─── Primary Colors ──────────────────────────────────────
  static Color primary = const Color(0xFF7C3AED); // Purple
  static Color primaryLight = const Color(0xFFA78BFA);
  static Color primaryDark = const Color(0xFF5B21B6);
  static Color secondary = const Color(0xFFEC4899); // Pink
  static Color accent = const Color(0xFFD4AF37); // Gold

  // ─── Text Colors ─────────────────────────────────────────
  static Color textPrimary = Colors.white;
  static Color textOnPrimary = Colors.white;
  static Color textSecondary = Colors.white70;
  static Color textHint = Colors.white38;
  static Color textDisabled = Colors.white24;

  // ─── Status Colors ───────────────────────────────────────
  static Color success = const Color(0xFF10B981); // Green
  static Color error = const Color(0xFFEF4444); // Red
  static Color warning = const Color(0xFFF59E0B); // Orange
  static Color info = const Color(0xFF3B82F6); // Blue

  // ─── Category Colors (RPG Stats) ─────────────────────────
  static Color strength = const Color(0xFFEF4444); // Red
  static Color agility = const Color(0xFF10B981); // Green
  static Color intelligence = const Color(0xFF3B82F6); // Blue
  static Color defense = const Color(0xFFF59E0B); // Orange
  static Color vitality = const Color(0xFFEC4899); // Pink

  // ─── Special Colors ──────────────────────────────────────
  static Color gold = const Color(0xFFFFD700);
  static Color xp = const Color(0xFF8B5CF6);
  static Color hp = const Color(0xFFEF4444);
  static Color level = const Color(0xFFFFD700);

  // ─── Gradient Colors ─────────────────────────────────────
  static List<Color> primaryGradient = [
    const Color(0xFF7C3AED),
    const Color(0xFFEC4899),
  ];

  static List<Color> backgroundGradient = [
    const Color(0xFF4C1D95),
    const Color(0xFF2E1065),
    const Color(0xFF1E1B4B),
  ];

  // ═══════════════════════════════════════════════════════════
  //  UPDATE THEME
  // ═══════════════════════════════════════════════════════════

  // Fungsi untuk Memicu Perubahan Tema
  // Dipanggil saat user mengganti tema dari halaman Pengaturan (Settings)
  static void updateTheme(AppThemeType theme) {
    currentTheme = theme;
    switch (theme) {
      case AppThemeType.darkMode:
        _setDarkMode();
        break;
      case AppThemeType.lightMode:
        _setLightMode();
        break;
      case AppThemeType.anime:
        _setAnime();
        break;
      case AppThemeType.comicMonochrome:
        _setComicMonochrome();
        break;
    }
  }

  // ─── Dark Mode Theme ─────────────────────────────────────
  static void _setDarkMode() {
    background = const Color(0xFF0F0F1E);
    cardBackground = const Color(0xFF1A1A2E);
    surface = const Color(0xFF1A1A2E);
    cardBorder = const Color(0xFF2D2D44);
    borderWidth = 1.0;

    primary = const Color(0xFF7C3AED);
    primaryLight = const Color(0xFFA78BFA);
    primaryDark = const Color(0xFF5B21B6);
    secondary = const Color(0xFFEC4899);
    accent = const Color(0xFFD4AF37);

    textPrimary = Colors.white;
    textOnPrimary = Colors.white;
    textSecondary = Colors.white70;
    textHint = Colors.white38;
    textDisabled = Colors.white24;

    success = const Color(0xFF10B981);
    error = const Color(0xFFEF4444);
    warning = const Color(0xFFF59E0B);
    info = const Color(0xFF3B82F6);

    strength = const Color(0xFFEF4444);
    agility = const Color(0xFF10B981);
    intelligence = const Color(0xFF3B82F6);
    defense = const Color(0xFFF59E0B);
    vitality = const Color(0xFFEC4899);

    gold = const Color(0xFFFFD700);
    xp = const Color(0xFF8B5CF6);
    hp = const Color(0xFFEF4444);
    level = const Color(0xFFFFD700);

    primaryGradient = [
      const Color(0xFF7C3AED),
      const Color(0xFFEC4899),
    ];

    backgroundGradient = [
      const Color(0xFF4C1D95),
      const Color(0xFF2E1065),
      const Color(0xFF1E1B4B),
    ];
  }

  // ─── Light Mode Theme ────────────────────────────────────
  static void _setLightMode() {
    background = const Color(0xFFF8F9FA); // Sangat terang, kebalikan dark
    cardBackground = Colors.white;
    surface = Colors.white;
    cardBorder = const Color(0xFFE9ECEF);
    borderWidth = 1.0;

    primary = const Color(0xFF7C3AED);
    primaryLight = const Color(0xFFA78BFA);
    primaryDark = const Color(0xFF5B21B6);
    secondary = const Color(0xFFEC4899);
    accent = const Color(0xFFD4AF37);

    textPrimary = const Color(0xFF1A1A2E);
    textOnPrimary = Colors.white;
    textSecondary = const Color(0xFF4A4A4A);
    textHint = const Color(0xFF9CA3AF);
    textDisabled = const Color(0xFFD1D5DB);

    success = const Color(0xFF10B981);
    error = const Color(0xFFEF4444);
    warning = const Color(0xFFF59E0B);
    info = const Color(0xFF3B82F6);

    strength = const Color(0xFFEF4444);
    agility = const Color(0xFF10B981);
    intelligence = const Color(0xFF3B82F6);
    defense = const Color(0xFFF59E0B);
    vitality = const Color(0xFFEC4899);

    gold = const Color(0xFFFFD700);
    xp = const Color(0xFF8B5CF6);
    hp = const Color(0xFFEF4444);
    level = const Color(0xFFFFD700);

    primaryGradient = [
      const Color(0xFF7C3AED),
      const Color(0xFFEC4899),
    ];

    backgroundGradient = [
      const Color(0xFFF8F9FA),
      const Color(0xFFE9ECEF),
      const Color(0xFFDEE2E6),
    ];
  }

  // ─── Anime Theme ─────────────────────────────────────────
  static void _setAnime() {
    background = const Color(0xFFFFF0F5); // Lavender Blush pastel
    cardBackground = const Color(0xFFFFFAFA); // Snow white with pink tint
    surface = const Color(0xFFFFFAFA);
    cardBorder = const Color(0xFFFFB6C1); // Light Pink
    borderWidth = 2.0; // Slightly thicker for cartoon feel

    primary = const Color(0xFFFF69B4); // Hot Pink
    primaryLight = const Color(0xFFFFB6C1); // Light Pink
    primaryDark = const Color(0xFFC71585); // Medium Violet Red
    secondary = const Color(0xFF9370DB); // Medium Purple
    accent = const Color(0xFF00CED1); // Dark Turquoise

    textPrimary = const Color(0xFF4A148C); // Deep Purple text for contrast
    textOnPrimary = Colors.white; // Text on Hot Pink should be white
    textSecondary = const Color(0xFF7B1FA2);
    textHint = const Color(0xFFBA68C8);
    textDisabled = const Color(0xFFE1BEE7);

    success = const Color(0xFF69F0AE); // Pastel Green
    error = const Color(0xFFFF5252); // Pastel Red
    warning = const Color(0xFFFFD740); // Pastel Yellow
    info = const Color(0xFF40C4FF); // Pastel Blue

    strength = const Color(0xFFFF4081); // Pink
    agility = const Color(0xFF00E676); // Green
    intelligence = const Color(0xFF448AFF); // Blue
    defense = const Color(0xFFFF9100); // Orange
    vitality = const Color(0xFFE040FB); // Purple

    gold = const Color(0xFFFFD700);
    xp = const Color(0xFFFF4081);
    hp = const Color(0xFFFF1744);
    level = const Color(0xFFFF9100);

    primaryGradient = [
      const Color(0xFFFF69B4), // Hot Pink
      const Color(0xFFDA70D6), // Orchid
    ];

    backgroundGradient = [
      const Color(0xFFFFF0F5),
      const Color(0xFFFFE4E1),
      const Color(0xFFFFC0CB),
    ];
  }

  // ─── Comic Monochrome Theme ──────────────────────────────
  // --- TEMA COMIC MONOCHROME (Sangat Spesial) ---
  // Mengubah semua warna menjadi Hitam, Putih, dan Abu-abu.
  // Border ditebalkan, dan gradient warna dimatikan menjadi warna solid hitam/putih.
  static void _setComicMonochrome() {
    background = Colors.white;
    cardBackground = Colors.white; // Full white for comic cards
    surface = Colors.white;
    cardBorder = Colors.black; // Stark black borders
    borderWidth = 3.0; // Thick comic borders

    primary = Colors.black;
    primaryLight = const Color(0xFF555555);
    primaryDark = Colors.black;
    secondary = const Color(0xFF333333);
    accent = Colors.black;

    textPrimary = Colors.black;
    textOnPrimary = Colors.white;
    textSecondary = const Color(0xFF222222);
    textHint = const Color(0xFF555555);
    textDisabled = const Color(0xFF999999);

    success = Colors.black;
    error = Colors.black;
    warning = Colors.black;
    info = Colors.black;

    strength = Colors.black;
    agility = const Color(0xFF222222);
    intelligence = const Color(0xFF444444);
    defense = const Color(0xFF333333);
    vitality = const Color(0xFF111111);

    gold = Colors.black;
    xp = Colors.black;
    hp = Colors.black;
    level = Colors.black;

    primaryGradient = [
      Colors.black,
      const Color(0xFF333333),
    ];

    backgroundGradient = [
      Colors.white,
      Colors.white,
      Colors.white,
    ];
  }

  // ─── Helper: Check if Dark Theme ────────────────────────
  static bool isDark(AppThemeType theme) {
    return theme == AppThemeType.darkMode;
  }

  // ─── Helper: Check if Light Theme ───────────────────────
  static bool isLight(AppThemeType theme) {
    return theme == AppThemeType.lightMode ||
        theme == AppThemeType.anime ||
        theme == AppThemeType.comicMonochrome;
  }
}

// ═══════════════════════════════════════════════════════════
//  APP TEXT STYLES (Dynamic - Uses AppColors)
// ═══════════════════════════════════════════════════════════

class AppTextStyles {
  static bool get _isComic => AppColors.currentTheme == AppThemeType.comicMonochrome;

  static TextStyle _font({required double fontSize, required FontWeight fontWeight, required Color color, double? letterSpacing}) {
    if (_isComic) {
      if (fontSize >= 20 || fontWeight == FontWeight.w900) {
        return GoogleFonts.bangers(fontSize: fontSize + 2, fontWeight: FontWeight.normal, color: color, letterSpacing: letterSpacing ?? 1.5);
      }
      return GoogleFonts.comicNeue(fontSize: fontSize, fontWeight: fontWeight, color: color, letterSpacing: letterSpacing);
    }
    return GoogleFonts.nunito(fontSize: fontSize, fontWeight: fontWeight, color: color, letterSpacing: letterSpacing);
  }

  // ─── Headings ────────────────────────────────────────────
  static TextStyle get h1 => _font(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
        letterSpacing: 1,
      );

  static TextStyle get h2 => _font(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  static TextStyle get h3 => _font(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  static TextStyle get h4 => _font(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // ─── Body Text ───────────────────────────────────────────
  static TextStyle get body => _font(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyBold => _font(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => _font(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      );

  // ─── Special Text ────────────────────────────────────────
  static TextStyle get caption => _font(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textHint,
      );

  static TextStyle get button => _font(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 1,
      );

  static TextStyle get label => _font(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      );

  // ─── RPG Stats Text ──────────────────────────────────────
  static TextStyle get statValue => _font(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
      );

  static TextStyle get statLabel => _font(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 1,
      );

  // ─── Comic Style Text (for Comic Monochrome theme) ──────
  static TextStyle get comicTitle => GoogleFonts.bangers(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.black,
        letterSpacing: 2,
      );

  static TextStyle get comicBody => GoogleFonts.comicNeue(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: Colors.black,
      );
}

// ═══════════════════════════════════════════════════════════
//  APP THEME CONFIGURATIONS
// ═══════════════════════════════════════════════════════════

class AppTheme {
  // ─── Theme Metadata ──────────────────────────────────────
  static const Map<AppThemeType, Map<String, String>> themeInfo = {
    AppThemeType.darkMode: {
      'name': 'Dark',
      'emoji': '🌑',
      'desc_en': 'Elegant dark theme with purple accents',
      'desc_id': 'Tema gelap elegan dengan aksen ungu',
    },
    AppThemeType.lightMode: {
      'name': 'Light',
      'emoji': '🌤️',
      'desc_en': 'Clean and bright for daytime focus',
      'desc_id': 'Bersih dan cerah untuk fokus di siang hari',
    },
    AppThemeType.anime: {
      'name': 'Pinky',
      'emoji': '🌸',
      'desc_en': 'Soft pastel colors with kawaii aesthetics',
      'desc_id': 'Warna pastel lembut dengan estetika kawaii',
    },
    AppThemeType.comicMonochrome: {
      'name': 'Comic',
      'emoji': '📓',
      'desc_en': 'Bold black & white manga inspired',
      'desc_id': 'Gaya hitam & putih tebal ala manga',
    },
  };

  // ─── Get Theme Name ──────────────────────────────────────
  static String getName(AppThemeType theme) {
    return themeInfo[theme]?['name'] ?? 'Unknown';
  }

  // ─── Get Theme Emoji ─────────────────────────────────────
  static String getEmoji(AppThemeType theme) {
    return themeInfo[theme]?['emoji'] ?? '🎨';
  }

  // ─── Get Theme Description ───────────────────────────────
  static String getDescription(AppThemeType theme, BuildContext context) {
    final isEn = context.l.isEn;
    return themeInfo[theme]?[isEn ? 'desc_en' : 'desc_id'] ?? '';
  }

  // ─── Get All Themes ──────────────────────────────────────
  static List<AppThemeType> get allThemes => AppThemeType.values;

  // ─── Convert String to ThemeType ─────────────────────────
  static AppThemeType fromString(String value) {
    switch (value) {
      case 'darkMode':
        return AppThemeType.darkMode;
      case 'lightMode':
        return AppThemeType.lightMode;
      case 'anime':
        return AppThemeType.anime;
      case 'comicMonochrome':
        return AppThemeType.comicMonochrome;
      default:
        return AppThemeType.darkMode;
    }
  }

  // ─── Convert ThemeType to String ─────────────────────────
  static String themeToString(AppThemeType theme) {
    return theme.toString().split('.').last;
  }

  // ─── Get ThemeData for MaterialApp ───────────────────────
  static ThemeData getThemeData(AppThemeType theme) {
    // Update AppColors first
    AppColors.updateTheme(theme);

    // Special handling for Comic Monochrome
    if (theme == AppThemeType.comicMonochrome) {
      return _getComicMonochromeThemeData();
    }

    // Standard ThemeData for other themes
    return ThemeData(
      useMaterial3: true,
      brightness: AppColors.isDark(theme) ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme(
        brightness:
            AppColors.isDark(theme) ? Brightness.dark : Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      cardColor: AppColors.cardBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTextStyles.h3,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.button,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.cardBackground,
        contentTextStyle: AppTextStyles.bodyBold.copyWith(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
        ),
        elevation: 10,
        actionTextColor: AppColors.accent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      ),
    );
  }

  // ─── Comic Monochrome Special ThemeData ──────────────────
  static ThemeData _getComicMonochromeThemeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      primaryColor: Colors.black,
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: Color(0xFF666666),
        onSecondary: Colors.white,
        error: Colors.black,
        onError: Colors.white,
        surface: Color(0xFFF5F5F5),
        onSurface: Colors.black,
      ),
      cardColor: const Color(0xFFF5F5F5),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: AppTextStyles.comicTitle,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.button,
          side: const BorderSide(color: Colors.black, width: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        contentTextStyle: AppTextStyles.comicBody.copyWith(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0), // Sharp comic edges
          side: const BorderSide(color: Colors.black, width: 3),
        ),
        elevation: 0,
        actionTextColor: Colors.black,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      ),
    );
  }
}

