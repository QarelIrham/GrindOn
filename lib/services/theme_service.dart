import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// Service for managing app theme
class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  
  AppThemeType _currentThemeType = AppThemeType.darkMode;
  
  ThemeService() {
    _loadTheme();
  }

  /// Get current theme type
  AppThemeType get currentThemeType => _currentThemeType;

  /// Get current ThemeData
  ThemeData get themeData => AppTheme.getThemeData(_currentThemeType);

  /// Load theme from SharedPreferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = prefs.getString(_themeKey);
      
      if (themeString != null) {
        _currentThemeType = AppTheme.fromString(themeString);
        AppColors.updateTheme(_currentThemeType); // Update colors!
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  /// Change theme
  Future<void> setTheme(AppThemeType themeType) async {
    try {
      _currentThemeType = themeType;
      AppColors.updateTheme(themeType); // Update colors!
      notifyListeners();

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _themeKey,
        AppTheme.themeToString(themeType),
      );
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  /// Toggle between dark and light mode (quick toggle)
  Future<void> toggleDarkLight() async {
    if (_currentThemeType == AppThemeType.darkMode) {
      await setTheme(AppThemeType.lightMode);
    } else {
      await setTheme(AppThemeType.darkMode);
    }
  }

  /// Check if current theme is dark
  bool get isDark => AppColors.isDark(_currentThemeType);

  /// Check if current theme is light
  bool get isLight => !isDark;
}
